# connection.ls -- communication with the server

require! settings
ui = require 'ui'
logs = require 'logging'
if module.hot
  module.hot.accept 'ui', ->
    ui := require 'ui'
  module.hot.accept 'logging', ->
    logs := require 'logging'

wsUrl = 'wss://chat.f-list.net:9799'

ws = null

pushMessage = (type, msg) ->
  msg = _.merge msg, { type: type, timestamp: new Date! }
  msgs = state.messages!
  msgs.push msg
  state.messages msgs

chat = state.chat

msgHandlers =
  ADL: (msg) ->
    # all global ops
    chat.ops msg.ops
  AOP: (msg) ->
    # gobal op has been added
    chat.ops _.union(chat.ops!, [msg.character])
  BRO: (msg) -> # TODO
  CDS: (msg) ->
    # channel description change
    if chat.channels[msg.channel]
      cinfo = chat.channels[msg.channel]
      cinfo.description msg.description
  CHA: (msg) ->
    # all channels
    chans = chat.allChannels!
    if not chans?
      chans := {}
    msg.channels.forEach (chan) ->
      chan.type = 'channel'
      chan.title = chan.name
      chans[chan.name] = chan
    chat.allChannels chans
  CIU: (msg) ->
    # invitation received
    pushMessage 'invite', msg
  CBU: (msg) ->
    # user banned from channel
    c = chat.channels[msg.channel]
    if c?
      c.users _.without(c.users, msg.character)
      logs.log 'channel', msg.channel, 'ban', msg
  CKU: (msg) ->
    # user kicked from channel
    c = chat.channels[msg.channel]
    if c?
      c.users _.without(c.users, msg.character)
      logs.log 'channel', msg.channel, 'kick', msg
  COA: (msg) ->
    # user promoted to chanop
    c = chat.channels[msg.channel]
    if c?
      c.ops _.union(c.ops!, [msg.character])
      logs.log 'channel', msg.channel, 'op-add', msg
  COL: (msg) ->
    # list of channel ops
    c = chat.channels[msg.channel]
    if c?
      maybeOwner = _.first msg.oplist
      if maybeOwner == '' then c.owner null else c.owner maybeOwner
      c.ops _.rest msg.oplist
  CON: (msg) ->
    # count connected users
    state.chat.usercount msg.count
  COR: (msg) ->
    # user removed from chanop
    c = chat.channels[msg.channel]
    if c?
      c.ops _.without(c.ops!, msg.character)
      logs.log 'channel', msg.channel, 'op-remove', msg
  CSO: (msg) ->
    # set channel owner
    c = chat.channels[msg.channel]
    if c?
      c.owner msg.character
      logs.log 'channel', msg.channel, 'owner-change', msg
  CTU: (msg) ->
    # user timed out from channel
    c = chat.channels[msg.channel]
    if c?
      c.users _.without(c.users, msg.character)
      logs.log 'channel', msg.channel, 'timeout', msg
  DOP: (msg) ->
    # gobal op has been removed
    chat.ops _.without(chat.ops!, msg.character)
  ERR: (msg) ->
    # an error happened
    pushMessage 'error', msg
  FKS: (msg) ->
    # kinks search results
    # TODO implement kinks search
  FLN: (msg) ->
    # character went offline
    chat.channels.forEach (chan) ->
      chan.users _.without(chan.users!, msg.character)
  HLO: (msg) ->
    # server welcome message
    # TODO display welcome message somewhere?
  ICH: (msg) ->
    # in channel (on channel join)
    c = chat.channels[msg.channel]
    c.users _.pluck msg.users, 'identity'
  IDN: (msg) ->
    # identification successful
    state.character msg.character
  JCH: (msg) ->
    # joined a channel
    c = chat.channels[msg.channel]
    if msg.character.identity == state.character!
      # we joined
      if not c?
        chat.channels[msg.channel] =
          description: m.prop ''
          name: msg.channel
          mode: m.prop msg.mode
          ops: m.prop []
          users: m.prop []
          owner: m.prop null
          logs: m.prop []
          links: m.prop []
          unread: m.prop 0
        c := chat.channels[msg.channel]
      ui.openTab do
        type: 'channel'
        title: msg.title
        name: msg.channel
        onclose: (t) -> ws-send 'LCH', channel: t.name
    # we joined OR someone else joined
    if c?
      c.users _.union(c.users!, [msg.character.identity])
  KID: (msg) ->
    # received kinks data
    # TODO process kinks data
  LCH: (msg) ->
    # left a channel (we or someone else)
    # NOTE tab should already have closed by this point
    # TODO clean up channel info too?
    c = chat.channels[msg.channel]
    if c?
      c.users _.without(c.users!, msg.character)
  LIS: (msg) ->
    # all online characters
    msg.characters.forEach (char) ->
      chat.characters[char[0]] =
        name: char[0]
        gender: char[1]
        status: char[2]
        message: char[3]
  NLN: (msg) ->
    # a character connected
    chat.characters[msg.identity] =
      name: msg.identity
      gender: msg.gender
      status: msg.status
      message: null
    if msg.identity == state.character!
      chat.status 'connected'
      m.redraw!
  IGN: (msg) ->
    # ignore list handling
    # TODO handle ignore list
  FRL: (msg) ->
    # friends list
    chat.friends msg.characters
  ORS: (msg) ->
    # open rooms list
    chans = chat.allChannels!
    if not chans?
      chans := {}
    msg.channels.forEach (chan) ->
      chan.type = 'room'
      chans[chan.name] = chan
    chat.allChannels chans
  PRD: (msg) ->
    # short profile data
    # TODO handle profile data
  PRI: (msg) ->
    # received private message
    # TODO handle ignore here
    if not chat.ims[msg.character]?
      chat.ims[msg.character] =
        logs: m.prop []
        links: m.prop []
        unread: m.prop 0
    ui.openTab type: 'im', name: msg.character, true
    logs.log 'im', msg.character, 'm', msg
  MSG: (msg) ->
    # received channel message
    logs.log 'channel', msg.channel, 'm', msg
  LRP: (msg) ->
    # received roleplaying ad
    # TODO handle ads
  RLL: (msg) ->
    # dice roll / bottle spin
    # TODO handle dice rolls
  RMO: (msg) ->
    # change room/channel mode
    c = chat.channels[msg.channel]
    if c?
      c.mode msg.mode
  RTB: (msg) ->
    # realtime bridge, i.e. something happened on f-list that
    # gets passed on into the chat (note, friend request etc)
    # TODO handle realtime bridge events
    console.log 'RTB', msg
  SFC: (msg) ->
    # admin reports and actions
    # TODO handle admin actions
  STA: (msg) ->
    # user status change
    chat.characters[msg.character] = _.merge chat.characters[msg.character],
      status: msg.status
      message: msg.statusmsg
  SYS: (msg) ->
    # generic system message
    # TODO handle SYS messages
    console.log 'SYS', msg
  TPN: (msg) ->
    # typing notification
    tp = chat.typing[msg.character]
    if not tp?
      tp = m.prop null
      chat.typing[msg.character] = tp
    tp msg.status
  UPT: (msg) ->
    # server uptime and other information
    # TODO handle server uptime info
  VAR: (msg) ->
    # server variables
    # TODO handle server variables

