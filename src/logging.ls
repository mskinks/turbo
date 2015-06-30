# logging.ls -- everything to do with logging etc.

require! settings

linkRx = /https?:\/\/[^\]\s]+/g

detectLinks = (msg, target) ->
  links = msg.message.match linkRx
  if links?
    tlinks = target.links!
    links = links.map (l) ->
      link: l
      from: msg.character
    .concat(tlinks).slice(0, settings.get('recentLinks'))
    target.links links

log = (kind, targetName, type, msg) ->
  scrollback = settings.get 'scrollback'
  msg = _.merge msg, { type: type, timestamp: new Date! }
  target = null
  if kind == 'channel'
    target := state.chat.channels[targetName]
  else
    target := state.chat.ims[targetName]
  msgs = target.logs!
  if msgs?
    detectLinks msg, target
    msgs.push msg
    # TODO optimize array splicing for performance if possible
    msgs := msgs.splice(0 - scrollback)
    if state.currentTab!.name != targetName and target.unread! < scrollback
      target.unread target.unread! + 1
    target.logs msgs

module.exports =
  log: log
