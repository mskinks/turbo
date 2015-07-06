# channel.ls -- reusable component for a chat channel.

bbcode = require 'bbcode'
r = require 'renderables'
logging = require 'logging'
settings = require 'settings'

if module.hot
  module.hot.accept 'renderables', ->
    r := require 'renderables'
    m.redraw!
  module.hot.accept 'bbcode', ->
    bbcode := require 'bbcode'
    m.redraw!
  module.hot.accept 'logging', ->
    logging := require 'logging'
  module.hot.accept 'settings', ->
    settings := require 'settings'

scrollChat = (el, init, ctx) ->
  if el.scrollTop == 0
    el.scrollTop = el.scrollHeight
    return
  div = el.firstChild
  last = div.lastChild
  if last?
    if div.scrollHeight - (el.scrollTop + el.offsetHeight) - div.lastChild.offsetHeight < 10
      el.scrollTop = el.scrollHeight
      return

# a thing that manages the rendering, displaying of chatlines, text area etc
# for a channel.
Channel = (name) ->
  title = state.chat.allChannels![name].title
  chan = state.chat.channels[name]
  logs = chan.logs
  users = ->
    _(chan.users!)
    .sortBy (u) -> u.toLowerCase!
    .value!.map (name) ->
      state.chat.characters[name] or { name: name }
  typed = m.prop ''

  return do
    view: (c) ->
      rm = (msg) -> r.message settings.get('timeFormat'), msg
      m 'div.channel.max', [
        m 'div.channel-main', [
          m 'div.channel-top.scroll', m 'div', [
            m 'h4', title
            m 'p', m.trust bbcode chan.description!
          ]
          m 'div.channel-chat.scroll',
            config: scrollChat
          , m 'div',
            logs!.map rm
          m 'div.channel-bottom', [
            m 'textarea.form-control.chat-input',
              value: typed!
              onkeydown: (ev) ->
                if ev.keyCode == 13 and typed!.length > 0
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
    view: (c) ->
      rm = (msg) -> r.message settings.get('timeFormat'), msg
      m 'div.channel.max', [
        m 'div.channel-main', [
          m 'div.channel-top', [
            m 'h4', user.name
          ]
          m 'div.channel-chat.scroll',
            config: scrollChat
          , m 'div',
            logs!.map rm
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
