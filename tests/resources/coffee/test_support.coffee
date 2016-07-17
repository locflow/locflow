@TestSupport =
  createElement: (tagName, id) ->
    elm = document.createElement tagName
    elm.className = 'testing'
    elm.id = id if id
    elm

  insertElement: (tagName, id) ->
    document.body.appendChild(@createElement(tagName, id))

  insertDiv: (id) ->
    @insertElement 'div', id

  createAuthenticityToken: ->
    csrf = document.createElement 'meta'
    csrf.name = 'authenticity_token'
    csrf.content = '123456'
    document.head.appendChild(csrf)

  removeAuthenticityToken: ->
    tokens = document.querySelectorAll('meta[name="authenticity_token"]')
    for token in tokens
      token.parentNode.removeChild(token)

  createDiv: (id) ->
    @createElement 'div', id

  insertAnchor: (id) ->
    @insertElement 'a', id

  createAnchor: (id) ->
    @createElement 'a', id

  removeAllElements: ->
    elms = document.querySelectorAll '.testing'
    elm.parentNode.removeChild(elm) for elm in elms
