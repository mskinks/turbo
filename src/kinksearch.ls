# kinksearch.ls -- search for people with kinks.

require! state
conn = require 'connection'
bbcode = require 'bbcode'
r = require 'renderables'
ui = require 'ui'

if module.hot
  module.hot.accept 'bbcode' ->
    bbcode := require 'bbcode'
  module.hot.accept 'ui' ->
    ui := require 'ui'
  module.hot.accept 'renderables' ->
    r := require 'renderables'

kinksURL = 'https://www.f-list.net/json/api/kink-list.php'

# TODO the fields are currently hardcoded to avoid downloading the huge fields list every time.
# we can't use the smaller chat fields JSON endpoint because that requires a login for historic
# reasons. current workaround is hoping the fields don't change too often and downloading the
# kinks fresh.
barf = {"genders":["Male","Female","Transgender","Herm","Shemale","Male-Herm","Cunt-boy","None"],"roles":["Always submissive","Usually submissive","Switch","Usually dominant","Always dominant"],"orientations":["Gay","Bi - male preference","Bisexual","Bi - female preference","Straight","Asexual","Pansexual","Bi-curious","Unsure"],"positions":["Always Bottom","Usually Bottom","Switch","Usually Top","Always Top"],"languages":["Arabic","Chinese","Dutch","English","French","German","Italian","Japanese","Korean","Other","Portuguese","Russian","Spanish","Swedish"]}

ks =
  options: m.prop []
  fields: m.prop null
  filter: m.prop ''
  search: m.prop []

order = ['kinks', 'genders', 'orientations', 'roles', 'positions', 'languages']

# TODO this also uses the non-login kinks endpoint (big download). the structure
# is translated into what the regular endpoint will give us once it's login free.
refreshKinks = ->
  m.request do
    method: 'GET'
    url: kinksURL
  .then (r) ->
    kinks = []
    _.values(r.kinks).forEach (group) ->
      group.items.forEach (kink) ->
        kinks.push do
          fetish_id: kink.kink_id
          name: kink.name
    ks.options _.merge barf, kinks: kinks

if ks.options!.length == 0
  refreshKinks!

optionMapper = ->
  if not ks.fields!?
    return [m('tr', m('td', 'Please select something to add above.'))]
  ks.options![ks.fields!]
  .filter (option) ->
    if ks.filter!.length == 0 then return true
    filter = ks.filter!.toLowerCase!
    if ks.fields! == 'kinks'
      option = option.name
    return option.toLowerCase!.indexOf(filter) != -1
  .map (option) ->
    if ks.fields! == 'kinks'
      return m 'tr', [
        m 'td', option.name
        m 'td', m 'button.btn.btn-primary.btn-xs',
          onclick: ->
            ks.search _.union ks.search!, [{
              type: ks.fields!
              name: option.name
              id: option.fetish_id
            }]
        , 'Add'
      ]
    else
      return m 'tr', [
        m 'td', option
        m 'td', m 'button.btn.btn-primary.btn-xs',
          onclick: ->
            ks.search _.union ks.search!, [{
              type: ks.fields!
              name: option
            }]
        , 'Add'
      ]

performSearch = ->
  query = _(ks.search!)
  .groupBy 'type'
  .mapValues (vals) ->
    if vals[0].id?
      return _.pluck vals, 'id'
    else
      return _.pluck vals, 'name'
  .value!

  conn.send 'FKS', _.merge { kinks: [] }, query

resultChar = (cls, c) ->
  m 'tr.result',
    class: cls
  , [
    m 'td.avatar', m 'img',
      src: 'http://static.f-list.net/images/avatar/' + encodeURIComponent(c.name.toLowerCase!) + '.png'
    m 'td', [
      m 'div.user', r.user c
      m 'div.status', m.trust bbcode c.message
    ]
    m 'td.buttons', [
      m 'button.btn.btn-primary.btn-xs',
        onclick: -> window.open('https://www.f-list.net/c/' + c.name)
      , 'Profile'
    ]
  ]

displayResults = ->
  if state.kinksearchresults! == null then return m 'h5', 'Perform a search to the left.'
  chars = _(state.kinksearchresults!.characters)
  .map (c) -> state.chat.characters[c]
  .groupBy 'status'
  .value!
  chars = _.merge { online: [], looking: [] }, chars
  return m '.results', [
    m 'h4', 'Looking for play'
    m 'table.table.table-striped.looking', m 'tbody', chars['looking'].map (c) -> resultChar 'looking', c
    m 'h4', 'Online'
    m 'table.table.table-striped.table-condensed.online', m 'tbody', chars['online'].map (c) -> resultChar 'online', c
  ]

module.exports =
  view: (c) ->
    if ks.options!.length == 0 then return m 'p', 'Hang on, downloading kinks info...'
    m '.kinksearch', [
      m '.search-builder', [
        m '.field-chooser', [
          m 'h4', 'Search for:'
          m '.fields', order.map (f) ->
            m 'button.btn.btn-sm',
              class: if ks.fields! == f then 'btn-success' else 'btn-primary'
              onclick: ->
                ks.fields f
                ks.filter ''
            , f[0].toUpperCase! + f.substring(1)
        ]
        m '.options', [
          m 'input[type=text].form-control.form-sm',
            onkeyup: m.withAttr 'value', ks.filter
            placeholder: 'Quick Search...'
          m '.scroll', m 'table.table.table-striped.table-condensed', m 'tbody', optionMapper!
        ]
        m '.search', [
          m '', [
            m '.pull-right', m 'button.btn.btn-danger.btn-sm',
              onclick: -> ks.search []
            , 'Clear All'
            m 'h4', 'Your Search'
          ]
          m '.scroll', m 'table.table.table-striped.table-condensed', [
            m 'tbody', ks.search!.map (item) ->
              m 'tr', [
                m 'td', item.type[0].toUpperCase!
                m 'td', item.name
                m 'td', m 'button.btn.btn-danger.btn-xs',
                  onclick: -> ks.search _.without(ks.search!, item)
                , 'Remove'
              ]
          ]
        ]
        m '.execute', m 'button.btn.btn-success.btn-lg',
          disabled: ks.search!.length == 0
          onclick: -> performSearch!
        , 'Search!'
      ]
      m '.search-results', displayResults!
    ]

