# navbar.ls -- navbar at the top of the chat

require! state
conn = require 'connection'

all-channels = ->
  # open channel tab and refresh channels
  t = _.find state.tabs!, (tab) -> tab.type == 'channels'
  if not t?
    t :=
      type: 'channels'
      name: 'All Rooms'
    tabs = state.tabs!
    tabs.unshift t
    state.tabs tabs
    m.redraw!
  state.currentTab t
  # request refreshes
  if not state.chat.allChannels!?
    conn.send 'CHA'
    conn.send 'ORS'

module.exports =
  view: (c) ->
    m 'nav.navbar.navbar-default', [
      m '.navbar-header', [
        m 'a.navbar-brand',
          href: '#'
        , "Turbo"
      ]
      if state.chat.status! == 'connected'
        m 'ul.nav.navbar-nav', [
          m 'li', m 'a',
            onclick: all-channels
          , 'Rooms'
          m 'li', m 'a',
            onclick: ->
          , 'Kink Search'
          m 'li', m 'a',
            onclick: ->
          , 'Settings'
        ]
    ]

