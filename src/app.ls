# app.ls -- main chat app

require! channelsearch
ui = require 'ui'
channel = require 'channel'

if module.hot
  module.hot.accept 'ui', ->
    ui := require 'ui'
  module.hot.accept 'channel', ->
    channel := require 'channel'
    # update all running channel renderers to new code
    _.values(state.chat.channels).forEach (c) ->
      if c.renderer?
        r = new channel.Channel c.name
        c.renderer = r
    m.redraw!

unreadTab = (tab, target) ->
  m 'li.tab',
    key: tab.type + '-' + tab.name
    class: if state.currentTab! == tab then 'current ' + tab.type else tab.type
    onclick: ->
      state.currentTab tab
      m.redraw!
  , [
    m 'div.pull-right', [
      if target.unread! > 0 then m 'span.badge.unread', target.unread!
      m 'a',
        onclick: ->
          ui.closeTab tab
          return false
      , 'X'
    ]
    m 'h5', tab.title
  ]

defaultTab = (tab) ->
  m 'li.tab',
    key: tab.type + '-' + tab.name
    class: if state.currentTab! == tab then 'current ' + tab.type else tab.type
    onclick: ->
      state.currentTab tab
      m.redraw!
  , [
    m 'div.pull-right', [
      m 'a',
        onclick: ->
          ui.closeTab tab
          return false
      , 'X'
    ]
    m 'h5', tab.name
  ]

tabList = ->
  m 'ul', state.tabs!.map (tab) ->
    if tab.type == 'channel'
      unreadTab tab, state.chat.channels[tab.name]
    else if tab.type == 'im'
      unreadTab tab, state.chat.ims[tab.name]
    else
      defaultTab tab

renderTab = (tab) ->
  if not tab? or tab == null
    return m '.greeting', "Welcome to F-Chat."
  if tab.type == 'channels'
    return channelsearch.view!
  if tab.type == 'channel'
    state.chat.channels[tab.name].unread 0
    c = state.chat.channels[tab.name].renderer
    if not c?
      c := new channel.Channel tab.name
      state.chat.channels[tab.name].renderer = c
    return c.view!
  if tab.type == 'im'
    state.chat.ims[tab.name].unread 0
    c = state.chat.ims[tab.name].renderer
    if not c?
      c := new channel.IM tab.name
      state.chat.ims[tab.name].renderer = c
    return c.view!
  return m 'p', "That's strange. This tab has an unknown type, and cannot be displayed."

module.exports =
  view: (c) ->
    m '.flex.max.row', [
      m 'div.app-tabs', tabList!
      m 'div.chat-pane.main-pane.flex',
        class: if state.focus! == 'tabs' then 'active' else ''
      , renderTab state.currentTab!
      if state.popout!?
        m 'div.chat-pane.popout-pane.flex',
          class: if state.focus! == 'popout' then 'active' else ''
        , renderTab state.popout!
    ]

