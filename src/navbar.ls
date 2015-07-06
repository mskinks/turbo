# navbar.ls -- navbar at the top of the chat

require! ui

all-channels = ->
  # open channel tab and refresh channels
  ui.openTab do
      type: 'channels'
      name: 'All Channels'
  # request refreshes
  if not state.chat.loadedChannels!
    conn.send 'CHA'
    conn.send 'ORS'

when-connected = [
  m 'li', m 'a',
    onclick: all-channels
  , 'Channels'
  m 'li', m 'a',
    onclick: ->
      ui.openTab do
        type: 'kinksearch'
        name: 'Kink Search'
  , 'Kink Search'
  m 'li', m 'a',
    onclick: ->
      ui.openTab do
        type: 'ads'
        name: 'Ads'
  , 'Ads'
]

always = [
  m 'li', m 'a',
    onclick: ->
      ui.openTab do
        type: 'logs'
        name: 'Logs'
  , 'Logs'
  m 'li', m 'a',
    onclick: ->
      ui.openTab do
        type: 'settings'
        name: 'Settings'
  , 'Settings'
]

module.exports =
  view: (c) ->
    m 'nav.navbar.navbar-default', [
      m '.navbar-header', [
        m 'a.navbar-brand',
          href: '#'
        , "Turbo"
      ]
      m 'ul.nav.navbar-nav', [
        if state.chat.status! == 'connected' then always.concat when-connected else always
      ]
    ]

