# actionpad.ls -- Turbo's action pad and quick actions.

require! state
require! fuzzy
conn = require 'connection'
app = require 'app'

as =
  input: m.prop ''
  selected: m.prop 0
  mode: m.prop 'start'
  primary: m.prop null
  actionCache: m.prop null
  secondary: m.prop null

availableActions = ->
  actions = (if dynamicActions[as.mode!] then dynamicActions[as.mode!]! else [])
  if actionsFor[as.mode!]?
    actions := actions.concat actionsFor[as.mode!]
  if as.selected! >= actions.length then as.selected actions.length - 1
  fuzzy.filter as.input!, actions,
    pre: '<u>'
    post: '</u>'
    extract: (a) -> a.name
  .map (r) ->
    o = r.original
    o.name = r.string
    return o

invoke = (mode, primary, secondary) ->
  if not mode?
    mode := 'start'
  as.input ''
  as.selected 0
  as.mode mode
  as.primary primary
  as.secondary secondary
  as.actionCache null
  if state.actionpad! == false
    state.actionpad true
    m.redraw!

actionsFor =
  start:
    * name: 'Join Channel'
      explain: 'Join a channel.'
      action: ->
        invoke 'channels'
        return false
    * name: 'Find Character'
      explain: 'Pop up character menu.'
      action: ->
    * name: 'Close This Tab'
      explain: 'Close the current tab.'
      action: ->

  channels: [{
    name: 'Refresh Channels'
    explain: 'Refresh channel list from server.',
    action: ->
      state.chat.allChannels null
      conn.send 'CHA'
      conn.send 'ORS'
  }]

dynamicActions =
  start: ->
    _(state.tabs!)
    .filter (tab) -> tab != state.currentTab!
    .map (tab) ->
      name: tab.name
      type: 'Chat Tab'
      explain: 'Switch to this tab.'
      action: -> state.currentTab tab
    .value!

  channels: ->
    chans = if as.input!.length < 3
      [{ name: '', explain: 'Type at least three letters to start searching.' }]
    else
      _(state.chat.allChannels!)
      .filter (c) -> c.title.toLowerCase!.indexOf(as.input!.toLowerCase!) > -1
      .sortByOrder 'characters', false
      .map (c) ->
        name: c.title
        type: (if c.type == 'channel' then 'Channel' else 'Room') + ', ' + c.characters + ' users'
        explain: 'Join ' + c.title
        action: ->
          conn.send 'JCH', channel: c.name
          return true
      .value!
    if not state.chat.allChannels!?
      conn.send 'CHA'
      conn.send 'ORS'
      chans.push do
        name: ''
        explain: 'Turbo is loading channel data...'
        action: ->
    return chans

  channel: ->
    if as.actionCache! then return as.actionCache!
    ctitle = state.chat.allChannels![as.primary!].title
    actions = _(as.secondary!.users!)
    .filter (c) -> c?
    .map (c) ->
      return do
        name: c
        type: 'Character in ' + ctitle
        explain: 'Character Actions'
        action: ->
          invoke 'character', c
          return false
    .value!
    as.actionCache actions
    return actions

  openlink: ->
    as.secondary!.links!.map (l) ->
      return do
        name: l.link
        type: 'Linked by ' + l.from
        action: ->
          window.open l.link
          return true

renderAction = (action, idx) ->
  m '.action',
    class: if idx == as.selected! then 'selected' else ''
    onclick: action.action
  , [
    if action.explain?
      m '.explain', action.explain
    m '.left', [
      m '.name', m.trust action.name
      if action.type? then m '.type', action.type
    ]
  ]

renderTarget =
  start: -> m 'h4', '>> Turbo'
  channels: -> m 'h4', 'Join Channel'
  channel: -> m 'h4', state.chat.allChannels![as.primary!].title
  openlink: -> m 'h4', 'Recent links in ' + state.chat.allChannels![as.primary!].title

controlKeys = (ev) ->
  code = ev.keyCode
  if code == 38
    # up
    if as.selected! > 0
      as.selected as.selected! - 1
    return false
  else if code == 40
    # down
    if as.selected! < availableActions!.length - 1
      as.selected as.selected! + 1
    return false
  else if code == 13
    # enter
    action = availableActions![as.selected!]
    uninvoke = action.action!
    ev.target.value = ''
    if uninvoke then state.actionpad false
    return false

module.exports =
  invoke: invoke

  view: (c) -> m 'div#actionpad', [
    m 'div.target', renderTarget[as.mode!]!
    m 'div.input', [
      m 'input[type=text]',
        config: (el, init, ctx) ->
          if !init
            el.focus!
        onkeyup: m.withAttr 'value', as.input
        onkeydown: controlKeys
    ]
    m 'div.actions-container',
      config: (el, init, ctx) ->
        s = el.querySelector 'div.action.selected'
        if s?
          s.scrollIntoView false
    , m 'div.actions', availableActions!.map renderAction
  ]
