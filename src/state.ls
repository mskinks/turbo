# state.ls -- contains global application state

settings = require 'settings'

if module.hot
  module.hot.accept 'settings', ->
    settings := require 'settings'

module.exports =
  ticket: m.prop null
  character: m.prop null
  messages: m.prop []
  tabs: m.prop []
  currentTab: m.prop null
  popout: m.prop null
  focus: m.prop 'tabs'
  actionpad: m.prop false
  chat:
    logging: m.prop settings.get 'alwaysLog'
    usercount: m.prop 0
    status: m.prop null
    ops: m.prop null
    friends: m.prop []
    channels: {}
    ims: {}
    typing: {}
    allChannels: m.prop {}
    loadedChannels: m.prop false
    characters: {}

