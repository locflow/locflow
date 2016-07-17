class Locflow.Adapter.Browser
  constructor: ->
    @progressBar = new Locflow.ProgressBar()

  visitProposed: (visit) ->
    visit.start()

  visitRequestStarted: (visit) ->
    visit.changeHistory()
    if visit.action is 'restore'
      visit.restore()
    else
      visit.loadCachedSnapshot()
    @progressBar.setValue(0)
    @progressBar.show()

  visitRequestProgressed: (value) ->
    @progressBar.setValue value

  visitRequestCompleted: (visit) ->
    visit.render()

  visitRequestFinished: (visit) ->
    @progressBar.setValue(100)
    setTimeout(=>
      @progressBar.hide()
    , 50)
    visit.callHandlersIfNotRestore()

  visitRequestFailedWithStatusCode: (visit) ->
    console.log 'VISIT FAILED'

  visitRequestTimeout: (visit) ->
    console.log 'VISIT TIMEOUTED'
