# state.ls -- contains global application state

module.exports =
  ticket: m.prop null
  character: m.prop null
  messages: m.prop []
  tabs: m.prop []
  currentTab: m.prop null
  popout: m.prop null
  focus: m.prop 'tabs'
  actionpad: m.prop false
  vars: m.prop do
    chat_max: 4096
    priv_max: 50000
    lfrp_max: 50000
    lfrp_flood: 600
    msg_flood: 0.5
    permissions: 0
  chat:
    logging: m.prop []
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

