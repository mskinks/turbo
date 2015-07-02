# actionpad.ls -- Turbo's action pad and quick actions.

require! state
require! fuzzy
conn = require 'connection'
app = require 'app'
settings = require 'settings'

ui = require 'ui'
if module.hot
  module.hot.accept 'ui', ->
    ui := require 'ui'

as =
  input: m.prop ''
  oldinput: m.prop ''
  dynamicActionCache: m.prop []
  selected: m.prop 0
  mode: m.prop 'start'
  primary: m.prop null
  actionCache: m.prop null
  secondary: m.prop null

availableActions = ->
  actions = (if preActions[as.mode!]? then preActions[as.mode!] else [])
  if dynamicActions[as.mode!]
    # cache dynamic actions, except if the input changes.
    if as.input! != as.oldinput!
      as.dynamicActionCache dynamicActions[as.mode!]!
      as.oldinput as.input!
    actions := actions.concat as.dynamicActionCache!
  if postActions[as.mode!]?
    actions := actions.concat postActions[as.mode!]
  if as.selected! >= actions.length then as.selected actions.length - 1
  fs = as.input!.toLowerCase!
  _.filter actions, (a) -> a.name.toLowerCase!.indexOf(fs) > -1

invoke = (mode, primary, secondary) ->
  if not mode?
    mode := 'start'
  as.input ''
  as.oldinput null
  as.selected 0
  as.mode mode
  as.primary primary
  as.secondary secondary
  as.actionCache null
  if state.actionpad! == false
    state.actionpad true
    m.redraw!

preActions =
  character:
    * name: 'F-List Profile'
      explain: 'View profile for this character.'
      action: ->
        window.open 'https://www.f-list.net/c/' + as.primary!
        return true
    * name: 'Open PM'
      explain: 'Send Private Message.'
      action: ->
        if not state.chat.ims[as.primary!]?
          state.chat.ims[as.primary!] =
            logs: m.prop []
            links: m.prop []
            unread: m.prop 0
        ui.openTab type: 'im', name: as.primary!, true
        return true
    * name: 'Ignore'
      explain: 'Ignore this character.'
      action: ->

  channel: [{
    name: 'Channel Actions'
    explain: 'Logging, auto-joining, and so on.'
    action: ->
      invoke 'channelactions', as.primary!
      return false
  }]

postActions =
  start:
    * name: 'Join Channel'
      explain: 'Join a channel.'
      action: ->
        invoke 'channels'
        return false
    * name: 'Find Character'
      explain: 'Search online characters.'
      action: ->
        invoke 'characters'
        return false
    * name: 'Close This Tab'
      explain: 'Close the current tab.'
      action: ->
        ui.closeTab ui.currentFocus!
        return true
    * name: 'Turbo Settings'
      explain: 'Open the settings tab.'
      action: ->
        ui.openTab do
          type: 'settings'
          name: 'Settings'
        return true

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
      name: if tab.type == 'channel' then tab.title else tab.name
      type: 'Chat Tab'
      explain: 'Switch to this tab.'
      action: -> state.currentTab tab
    .value!

  channels: ->
    chans = if as.input!.length < 3
      [{ name: '', explain: 'Type at least three letters to start searching.' }]
    else
      _(state.chat.allChannels!)
      .values!
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
    if not state.chat.loadedChannels!
      conn.send 'CHA'
      conn.send 'ORS'
      # TODO message about loading channel data
    return chans

  characters: ->
    chars = if as.input!.length < 3
      [{ name: '', explain: 'Type at least three letters to start searching.' }]
    else
      fs = as.input!.toLowerCase!
      _(Object.keys(state.chat.characters))
      .filter (c) -> c.toLowerCase!.indexOf(fs) > -1
      .map (c) ->
        name: c
        type: 'Character'
        explain: 'Character Actions'
        action: ->
          invoke 'character', c
          return false
      .value!

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

  channelactions: ->
    ac = state.chat.allChannels![as.primary!]
    autojoin = null
    if _.findIndex(settings.get('autojoin')[state.character!], (c) -> c.name == ac.name) == -1
      autojoin =
        name: 'Add to Autojoin'
        explain: 'Automatically join this channel on login.'
        action: ->
          settings.addAutojoin state.character!, ac
          return true
    else
      autojoin =
        name: 'Remove from Autojoin'
        explain: 'Don\'t auto-join this channel on login.'
        action: ->
          settings.removeAutojoin state.character!, ac
          return true
    return [autojoin]

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
    onmousemove: -> as.selected idx
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
  characters: -> m 'h4', 'Find Character'
  character: -> m 'h4', as.primary!
  channelactions: -> m 'h4', 'Actions for ' + state.chat.allChannels![as.primary!].title

controlKeys = (ev) ->
  code = ev.keyCode
  fix = false
  if code == 13
    # enter
    action = availableActions![as.selected!]
    uninvoke = action.action!
    ev.target.value = ''
    if uninvoke then dismiss!
    return false
  else
    if code == 38
      # up
      as.selected as.selected! - 1
      fix = true
    else if code == 40
      # down
      as.selected as.selected! + 1
      fix = true
    else if code == 33
      # pgup
      as.selected as.selected! - 6
      fix = true
    else if code == 34
      # pgdn
      as.selected as.selected! + 6
      fix = true
    if fix
      if as.selected! < 0
        as.selected availableActions!.length - 1
      if as.selected! >= availableActions!.length
        as.selected 0
      return false

positioningClass = ->
  if state.popout!? and state.focus! == 'popout'
    return 'righty'
  else if state.popout!?
    return 'lefty'
  else
    return ''

dismiss = ->
  state.actionpad false
  m.redraw true
  ui.focusTextInput!

module.exports =
  invoke: invoke

  dismiss: dismiss

  view: (c) -> m 'div#ap-container', [
    m 'div#ap-overlay',
      onclick: -> dismiss!
    m 'div#actionpad',
      class: positioningClass!
    , [
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
  ]
