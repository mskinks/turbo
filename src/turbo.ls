# this causes webpack to compile and load the CSS
# require '../css-src/turbo.less'
require '../css-src/turbo.less'

# load the login and app components. in development mode,
# reload them on the fly whenever they change thanks to webpack dev server.
login = require 'login'
app = require 'app'
navbar = require 'navbar'
actionpad = require 'actionpad'
require('keybindings')

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
  module.hot.accept 'actionpad', ->
    actionpad := require 'actionpad'
    m.redraw!
  module.hot.accept 'keybindings', ->
    require('keybindings')

Main =
  page: ->
    if state.chat.status! == 'connected'
      return app.view!
    else if state.chat.status! == 'connecting'
      return m '.connecting', [
        m 'div.whee',
          style: 'background: url(https://static.f-list.net/images/avatar/' + encodeURIComponent(state.character!.toLowerCase!) + '.png) no-repeat;'
        m 'h4', 'Connecting... please wait.'
      ]
    else
      return login.view!

  view: (c) -> m 'div.turbo.flex.column', [
    navbar.view!
    @page!
    if state.actionpad! then actionpad.view!
  ]

window.m = m

m.mount document.body, Main
