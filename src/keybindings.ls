# keybindings.ls -- global (and maybe local) keybindings

key = require 'keymaster'
actionpad = require 'actionpad'
require! state

if module.hot
  module.hot.accept 'actionpad', ->
    actionpad := require 'actionpad'

# catch keys even when in an input element
key.filter = -> true

key 'ctrl+space', ->
  if !state.actionpad!
    actionpad.invoke!
  else
    state.actionpad false
    m.redraw!

activeFrame = ->
  if state.focus! == 'popout'
    return state.popout!
  else
    return state.currentTab!

key 'ctrl+o', ->
  f = activeFrame!
  if f.type == 'channel'
    actionpad.invoke 'openlink', f.name, state.chat.channels[f.name]
  if f.type == 'im'
    actionpad.invoke 'openlink', f.name, state.chat.ims[f.name]
  return false

key 'ctrl+c', ->
  f = activeFrame!
  if f.type == 'channel'
    actionpad.invoke 'channel', f.name, state.chat.channels[f.name]

key 'esc', ->
  state.actionpad false
  m.redraw!

switchTab = (step) ->
  tabs = state.tabs!
  idx = _.indexOf tabs, state.currentTab!
  if idx != -1
    nidx = idx + step
    if nidx >= 0 and nidx < tabs.length
      state.currentTab tabs[nidx]
      m.redraw!

key 'ctrl+down', -> switchTab 1
key 'ctrl+up', -> switchTab -1

key 'ctrl+p', ->
  if state.popout!?
    tab = state.popout!
    state.tabs state.tabs!.concat tab
    state.popout null
  else
    tab = state.currentTab!
    if (tab.type == 'channel' or tab.type == 'im') and state.tabs!.length > 1
      i = _.indexOf state.tabs!, tab
      state.popout tab
      state.tabs _.without(state.tabs!, tab)
      if i >= state.tabs!.length
        i := state.tabs!.length - 1
      state.currentTab state.tabs![i]
  m.redraw!
  return false