handleMessage = (srvmsg) ->
  srvmsg = srvmsg.data
  code = srvmsg.substr(0, 3)
  if code == 'PIN'
    ws.send 'PIN'
    return
  payload = srvmsg.substr(4)
  try
    payload := JSON.parse(payload)
    if msgHandlers[code]?
      msgHandlers[code] payload
      # don't redraw on online/offline -- happens too often
      # TODO: occasionally redraw (timeout) to visually acknowledge NLN/LIS maybe.
      if code != 'LIS' and code != 'NLN' and code != 'FLN'
        m.redraw!
    else
      # TODO report unknown code
  catch
    # TODO report error

ws-send = (code, payload) ->
  if ws? and ws.readyState == 1
    if payload?
      ws.send(code + ' ' + JSON.stringify(payload))
    else
      ws.send(code)

window.send = ws-send

window.disconnect = ->
  ws.close!
  ws := null

module.exports =
  send: ws-send

  connect: (aname, cname) ->
    if ws? then return
    ws := new WebSocket wsUrl
    ws.onmessage = handleMessage
    ws.onclose = -> state.chat.status null
    ws.onopen = ->
      ws-send 'IDN',
        method: 'ticket'
        account: aname
        ticket: state.ticket!.ticket
        character: cname
        cname: 'Turbo'
        cversion: 'dev'

  disconnect: ->
    if not ws? then return
    ws.close!
    ws := null

