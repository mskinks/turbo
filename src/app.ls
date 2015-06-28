# app.ls -- main chat app

require! channelsearch
channel = require 'channel'

if module.hot
  module.hot.accept 'channel', ->
    channel := require 'channel'
    # update all running channel renderers to new code
    _.values(state.chat.channels).forEach (c) ->
      if c.renderer?
        r = new channel.Channel c.name
        c.renderer = r
    m.redraw!

closeTab = (tab) ->
  if state.currentTab! == tab
    state.currentTab null
  state.tabs _.without(state.tabs!, tab)

tabList = ->
  m 'ul', state.tabs!.map (tab) ->
    m 'li.tab',
      class: if state.currentTab! == tab then 'current ' + tab.type else tab.type
      onclick: ->
        state.currentTab tab
        m.redraw!
    , [
      m 'div.pull-right', [
        m 'a',
          onclick: -> closeTab tab
        , 'x'
      ]
      m 'h5', tab.name
    ]

renderTab = (tab) ->
  if not tab?
    return m '.greeting', "Welcome to F-Chat."
  if tab.type == 'channels'
    return channelsearch.view!
  if tab.type == 'channel'
    c = state.chat.channels[tab.name].renderer
    if not c?
      c := new channel.Channel tab.name
      state.chat.channels[tab.name].renderer = c
    return c.view!
  if tab.type == 'im'
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
      m 'div.main-pane.flex', renderTab state.currentTab!
    ]

