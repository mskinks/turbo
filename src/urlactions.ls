# urlactions.ls -- intra-chat links that cause chat app actions,
# i.e. clicking on a channel tag to open it.

require! state
conn = require 'connection'

window.onhashchange = (ev) ->
  if window.location.hash == '' then return
  if not state.chat.status! == 'connected' then return
  hash = window.location.hash.substring(1).split('/')
  act = hash[0]
  p = decodeURIComponent(hash[1])
  if act == 'channel'
    t = _.find state.tabs!, (t) -> t.type == 'channel' and t.name == p
    console.log t
    if t?
      state.currentTab t
      m.redraw!
    else
      conn.send 'JCH', channel: p
  window.location.hash = ''
