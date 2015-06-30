# channel.ls -- reusable component for a chat channel.

require! state
require! moment

bbcode = require 'bbcode'
conn = require 'connection'
r = require 'renderables'
logging = require 'logging'

if module.hot
  module.hot.accept 'renderables', ->
    r := require 'renderables'
    m.redraw!
  module.hot.accept 'bbcode', ->
    bbcode := require 'bbcode'
    m.redraw!
  module.hot.accept 'logging', ->
    logging := require 'logging'

renderMessage = (msg) ->
  user = state.chat.characters[msg.character] or { name: name }
  if msg.type == 'm'
    return m 'div.message',
      key: msg.character + '-' + msg.timestamp.getTime!
    , [
      m 'span.timestamp', '[' + moment(msg.timestamp).format('HH:mm') + ']'
      r.user user
      m 'span.message', m.trust bbcode msg.message
    ]

scrollChat = (el, init, ctx) ->
  if el.scrollTop == 0
    el.scrollTop = el.scrollHeight
    return
  div = el.firstChild
  last = div.lastChild
  if last?
    if div.scrollHeight - (el.scrollTop + el.offsetHeight) - div.lastChild.offsetHeight < 10
      last.scrollIntoView false
      return

# a thing that manages the rendering, displaying of chatlines, text area etc
# for a channel.
Channel = (name) ->
  chan = state.chat.channels[name]
  logs = chan.logs
  users = ->
    chan.users!.map (name) ->
      state.chat.characters[name] or { name: name }
  typed = m.prop ''

  return do
    view: (c) -> m 'div.channel.max', [
      m 'div.channel-main', [
        m 'div.channel-top.scroll', m 'div', [
          m 'p', m.trust bbcode chan.description!
        ]
        m 'div.channel-chat.scroll',
          config: scrollChat
        , m 'div',
          logs!.map renderMessage
        m 'div.channel-bottom', [
          m 'textarea.form-control.chat-input',
            value: typed!
            onkeydown: (ev) ->
              if ev.keyCode == 13
                msg =
                  character: state.character!
                  channel: name
                  message: typed!
                conn.send 'MSG', msg
                logging.log 'channel', name, 'm', msg
                typed ''
            onkeyup: (ev) ->
              if ev.keyCode != 13
                typed ev.target.value
              else
                ev.target.value = ''
        ]
      ]
      m 'div.channel-users.scroll', m 'div.user-list', users!.map r.user
    ]

# TODO see if we can merge or inherit channel and IM renderers

# a thing that manages a user IM.
IM = (name) ->
  user = state.chat.characters[name]
  im = state.chat.ims[name]
  logs = im.logs
  typed = m.prop ''

  return do
    view: (c) -> m 'div.channel.max', [
      m 'div.channel-main', [
        m 'div.channel-top', [
          m 'h4', user.name
        ]
        m 'div.channel-chat.scroll',
          config: scrollChat
        , m 'div',
          logs!.map renderMessage
        m 'div.channel-bottom', [
          m 'textarea.form-control',
            onkeydown: (ev) ->
              if ev.keyCode == 13 and typed!.length > 0
                msg =
                  character: state.character!
                  recipient: name
                  message: typed!
                conn.send 'PRI', msg
                logging.log 'im', name, 'm', msg
                typed ''
            onkeyup: (ev) ->
              if ev.keyCode != 13
                typed ev.target.value
              else
                ev.target.value = ''
        ]
      ]
    ]

module.exports =
  Channel: Channel
  IM: IM
