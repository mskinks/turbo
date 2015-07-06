# logging.ls -- everything to do with logging etc.

settings = require 'settings'

if module.hot
  module.hot.accept 'settings', ->
    settings := require 'settings'

# helper functions for putting log data together
checkLogDay = (ix, range, day, resultmap) ->
  creq = ix.count(range)
  creq.onsuccess = ->
    resultmap[day] = creq.result

# detect if logging facilities (indexedDB) are available
# if so, open the database for access, set everything up,
# and return a safe-ish database interface, hiding the details.
# yes, this is pretty gnarly code. maybe a FIXME, but maybe not
# (performance etc).
available = true
db = null
batchLogs = []
if window.indexedDB and db == null
  # https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API/Using_IndexedDB
  dbo = window.indexedDB.open 'TurboLogs'
  dbo.onupgradeneeded = (ev) ->
    db = ev.target.result
    chlogs = db.createObjectStore 'channels', keyPath: 'key'
    chlogs.createIndex 'logs', ['on', 'channel', 'timestamp'], unique: false
    chlogs.createIndex 'targets', ['on', 'channel'], unique: false
    chlogs.createIndex 'tags', 'tags', unique: false
    crlogs = db.createObjectStore 'ims', keyPath: 'key'
    crlogs.createIndex 'logs', ['on', 'with', 'timestamp'], unique: false
    crlogs.createIndex 'targets', ['on', 'with'], unique: false
    crlogs.createIndex 'tags', 'tags', unique: false
  dbo.onerror = (e) ->
    console.log e
    available := false
  dbo.onsuccess = (ev) ->
    innerDB = ev.target.result

    # flush batched logs to db every 3 seconds (if there are any)
    setInterval ->
      if batchLogs.length > 0
        flush = batchLogs.splice(0)
        logmode = settings.get 'logging'
        always = _.union settings.get('alwaysLogNames'), state.chat.logging!

        # no need to log if
        if logmode == 'none' and always.length == 0 then return

        tx = innerDB.transaction ['channels', 'ims'], "readwrite"
        lch = tx.objectStore 'channels'
        lcr = tx.objectStore 'ims'
        flush.forEach (log) ->
          if log.channel?
            if (logmode == 'ims' or logmode == 'none') and
              always.indexOf(log.channel) == -1 then return
            lch.put log
          else
            if logmode == 'none' and always.indexOf(log.character) == -1 then return
            lcr.put log
    , 3000

    db :=
      queueLog: (isChannel, target, log) ->
        log.key = Math.floor(log.timestamp.getTime! / 1000) + '-' + log.character
        if isChannel
          log.channel = target
        else
          log.with = target
        log.on = state.character!
        batchLogs.push _.omit log, 'type'
      getLogTargets: (osName, recvProp) ->
        tx = innerDB.transaction [osName]
        os = tx.objectStore osName
        ix = os.index 'targets'
        uniqs = []
        ix.openKeyCursor(null, 'nextunique').onsuccess = (ev) ->
          c = ev.target.result
          if c?
            uniqs.push c.key
            c.continue!
          else
            recvProp _.pluck uniqs, 1

      getLogMonth: (osName, character, target, year, month, recvf) ->
        KeyRange = window.IDBKeyRange
        current = new Date year, month, 1
        last = new Date year, month + 1, 0

        daymap = {}
        tx = innerDB.transaction [osName]
        os = tx.objectStore osName
        ix = os.index 'logs'
        tx.oncomplete = ->
          recvf daymap

        # what this does: because of IDB limitations but thanks to its high
        # concurrency, we step through the month day by day and for every day
        # we fire off a request to get the number of logs for that day
        # (asynchronously). those get added to the daymap. tx.oncomplete
        # is called by the transaction when the last callback finishes.
        #
        # FIXME: this is hopefully pretty performant. check and if not so,
        # add another index. :/
        while current <= last
          next = new Date current.getTime!
          next.setDate(next.getDate! + 1)
          range = KeyRange.bound [character, target, current],
            [character, target, next], false, true

          # it's current.getDate! - 1 because the processing will be 0-based
          # whereas javascript DAY dates are 1-based (for some reason months
          # are 0-based again...)
          checkLogDay ix, range, (current.getDate! - 1), daymap
          current = next

      getLogs: (osName, character, target, date, recvf) ->
        upper = new Date date.getTime!
        upper.setDate(upper.getDate! + 1)
        tx = innerDB.transaction [osName]
        os = tx.objectStore osName
        ix = os.index 'logs'
        range = window.IDBKeyRange.bound [character, target, date],
          [character, target, upper], false, true

        logs = []
        ocr = ix.openCursor range
        ocr.onsuccess = (ev) ->
          cursor = ev.target.result
          if cursor?
            logs.push cursor.value
            cursor.continue!
          else
            recvf logs


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

# dump a channel's scrollback to the log database
# this happens when always logging or session logging is activated on a channel
addScrollback = (thing) ->
  target = null
  if thing.title
    target = state.chat.channels[thing.name]
  else
    target = state.chat.ims[thing.name]
  target.logs!.forEach (log) ->
    db.queueLog thing.title?, (target.title or target.name), log

# log live (i.e. an incoming message)
log = (kind, targetName, type, msg) ->
  scrollback = settings.get 'scrollback'
  msg = _.merge msg, { type: type, timestamp: new Date! }
  target = null
  title = null
  if kind == 'channel'
    target = state.chat.channels[targetName]
    title = state.chat.allChannels![targetName].title
  else
    target = state.chat.ims[targetName]
  msgs = target.logs!
  if msgs?
    detectLinks msg, target
    msgs.push msg
    # TODO optimize array splicing for performance if possible
    msgs := msgs.splice(0 - scrollback)
    if state.currentTab!.name != targetName and target.unread! < scrollback
      target.unread target.unread! + 1
    if available and type == 'm'
      db.queueLog (kind == 'channel'), (title or targetName), msg
    target.logs msgs

getLogTargets = (type, prop) ->
  prop null
  db.getLogTargets type, prop

getLogMonth = (osName, character, target, year, month, recvf) ->
  db.getLogMonth ...

getLogs = (osName, character, target, date, recvf) ->
  db.getLogs ...

exports.log = log
exports.addScrollback = addScrollback
exports.getLogTargets = getLogTargets
exports.getLogMonth = getLogMonth
exports.getLogs = getLogs
exports.available = -> available

