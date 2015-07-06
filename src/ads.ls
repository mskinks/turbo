# ads.ls -- roleplaying ads

logging = require 'logging'
settings = require 'settings'
r = require 'renderables'

if module.hot
  module.hot.accept 'settings', ->
    settings := require 'settings'
  module.hot.accept 'logging', ->
    logging := require 'logging'
  module.hot.accept 'renderables', ->
    r := require 'renderables'

displayAds = ->
  rm = (msg) -> r.message settings.get('timeFormat'), msg
  _(state.chat.recentAds!)
  .filter (ad) ->
    return true
  .map (ad) ->
    rm _.merge(ad, type: 'ad')
  .value!

exports.receive = (ad) ->
  admode = settings.get 'adMode'
  if admode == 'none' then return
  if _.contains(settings.get('adblockChannels'), ad.channel) then return
  if _.contains(settings.get('adblockCharacters'), ad.character) then return
  genders = settings.get 'adblockGenders'
  if genders.length > 0
    c = state.chat.characters[ad.character]
    if c? and _.contains genders, c.gender then return
  if admode == 'all'
    logging.log 'channel', ad.channel, 'ad', ad
  ads = state.chat.recentAds!
  state.chat.recentAds [_.merge(ad, timestamp: new Date!)].concat(ads.slice(0, settings.get('recentAds')))

exports.view = (c) ->
  m '.ad-viewer', [
    m '.ad-filter', [
      m 'p', 'fumbulant'
    ]
    m '.ad-display', displayAds!
  ]
