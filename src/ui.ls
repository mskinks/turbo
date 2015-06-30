# ui.ls -- various functions that deal with UI interaction
# tabs, panes, input focus, etc

conn = require 'connection'

activePane = ->
  if state.focus! == 'popout'
    return document.querySelector 'div.popout-pane'
  else
    return document.querySelector 'div.main-pane'

focusTextInput = ->
  ta = document.querySelector('div.chat-pane.active div.channel div.channel-bottom textarea.chat-input')
  if ta?
    ta.focus!

module.exports =
  focusTextInput: focusTextInput

  openTab: (newtab, nofocus) ->
    nofocus = nofocus or false
    if not newtab? then return
    if state.popout!?
      t = state.popout!
      if t.name == newtab.name and t.type == newtab.type
        if not nofocus then state.focus 'popout'
        return
    exists = _.find(state.tabs!, (t) -> t.name == newtab.name and t.type == newtab.type)
    if exists?
      if not nofocus then
        state.focus 'tabs'
        state.currentTab exists
    else
      state.tabs state.tabs!.concat(newtab)
      if not nofocus then state.currentTab newtab
    m.redraw true
    focusTextInput!

  closeTab: (tab) ->
    if not tab? then return
    if tab.onclose? then tab.onclose tab
    if state.popout! == tab
      state.popout null
      state.focus 'tabs'
    else
      if state.currentTab! == tab
        # move focus away from current tab before removing it
        idx = _.findIndex(state.tabs!, (t) -> t.name == tab.name and t.type == tab.type)
        idx = idx - 1
        if idx < 0
          idx := 0
        state.tabs _.without(state.tabs!, tab)
        if state.tabs![idx]?
          state.currentTab state.tabs![idx]
        else
          state.currentTab null
      else
        # not focused, just remove
        state.tabs _.without(state.tabs!, tab)
    if state.tabs!.length == 0
      if state.popout!?
        state.tabs [state.popout!]
        state.popout null
        state.focus 'tabs'
      else
        state.focus 'tabs'
        state.currentTab null
    m.redraw true
    focusTextInput!

  split: ->
    if state.popout!?
      if state.focus! == 'popout'
        # we're popped out and on the popout -- pop back in
        popout = state.popout!
        state.tabs state.tabs!.concat popout
        state.popout null
        state.currentTab popout
        state.focus 'tabs'
      else if state.currentTab!? and (state.currentTab!.type == 'channel' or state.currentTab!.type == 'im')
        # switch current tab with popout
        popout = state.popout!
        tab = state.currentTab!
        state.tabs _.without(state.tabs!, tab).concat popout
        state.popout tab
        state.currentTab popout
        state.focus 'popout'
    else
      # not popped out -- pop out if we have > 1 tabs
      if state.tabs!.length > 1 and state.currentTab!? and (state.currentTab!.type == 'channel' or state.currentTab!.type == 'im')
        tab = state.currentTab!
        idx = _.findIndex(state.tabs!, (t) -> t.name == tab.name and t.type == tab.type)
        idx = idx - 1
        if idx < 0
          idx := 0
        state.tabs _.without(state.tabs!, tab)
        state.currentTab state.tabs![idx]
        state.popout tab
        state.focus 'popout'
    m.redraw true
    focusTextInput!

  moveFocus: (t) ->
    oldfocus = state.focus!
    if t == 'popout'
      if not state.popout!? then return
      state.focus 'popout'
    else
      state.focus 'tabs'
    m.redraw true
    focusTextInput!

  switchTab: (step) ->
    tabs = state.tabs!
    idx = _.indexOf tabs, state.currentTab!
    if idx != -1
      nidx = idx + step
      if nidx >= 0 and nidx < tabs.length
        state.currentTab tabs[nidx]
        m.redraw true
        focusTextInput!

  currentFocus: ->
    if state.popout!? and state.focus! == 'popout'
      return state.popout!
    else if state.currentTab!?
      return state.currentTab!
