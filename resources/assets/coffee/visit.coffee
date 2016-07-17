class Locflow.Visit
  constructor: (@url, @opts = { action: 'advance' }) ->
    @action = @opts.action
    @state = 'initialized'
    @stateHistory = [@state]
    @timing = {}
    @timeoutMillis = 4000

  setState: (@state) ->
    @stateHistory.push @state

  propose: ->
    @setState 'proposed'
    Locflow.adapter?.visitProposed(@)

  restore: ->
    @setState 'restored'
    @trackTiming 'restore'
    Locflow.router.restore(@)

  loadCachedSnapshot: ->
    Locflow.snapshot.render(@url.toString())

  start: ->
    @setState 'started'
    @trackTiming 'start'
    Locflow.router.invokeVisit(@)
    Locflow.adapter?.visitRequestStarted(@)

  callHandlersIfNotRestore: ->
    @callHandlers() if @action isnt 'restore'

  callHandlers: ->
    Locflow.handler?.call @url

  render: ->
    Locflow.renderer?.render(@requestResponse)
    @finish()

  finish: ->
    Locflow.adapter?.visitRequestFinished(@)

  progress: (value) ->
    Locflow.adapter?.visitRequestProgressed(value)

  sendRequest: ->
    @request = Locflow.Request.GET @url,
      success: @onRequestSuccess.bind(@)
      error: @onRequestError.bind(@)
      timeout: @onRequestTimeout.bind(@)
      timeoutMillis: @timeoutMillis

  onRequestSuccess: (@requestResponse, @requestStatus, xhr) ->
    Locflow.adapter?.visitRequestCompleted(@)

  onRequestError: (@requestResponse, @requestStatus, xhr) ->
    Locflow.adapter?.visitRequestFailedWithStatusCode(@)

  onRequestTimeout: ->
    Locflow.adapter?.visitRequestTimeout(@)

  changeHistory: () ->
    return @advanceHistory() if @opts.action is 'advance'
    return @replaceHistory() if @opts.action is 'replace'

  advanceHistory: ->
    history.pushState { locflow: true }, null, @url

  replaceHistory: ->
    history.replaceState { locflow: true }, null, @url

  trackTiming: (step) ->
    @timing[step] = new Date().getTime()
