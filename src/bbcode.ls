# bbcode.ls -- BBCode-to-HTML converter

# this maps bbcode tags to a function which must return a bit of valid html.
# parameters are:
# c - the already processed contents of the tag
# s - the current position in the parsing stack (use to check if within some other tag)
# p - (optional) parameter
tagmap =
  color: (c, s, p) ->
    if p?
      '<span style="color:"' + p + ';">' + c + '</span>'
    else
      c
  b: (c, s, p) -> '<b>' + c + '</b>'
  i: (c, s, p) -> '<i>' + c + '</i>'
  url: (c, s, p) ->
    domain = p.match(/^https?:\/\/(.+)[\/$]/)?[1] or 'unknown domain'
    '<a href="' + p + '" target="_blank">' + c + ' <span class="small">[' + domain + ']</span></a>'

tagrx = /\[(\w+)=?([^\]]*)\]/

nextValid = (str) ->
  pos = 0
  next = null
  while next == null and pos < str.length - 1
    console.log "next:", next
    console.log "pos:", pos
    console.log "str:", str.substring(pos)
    next := tagrx.exec str.substring(pos)
    if next != null
      if _.has(tagmap, next[1]) == false
        pos := next.index + next[0].length
        next := null
    else
      break
  return next

bbcodeRec = (bb, stack) ->
  if bb.length == 0
    return ''
  if stack.length > 10
    return bb
  next = nextValid bb
  if not next?
    return bb
  closing = '[/' + next[1] + ']'
  end = bb.indexOf(closing)
  if end == -1 or end < next.index
    return bb
  beforeTag = bb.substring(0, next.index)
  afterTag = bb.substring(end + closing.length)
  insideTag = bb.substring(next.index + next[0].length, end)
  return beforeTag +
    tagmap[next[1]](bbcodeRec(insideTag, stack.concat(next[1])), stack, next[2]) +
    bbcodeRec(afterTag, stack)

window.bbcodeRec = bbcodeRec

module.exports = (bb) -> bbcodeRec bb, []

