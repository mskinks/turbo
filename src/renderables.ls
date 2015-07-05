# renderables.ls -- stuff that gets rendered again and again (like username badges)

require! state
require! settings
require! moment
require! bbcode

actionpad = require 'actionpad'
if module.hot
  module.hot.accept 'actionpad', ->
    actionpad := require 'actionpad'

user = (user) ->
  m 'span.user', [
    m 'a',
      class: user.gender or ''
      onclick: -> actionpad.invoke 'character', user.name
    , user.name
  ]

message = (tf, msg) ->
  u = state.chat.characters[msg.character] or { name: msg.character, gender: 'Offline' }
  if msg.type == 'm' or msg.on?
    return m 'div.message',
      key: msg.character + '-' + msg.timestamp.getTime!
    , [
      m 'span.timestamp', '[' + moment(msg.timestamp).format(tf) + ']'
      user u
      m 'span.message', m.trust bbcode msg.message
    ]

module.exports =
  user: user
  message: message
