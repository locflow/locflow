class Locflow.Interceptor
  intercept: (elm) ->
    elm.addEventListener('click', @onClick.bind(@))
    elm.addEventListener('submit', @onSubmit.bind(@))

  shouldIgnore: (elm) ->
    return false if @getElementAction(elm) is 'accept'
    return true if @getElementAction(elm) is 'ignore'
    return true if @getParentAction(elm) is 'ignore'
    false

  getElementAction: (elm) ->
    dataLocflow = elm and elm.getAttribute and elm.getAttribute('data-locflow')
    return 'ignore' if dataLocflow is 'false'
    return 'accept' if dataLocflow is 'true'
    'default'

  getParentAction: (elm) ->
    parent = elm.parentNode
    while parent
      action = @getElementAction parent
      return action if action isnt 'default'
      parent = parent.parentNode
    'default'

  hasParentAnchor: (elm) ->
    @getParentAnchor(elm) isnt null

  getParentAnchor: (elm) ->
    while elm.parentNode
      return elm.parentNode if elm.parentNode.tagName is 'A'
      elm = elm.parentNode
    null

  onClick: (ev) ->
    target = ev.target
    if target.tagName is 'A' and target.href and not @shouldIgnore(target)
      ev.preventDefault()
      @proposeVisitFromAnchor(target)
    else if @hasParentAnchor(target) and not @shouldIgnore(@getParentAnchor(target))
      ev.preventDefault()
      @proposeVisitFromAnchor(@getParentAnchor(target))

  proposeVisitFromAnchor: (anchor) ->
    method = anchor.getAttribute('data-method') or 'GET'
    if method.toUpperCase() isnt 'GET'
      request = new Locflow.Request(method, anchor.href)
      request.send()
    else
      @visit = new Locflow.Visit(anchor.href)
      @visit.propose()

  onSubmit: (ev) ->
    targetForm = ev.target
    if targetForm.getAttribute('data-locflow') is 'remote' and not @shouldIgnore(targetForm)
      ev.preventDefault()
      form = new Locflow.Form(targetForm)
      form.submit()

