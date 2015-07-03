# settings.ls -- Turbo settings that can be saved to local application
# storage.

template = ->
  return do
    showUsers: true
    autojoin: {}
    scrollback: 100
    recentLinks: 6
    recentAds: 50
    timeFormat: 'HH:mm'
    logging: 'ims'
    alwaysLog: []
    alwaysLogNames: []
    adMode: 'tab'
    adblockChannels: []
    adblockCharacters: []
    adblockGenders: []

settings = m.prop template!

# try loading settings on load
loaded = window.localStorage.getItem 'turbo-settings'
if loaded?
  loaded = JSON.parse loaded
  settings _.merge settings!, loaded

save = ->
  s = settings!
  s.saved = true
  window.localStorage.setItem 'turbo-settings', JSON.stringify(s)
  settings s

get = (key) -> settings![key]

set = (key, value) ->
  s = settings!
  s[key] = value
  if key == 'alwaysLog'
    # we save the names again separately, for faster access by the logging module.
    s.alwaysLogNames = _.pluck value, 'name'
  s.saved = false
  settings s

addAutojoin = (char, channel) ->
  aj = get 'autojoin'
  if not aj[char]?
    aj[char] = []
  aj[char].push do
    name: channel.name
    title: channel.title
  set 'autojoin', aj
  save!

removeAutojoin = (char, channel) ->
  aj = get 'autojoin'
  if not aj[char]?
    return
  aj[char] = _.reject(aj[char], (c) -> c.name == channel.name)
  if aj[char].length == 0
    set 'autojoin', _.omit aj, char
  else
    set 'autojoin', aj
  save!

addAdblock = (what) ->
  if what.title
    # it's a channel
    cs = get 'adblockChannels'
    cs.push what
    set 'adblockChannels', cs
  else
    cs = get 'adblockCharacters'
    cs.push what
    set 'adblockCharacters', cs

removeAdblock = (what) ->
  if what.title
    # it's a channel
    cs = get 'adblockChannels'
    cs = _.reject cs, (c) -> c.name == what.name
    set 'adblockChannels', cs
  else
    cs = get 'adblockCharacters'
    cs = _.without cs, what
    set 'adblockCharacters', cs

input = (key, label, numeric = false) ->
  m '.form-group', [
    m 'label', label
    m 'input[type.text].form-control',
      value: get key
      onchange: (e) ->
        if numeric
          n = parseInt(e.target.value)
          if not n.isNan! and n >= 0
            set key, n
        else
          set key, e.target.value
  ]

radio = (key, val, label) ->
  m '.radio', m 'label', [
    m 'input[type=radio]',
      value: 'channel'
      checked: get(key) == val
      onchange: -> set key, val
    m 'span', label
  ]

view-tabs =
  autojoin: -> [
    m 'h3', 'Autojoin'
    m 'p', 'Turbo will automatically join the following channels on login:'
    m '.autojoin', _.pairs(settings!.autojoin).map (p) ->
      m '.character', [
        m 'b', p[0]
        m 'span', ' will autojoin'
        m '.channels', p[1].map (ch) ->
          m '.channel', [
            m '.pull-right', m 'button.btn.btn-xs.btn-danger',
              onclick: -> removeAutojoin p[0], ch
            , 'Remove'
            m 'span', ch.title
          ]
      ]
    m 'p.small', 'You can add a channel to this list via its Action Pad (press Ctrl-C or click the popup icon while in the channel).'
  ]

  messages: -> [
    m 'h3', 'Buffers and Messages'
    input 'scrollback', 'Tabs keep this many lines for scrollback:', true
    input 'recentLinks', 'Tabs remember this many links for the Recent Links pad (Ctrl-O):', true
    input 'timeFormat', 'Messages display their time stamps like this:'
  ]

  ads: -> [
    m 'h3', 'Ads'
    m 'p', 'How do you like your LFRP ads?'
    radio 'adMode', 'all', 'Show them in channels and collect them in the Ad tab'
    radio 'adMode', 'tab', 'Ad tab only'
    radio 'adMode', 'none', 'Don\'t show any ads'
    input 'recentAds', 'The Ad tab keeps this many ads:', true
    m 'p', 'Always block ads in these channels:'
    m '.adblock-channel', settings!.adblockChannels.map (ch) ->
      m '.channel', [
        m '.pull-right', m 'button.btn.btn-xs.btn-danger',
          onclick: -> removeAdblock ch
        , 'Remove'
        m 'span', ch.title
      ]
    m 'p', 'Always block ads from these characters:'
    m '.adblock-character', settings!.adblockCharacters.map (cr) ->
      m '.character', [
        m '.pull-right', m 'button.btn.btn-xs.btn-danger',
          onclick: -> removeAdblock cr
        , 'Remove'
        m 'span', cr
      ]
    m 'p.small', 'Add channels or characters from their Action Pad (Ctrl-C / popup icon).'
  ]

  logging: -> [
    m 'h3', 'Logging'
    m 'p', 'Turbo will keep logs of:'
    radio 'logging', 'all', 'Everything'
    radio 'logging', 'ims', 'Private Messages'
    radio 'logging', 'none', 'Nothing'
    m 'p', 'And no matter what you set above, Turbo will ALWAYS log:'
    m '.autojoin-channels', settings!.alwaysLog.map (ch) ->
      m '.channel', [
        m '.pull-right', m 'button.btn.btn-xs.btn-danger',
          onclick: -> set 'alwaysLog', _.remove(get('alwaysLog'), (ac) -> ac.name == ch.name)
        , 'Remove'
        m 'span', if c.type == 'channel' then c.title else c.name
      ]
    m 'p.small', 'You can add channels or characters to this list, or save logs for the running session only, from their Action Pad (Ctrl-C while viewing the tab, or click the popup icon).'
  ]

selectedTab = m.prop 'autojoin'
justSaved = m.prop false
module.exports =
  get: get
  set: set
  save: save
  addAutojoin: addAutojoin
  removeAutojoin: removeAutojoin
  addAdblock: addAdblock
  removeAdblock: removeAdblock
  propFor: (key) ->
    return (val) ->
      s = settings!
      if val?
        s[key] = value
        s.saved = false
        settings s
      else
        return s[key]
  view: (c) -> m '.settings', [
    m 'ul.nav.nav-pills', Object.keys(view-tabs).map (tab) ->
      m 'li',
        class: if tab == selectedTab! then 'active' else ''
      , m 'a',
        onclick: -> selectedTab tab
      , tab.charAt(0).toUpperCase! + tab.slice(1)

    m '.tab-view', view-tabs[selectedTab!]!

    m 'button.btn.btn-primary',
      onclick: ->
        save!
        justSaved true
        setTimeout ->
          justSaved false
        , 3000
    , 'Save Settings'
    if justSaved!
      m 'span', 'Settings saved.'
  ]


