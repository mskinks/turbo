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

justSaved = m.prop false

module.exports =
  get: get
  set: set
  save: save
  addAutojoin: addAutojoin
  removeAutojoin: removeAutojoin
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

    m 'h3', 'Buffers and Messages'
    m '.form-group', [
      m 'label', 'Tabs keep this many lines for scrollback:'
      m 'input[type.text].form-control',
        value: get 'scrollback'
        onchange: (e) ->
          n = parseInt(e.target.value)
          if not n.isNan! and n >= 0
            set 'scrollback', n
    ]
    m '.form-group', [
      m 'label', 'Tabs remember this many links for the Recent Links pad (Ctrl-O):'
      m 'input[type.text].form-control',
        value: get 'recentLinks'
        onchange: (e) ->
          n = parseInt(e.target.value)
          if not n.isNan! and n >= 0
            set 'recentLinks', n
    ]
    m '.form-group', [
      m 'label', 'The Ad tab keeps this many ads:'
      m 'input[type.text].form-control',
        value: get 'recentAds'
        onchange: (e) ->
          n = parseInt(e.target.value)
          if not n.isNan! and n >= 0
            set 'recentAds', n
    ]
    m '.form-group', [
      m 'label', 'Messages display their time stamps like this:'
      m 'input[type.text].form-control',
        value: get 'timeFormat'
        onchange: (e) ->
          set 'timeFormat', e.target.value
    ]

    m 'h3', 'Logging'
    m 'p', 'Turbo will keep logs of:'
    m '.radio', m 'label', [
      m 'input[type=radio]',
        value: 'all'
        checked: get('logging') == 'all'
        onchange: -> set 'logging', 'all'
      m 'span', 'Everything'
    ]
    m '.radio', m 'label', [
      m 'input[type=radio]',
        value: 'ims'
        checked: get('logging') == 'ims'
        onchange: -> set 'logging', 'ims'
      m 'span', 'Private Messages'
    ]
    m '.radio', m 'label', [
      m 'input[type=radio]',
        value: 'none'
        checked: get('logging') == 'none'
        onchange: -> set 'logging', 'none'
      m 'span', 'Nothing'
    ]
    m 'p', 'And no matter what you set above, Turbo will ALWAYS log:'
    m '.autojoin-channels', settings!.alwaysLog.map (ch) ->
      m '.channel', [
        m '.pull-right', m 'button.btn.btn-xs.btn-danger',
          onclick: -> set 'alwaysLog', _.remove(get('alwaysLog'), (ac) -> ac.name == ch.name)
        , 'Remove'
        m 'span', if c.type == 'channel' then c.title else c.name
      ]
    m 'p.small', 'You can add channels or characters to this list, or save logs for the running session only, from their Action Pad (Ctrl-C while viewing the tab, or click the popup icon).'

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


