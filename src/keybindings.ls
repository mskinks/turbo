# keybindings.ls -- global (and maybe local) keybindings

key = require 'keymaster'
require! state

actionpad = require 'actionpad'
ui = require 'ui'
if module.hot
  module.hot.accept 'actionpad', ->
    actionpad := require 'actionpad'
  module.hot.accept 'ui', ->
    ui := require 'ui'

# catch keys even when in an input element
key.filter = -> true

key 'ctrl+space', ->
  if !state.actionpad!
    actionpad.invoke!
  else
    actionpad.dismiss!

key 'ctrl+o', ->
  f = ui.currentFocus!
  if f.type == 'channel'
    actionpad.invoke 'openlink', f.name, state.chat.channels[f.name]
  if f.type == 'im'
    actionpad.invoke 'openlink', f.name, state.chat.ims[f.name]
  return false

key 'ctrl+c', ->
  f = ui.currentFocus!
  if f.type == 'channel'
    actionpad.invoke 'channel', f.name, state.chat.channels[f.name]

key 'esc', ->
  actionpad.dismiss!

key 'ctrl+down', -> ui.switchTab 1
key 'ctrl+up', -> ui.switchTab -1
key 'ctrl+right', -> ui.moveFocus 'popout'
key 'ctrl+left', -> ui.moveFocus 'tabs'

key 'ctrl+s', ->
  ui.split!
  return false
