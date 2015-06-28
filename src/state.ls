# state.ls -- contains global application state

module.exports =
  ticket: m.prop null
  character: m.prop null
  messages: m.prop []
  tabs: m.prop []
  currentTab: m.prop null
  chat:
    usercount: m.prop 0
    status: m.prop null
    ops: m.prop null
    friends: m.prop []
    channels: {}
    ims: {}
    typing: {}
    allChannels: m.prop null
    characters: {}

