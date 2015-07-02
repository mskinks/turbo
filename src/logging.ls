# logging.ls -- everything to do with logging etc.

settings = require 'settings'

if module.hot
  module.hot.accept 'settings', ->
    settings := require 'settings'

# detect if logging facilities (indexedDB) are available
# if so, open the database for access.
available = false
db = null
batchLogs = []
if window.indexedDB
  # https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API/Using_IndexedDB
  dbo = window.indexedDB.open 'TurboLogs'
  dbo.onerror = ->
    available false
  dbo.onupgradeneeded = (ev) ->
    db = ev.target.result
    os = db.createObjectStore 'logs', keyPath: 'key'
    os.createIndex 'timestamp', 'timestamp', unique: false
    os.createIndex 'character', 'character', unique: false
    os.createIndex 'channel', 'channel', unique: false
    os.createIndex 'on', 'on', unique: false
    os.createIndex 'tags', 'tags', unique: false
  dbo.onsuccess = (ev) ->
    innerDB = ev.target.result

    # flush batched logs to db every second (if there are any)
    setTimeout ->
      if batchLogs.length > 0
        flush = batchLogs.splice(0)
        tx = innerDB.transaction ['logs'], "readwrite"
        os = tx.objectStore 'logs'
        flush.forEach (log) ->
          os.add log
    , 1000

    db :=
      writeLog: (kind, target, log) ->
        log.key = Math.floor(log.timestamp.getTime! / 1000) + '-' + log.character
        log.channel = if kind == 'channel' then target else null
        log.on = state.character!
        batchLogs.push log
      fetchLogs: (query) ->
        innerDB.transaction ['logs']
        os = tx.objectStore 'os'

    available := true
else
  available := false

# do the actual logging
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
    if available
      db.writeLog kind, targetName, msg
    target.logs msgs

module.exports =
  log: log
  available: available

