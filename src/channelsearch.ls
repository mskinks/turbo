# channelsearch.ls -- the channel search tab

filters =
  search: m.prop ''
  show: m.prop ['channel', 'room']

joinChannel = (name) ->
  conn.send 'JCH',
    channel: name

refreshChannels = (allprop) ->
  allprop {}
  conn.send 'CHA'
  conn.send 'ORS'

channel = (chan) ->
  m 'tr.channel',
    key: chan.name
    onclick: -> joinChannel chan.name
  , [
    m 'td', chan.type
    m 'td', chan.title
    m 'td', chan.characters
  ]

listChannels = (all) ->
  filtered = _(all).values!.filter (chan) ->
    if filters.search!.length > 0 and chan.title.toLowerCase!.indexOf(filters.search!.toLowerCase!) == -1
      return false
    return _.includes filters.show!, chan.type
  .sortByOrder 'characters', false
  .value!

  return m 'table.table.table-striped', [
    m 'thead', m 'tr', [
      m 'th', 'Type'
      m 'th', 'Name'
      m 'th', '#'
    ]
    m 'tbody', filtered.map channel
  ]

module.exports =
  view: (c) ->
    m '.channelsearch.scroll', [
      m '.options.panel.panel-default', [
        m '.panel-heading', [
          m '.pull-right', [
            m 'button.btn.btn-xs.btn-primary',
              onclick: -> refreshChannels state.chat.allChannels
            , 'Refresh List'
          ]
          m '', 'Show channels:'
        ]
        m '.panel-body', [
          m 'input[type=text].form-control]',
            placeholder: 'Type here for Quick Search...'
            onkeyup: m.withAttr 'value', filters.search
            value: filters.search!
          m 'label.checkbox-inline', [
            m 'input[type=checkbox]',
              onchange: -> filters.show _.xor(filters.show!, ['channel'])
              checked: _.contains filters.show!, 'channel'
            , ''
          ], 'Show public channels'
          m 'label.checkbox-inline', [
            m 'input[type=checkbox]',
              onchange: -> filters.show _.xor(filters.show!, ['room'])
              checked: _.contains filters.show!, 'room'
            , ''
          ], 'Show private rooms'
        ]
      ]
      m '.results', if state.chat.allChannels!
        listChannels state.chat.allChannels!
      else
        'Waiting for channel list from F-Chat server...'
    ]
