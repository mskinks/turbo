# login.ls -- the login window
require! state
conn = require 'connection'

problems = m.prop []

loginFields =
  user: m.prop null
  password: m.prop null

ticketURL = window.location.href + 'proxy.php'
logindata = ->
  return do
    account: loginFields.user!
    password: loginFields.password!

if module.hot
  ticketURL = 'https://www.f-list.net/json/getApiTicket.php'

tryLogin = ->
  m.request do
    method: 'POST'
    url: ticketURL
    config: (xhr) ->
      xhr.setRequestHeader "Content-Type", "application/x-www-form-urlencoded"
    serialize: ->
      _(logindata!)
      .pairs!
      .map (p) -> p[0] + '=' + encodeURIComponent(p[1])
      .value!.join('&')
  .then (response) ->
    if response.error? and response.error != '' then
      problems [response.error]
    else
      state.ticket response
  , (error) ->
    problems ["Couldn't get a login ticket: " + error]

  return false

startChat = (acctname, charname) ->
  state.chat.status "connecting"
  conn.connect acctname, charname

module.exports =
  view: (c) -> m '.login-page.columns.centered', [
    m '.panel.login-panel.panel-default', [
      m '.panel-heading', m 'h4', "Please Sign In"

      if not state.ticket!? then
        m '.panel-body', [
          m 'p', "You must sign in to F-List to join the chat."

          if problems!.length > 0 then
            problems!.map (problem) ->
              m '.alert.alert-danger', problem

          m 'form.form-horizontal',
            onsubmit: ->
              tryLogin!
              return false
          , m 'fieldset', [
            m '.form-group', [
              m 'label', "Username"
              m 'div', m 'input[type=text].form-control',
                value: loginFields.user!
                onchange: m.withAttr 'value', loginFields.user
            ]
            m '.form-group', [
              m 'label', "Password"
              m 'div', m 'input[type=password].form-control',
                value: loginFields.password!
                onchange: m.withAttr 'value', loginFields.password
            ]
            m 'button[type=submit].btn.btn-primary', "Sign In"
          ]
        ]
      else
        m '.panel-body', [
          m 'p', "Please choose a character to log into the chat."
          m 'table.table.table-striped.table-hover', m 'tbody', state.ticket!.characters.map (charname) ->
            m 'tr',
              onclick: -> startChat loginFields.user!, charname
            , [
              m 'td', m 'img.avatar-tiny',
                src: "https://static.f-list.net/images/avatar/" + charname.toLowerCase! + ".png"
              m 'td', charname
            ]
        ]
    ]
  ]
