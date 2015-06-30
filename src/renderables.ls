# renderables.ls -- stuff that gets rendered again and again (like username badges)


actionpad = require 'actionpad'
if module.hot
  module.hot.accept 'actionpad', ->
    actionpad := require 'actionpad'

module.exports =
  user: (user) ->
    m 'span.user', [
      m 'a',
        class: user.gender or ''
        onclick: -> actionpad.invoke 'character', user.name
      , user.name
    ]

