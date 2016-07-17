@Locflow =
  version: '2.0.0'

  supported: do ->
    window.history.pushState? and window.requestAnimationFrame?

  back: ->
    history.back()

  forward: ->
    history.forward()

  visit: (path, opts) ->
    visit = new Locflow.Visit(path, opts)
    visit.propose()
    visit

  submit: (target) ->
    form = new Locflow.Form(target)
    form.submit()

  match: (path, callback) ->
    @handler ||= new Locflow.Handler()
    @handler.match(path, callback)

  route: (path, callbacks) ->
    @router ||= new Locflow.Router()
    @router.register(path, callbacks)

  initialize: (sendInitialRequest = true) ->
    @adapter = new Locflow.Adapter.Browser()
    @renderer = new Locflow.Renderer()
    @router ||= new Locflow.Router()
    @handler ||= new Locflow.Handler()
    @interceptor = new Locflow.Interceptor()
    @interceptor.intercept(document.body.parentNode)
    if sendInitialRequest
      visit = new Locflow.Visit(new Locflow.Url(document.location))
      @router.invokeCustomRoute(visit)
      visit.callHandlers()

  useAuthenticityTokenFromMeta: (metaName, attrName) ->
    @csrf = new Locflow.Csrf(metaName, attrName)

Locflow.Encoding = {}
Locflow.Adapter = {}

if Locflow.supported
  window.addEventListener 'popstate', (ev) ->
    url = new Locflow.Url(document.location)
    visit = new Locflow.Visit(url, action: 'restore')
    visit.propose()
  window.addEventListener('load', -> Locflow.initialize(true))
