# settings.ls -- Turbo settings that can be saved to local application
# storage.

template = ->
  return do
    showUsers: true
    autojoin: []

settings = m.prop template

module.export =
  get: (key) -> settings![key]
  set: (key, value) ->
    s = settings!
    s[key] = value
    s.saved = false
    settings s
  save: ->
    s = settings!
    s.saved = true
    # TODO actual save here
    settings s

