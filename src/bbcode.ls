# bbcode.ls -- BBCode-to-HTML converter

# this maps bbcode tags to a function which must return a bit of valid html.
# parameters are:
# c - the already processed contents of the tag
# s - the current position in the parsing stack (use to check if within some other tag)
# p - (optional) parameter
tagmap =
  noparse: (c, s, p) -> c
  color: (c, s, p) ->
    if p?
      '<span style="color:"' + p + ';">' + c + '</span>'
    else
      c
  b: (c, s, p) -> '<b>' + c + '</b>'
  i: (c, s, p) -> '<i>' + c + '</i>'
  url: (c, s, p) ->
    domain = p.match(/^https?:\/\/([\w-.]+)/)?[1] or 'unknown domain'
    '<a href="' + p + '" target="_blank">' + c + ' <span class="small">[' + domain + ']</span></a>'
  sub: (c, s, p) -> '<sub>' + c + '</sub>'
  sup: (c, s, p) -> '<sup>' + c + '</sup>'

tagrx = /\[(\w+)=?([^\]]*)\]/

nextValid = (str) ->
  pos = 0
  next = null
  while next == null and pos < str.length - 1
    next := tagrx.exec str.substring(pos)
    if next != null
      if _.has(tagmap, next[1]) == false
        pos := pos + next.index + next[0].length
        next := null
    else
      break
  if next?
    next.index = pos + next.index
  return next

bbcodeRec = (bb, stack) ->
  if bb.length == 0
    return ''
  if stack.length > 10
    return bb
  if stack[0] == 'noparse'
    return '<span class="noparse">' + bb + '</span>'
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
    tagmap[next[1]](bbcodeRec(insideTag, [next[1]].concat(stack)), stack, next[2]) +
    bbcodeRec(afterTag, stack)

module.exports = (bb) -> bbcodeRec bb, []

