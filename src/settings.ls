# settings.ls -- Turbo settings that can be saved to local application
# storage.

template = ->
  return do
    showUsers: true
    autojoin: []
    scrollback: 100
    recentLinks: 6
    timeFormat: 'HH:mm'

settings = m.prop template!

# try loading settings on load
loaded = window.localStorage.getItem 'turbo-settings'
if loaded?
  loaded = JSON.parse loaded
  settings _.merge settings!, loaded

module.exports =
  get: (key) -> settings![key]
  set: (key, value) ->
    s = settings!
    s[key] = value
    s.saved = false
    settings s
  propFor: (key) ->
    return (val) ->
      s = settings!
      if val?
        s[key] = value
        s.saved = false
        settings s
      else
        return s[key]
  save: ->
    s = settings!
    s.saved = true
    window.localStorage.setItem 'turbo-settings', JSON.stringify(s)
    settings s

