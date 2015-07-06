# renderables.ls -- stuff that gets rendered again and again (like username badges)

require! settings
require! moment
require! bbcode

actionpad = require 'actionpad'

user = (user) ->
  classes = []
  if user.gender?
    classes.push user.gender.toLowerCase!
  if user.status?
    classes.push user.status.toLowerCase!
  m 'span.user',
    class: classes.join ' '
  , [
    m 'a',
      onclick: -> actionpad.invoke 'character', user.name
    , user.name
  ]

message = (tf, msg) ->
  u = state.chat.characters[msg.character] or { name: msg.character, gender: 'Offline', status: 'Offline' }
  if msg.type == 'm' or msg.on?
    content = msg.message
    cls = 'm'
    if content.substr(0, 3) == '/me'
      content = content.substr(3)
      if content.length <= 140
        cls = 'act'
      else
        cls = 'act long'
    return m 'div.message',
      class: cls
      key: msg.character + '-' + msg.timestamp.getTime!
    , [
      m 'span.timestamp', '[' + moment(msg.timestamp).format(tf) + ']'
      user u
      m 'span.message', m.trust bbcode content
    ]
  else if msg.type == 'ad'
    return m 'div.message.ad',
      key: msg.character + '-' + msg.timestamp.getTime!
    , [
      m 'span.channel', msg.channel
      m 'span.timestamp', '[' + moment(msg.timestamp).format(tf) + ']'
      user u
      m 'span.message', m.trust bbcode msg.message
    ]

exports.user = user
exports.message = message
