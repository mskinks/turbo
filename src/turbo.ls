# this causes webpack to compile and load the CSS
require '../css-src/turbo.less'

require! state
# bind state to window so we can inspect it in the JS console
window.state = state

# load the login and app components. in development mode,
# reload them on the fly whenever they change thanks to webpack dev server.
login = require 'login'
app = require 'app'
navbar = require 'navbar'

if module.hot then
  module.hot.accept 'login', ->
    login := require 'login'
    m.redraw!
  module.hot.accept 'app', ->
    app := require 'app'
    m.redraw!
  module.hot.accept 'navbar', ->
    navbar := require 'navbar'
    m.redraw!

Main =
  page: ->
    if state.chat.status! == 'connected'
      return app.view!
    else if state.chat.status! == 'connecting'
      return m '.connecting', "Connecting! Please wait."
    else
      return login.view!

  view: (c) -> m 'div.turbo.flex.column', [
    navbar.view!
    @page!
  ]

m.mount document.body, Main
