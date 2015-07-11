# characters.ls -- list and search all known characters.
# this is mostly for debug right now (kinks search is more efficient)
# but maybe this can be used somewhere...

require! actionpad
require! renderables

ac =
  search: m.prop ''
  gendersearch: m.prop ''

module.exports =
  view: (c) ->
    m '.all-characters', [
      m '.filters', [
        m 'input[type=text].form-control',
          placeholder: 'Filter Names'
          value: ac.search!
          onkeyup: m.withAttr 'value', ac.search
        m 'input[type=text].form-control',
          placeholder: 'Filter Genders'
          value: ac.gendersearch!
          onkeyup: m.withAttr 'value', ac.gendersearch
      ]
      m '.list', [
        if ac.search!.length > 3 or ac.gendersearch!.length > 3
          m 'div',
            _(_.values(state.chat.characters))
            .filter (char) ->
              if ac.gendersearch!.length > 3 and char.gender.toLowerCase!.indexOf(ac.gendersearch!.toLowerCase!) == -1
                return false
              if ac.search!.length > 3 and char.name.toLowerCase!.indexOf(ac.search!.toLowerCase!) == -1
                return false
              return true
            .sortBy (c) -> c.name.toLowerCase!
            .value!
            .map (char) -> m 'span', [
              m 'span', '- '
              renderables.user char
            ]
      ]
    ]
