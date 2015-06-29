# renderables.ls -- stuff that gets rendered again and again (like username badges)

module.exports =
  user: (user) ->
    m 'div.user', [
      m 'a',
        class: user.gender or ''
        href: 'https://www.f-list.net/c/' + user.name
        target: '_blank'
      , user.name
    ]

