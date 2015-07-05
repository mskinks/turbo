# logviewer.ls -- the log viewer

require! state
require! settings
require! moment
logging = require 'logging'
r = require 'renderables'

if module.hot
  module.hot.accept 'logging' ->
    logging := require 'logging'
  module.hot.accept 'renderables' ->
    r := require 'renderables'

monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
  'September', 'October', 'November', 'December']

weeksInMonth = (year, month) ->
  first = new Date year, month, 1
  last = new Date year, month + 1, 0
  return Math.ceil((first.getDay! + last.getDate!) / 7)

lv =
  character: m.prop (state.character! or null)
  logtype: m.prop 'ims'
  target: m.prop null
  channels: m.prop []
  ims: m.prop []
  year: m.prop new Date!.getFullYear!
  month: m.prop new Date!.getMonth!
  logdates: m.prop null
  logdate: m.prop null
  logs: m.prop []

logtypes =
  ims: 'IM Logs'
  channels: 'Channel Logs'

targetSelect = (ttype) ->
  m '.form-group', m 'select.form-control',
    value: lv.target!
    onchange: (ev) ->
      lv.target ev.target.value
      logging.getLogMonth lv.logtype!, lv.character!, lv.target!,
        lv.year!, lv.month!, (r) ->
          lv.logdates r
          m.redraw!
  , [m('option', value: null, selected: lv.target! == null, disabled: true, 'Please select')].concat lv[ttype]!.map (t) ->
    m 'option', value: t, selected: lv.target == t, t

changeYear = (d) ->
  lv.year lv.year! + d
  loadMonth!

changeMonth = (d) ->
  lv.month lv.month! + d
  if lv.month! < 0
    lv.year lv.year! - 1
    lv.month 11
  if lv.month > 11
    lv.year lv.year! + 1
    lv.month 0
  loadMonth!

loadMonth = ->
  logging.getLogMonth lv.logtype!, lv.character!, lv.target!,
    lv.year!, lv.month!, (r) ->
      lv.logdates r
      m.redraw!

loadLogs = ->
  logging.getLogs lv.logtype!, lv.character!, lv.target!,
    lv.logdate!, (r) ->
      lv.logs r
      m.redraw!

dayClasses = (day) ->
  classes = []
  if day[1] > 0 then classes.push 'has-logs'
  if lv.logdate!? and lv.logdate!.getDate! == day[0] then classes.push 'selected'
  return classes.join ' '

calendar = ->
  weeks = weeksInMonth lv.year!, lv.month!
  first = new Date(lv.year!, lv.month!, 1).getDay! - 1
  days = (new Date(lv.year!, lv.month! + 1, 0).getDate!) - 1
  if first < 0 then first = 6
  month = []
  for day from 0 to weeks * 7 - 1
    if day >= first and day <= first + days
      month[day] = [(day - first) + 1, lv.logdates![(day - first)]]
    else
      month[day] = [null, 0]
  month = _.chunk month, 7

  m '.date-selection', [
    m '.year-select', [
      m 'button.btn.btn-primary.btn-xs', onclick: (-> changeYear(-1)), '<'
      m 'span', lv.year!
      m 'button.btn.btn-primary.btn-xs', onclick: (-> changeYear(1)), '>'
    ]
    m '.month-select', [
      m 'button.btn.btn-primary.btn-xs', onclick: (-> changeMonth(-1)), '<'
      m 'span', monthNames[lv.month!]
      m 'button.btn.btn-primary.btn-xs', onclick: (-> changeMonth(1)), '>'
    ]
    m '.calendar', month.map (week) ->
      m '.week', week.map (day) ->
        m '.day',
          class: dayClasses day
          onclick: ->
            lv.logdate new Date lv.year!, lv.month!, day[0]
            loadLogs!
        , [
          if day[0]?
            m 'span.num', day[0]
          else
            m 'span', ''
        ]
  ]

module.exports =
  view: (c) ->
    rm = (msg) -> r.message settings.get('timeFormat'), msg
    return m '.log-viewer', [
      m '.log-selection', [
        m 'h5', 'Viewing logs for'
        m '.form-group', m 'select.form-control',
          value: lv.character!
          onchange: m.withAttr 'value', lv.character
        , [m('option', value: null, selected: lv.target! == null, disabled: true, 'Please select')].concat state.ticket!.characters.map (me) ->
          m 'option',
            value: me
            selected: lv.character! == me
          , me
        if lv.character!
          m 'ul.nav.nav-pills', _.pairs(logtypes).map (p) ->
            m 'li',
              class: if lv.logtype! == p[0] then 'active' else ''
            , m 'a',
              onclick: ->
                lv.logtype p[0]
                logging.getLogTargets lv.logtype!, (r) ->
                  lv[lv.logtype!] r
                  m.redraw!
            , p[1]
        if lv.character! and lv[lv.logtype!]!?
          targetSelect lv.logtype!
        if lv.target!? and lv.logdates!?
          calendar!
        else
          m 'p.checking', 'Checking logs...'
      ]
      m '.log-display', [
        m '.info', [
          m 'h4', if lv.logdate!? then
            lv.target! + ', ' + moment(lv.logdate!).format('YYYY-MM-DD')
          else
            'Select a place or character and a date to view logs.'
        ]
        m '.logs', m 'div', lv.logs!.map rm
      ]
    ]
