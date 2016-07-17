describe 'Locflow.Visit specs', ->
  beforeEach ->
    Locflow.initialize(false)
    Locflow.router.removeAll()

  it 'has a default state of initialized', ->
    visit = new Locflow.Visit '/home'
    expect(visit.state).to.eq 'initialized'

  describe '#start', ->
    it 'updates state to `started`', ->
      visit = new Locflow.Visit '/home'
      visit.start()
      expect(visit.stateHistory).to.include 'started'

    it 'calls the `onVisit` method from the Router', ->
      Locflow.router.register '/home',
        onVisit: (visit) -> visit.going_to = 'called_from_route'
        onLeave: (visit) ->
      visit = new Locflow.Visit '/home'
      visit.start()
      expect(visit.going_to).to.eq 'called_from_route'

    it 'tracks `start` timing', ->
      visit = new Locflow.Visit '/home'
      expect(visit.timing.start).not.to.be.ok
      visit.start()
      expect(visit.timing.start).to.be.ok

  describe '#propose', ->
    it 'invokes adapter visitProposed callback', ->
      Locflow.initialize false
      sinon.spy(Locflow.adapter, 'visitProposed')
      visit = new Locflow.Visit '/home'
      visit.propose()
      expect(Locflow.adapter.visitProposed.called).to.be.true
      expect(Locflow.adapter.visitProposed.calledWith(visit)).to.be.true

  describe '#advanceHistory', ->
    visit = null
    beforeEach -> visit = new Locflow.Visit '/about'

    it 'inserts a new entry in the browser history', ->
      previous = history.length
      visit.advanceHistory()
      expect(history.length).to.eq previous + 1

    it 'updates the browser location to the visit url', ->
      visit.advanceHistory()
      location = new Locflow.Url(document.location)
      expect(location.path).to.eq '/about'

  describe '#restore', ->
    it 'invokes `restore` action in the route', ->
      route = Locflow.router.register '/home',
        restore: (visit, cache) -> visit.restoring_in = 'home'
        onVisit: (visit, cache) ->
        onLeave: (visit, cache) ->
      visit = new Locflow.Visit('/home')
      visit.restore()
      expect(visit.restoring_in).to.eq 'home'

    it 'updates the state to ´restored`', ->
      visit = new Locflow.Visit('/home')
      visit.restore()
      expect(visit.state).to.eq 'restored'

  describe '#loadCachedSnapshot', ->
    it 'updates the current body with the cache associated with the visit', ->
      visit = new Locflow.Visit '/home'
      html = document.createElement 'html'
      html.innerHTML = """
        <body>
          <h1 id="my-title">My title</h1>
        </body>
      """
      body = html.getElementsByTagName("body")[0]
      Locflow.snapshot.cache.put(visit.url.toString(), body: body)
      visit.loadCachedSnapshot()
      title = document.getElementById('my-title')
      expect(title).to.be.ok
      expect(title.innerHTML).to.eq('My title')

  describe '#render', ->
    xhr = requests = null
    beforeEach ->
      xhr = sinon.useFakeXMLHttpRequest()
      xhr.onCreate = (req) -> requests.push(req)
      requests = []
      Locflow.initialize(false)

    it 'renders the HTML from the request response', ->
      visit = new Locflow.Visit '/home'
      visit.requestResponse = """
      <html>
        <head>
          <title>my-title</title>
        </head>
        <body>
          <div id="my-element">ok</div>
        </body>
      </html>
      """
      visit.requestStatus = 200
      visit.render()
      elm = document.getElementById 'my-element'
      expect(elm).to.be.ok
      expect(document.title).to.eq 'my-title'

    it 'calls visitRequestFinished in the adapter', ->
      visit = new Locflow.Visit '/home'
      visit.requestResponse = """
      <html>
        <body>
        </body>
      </html>
      """
      visit.requestStatus = 200
      sinon.spy(Locflow.adapter, 'visitRequestFinished')
      visit.render()
      expect(Locflow.adapter.visitRequestFinished.called).to.be.true

  describe '#sendRequest', ->
    xhr = requests = null
    beforeEach ->
      xhr = sinon.useFakeXMLHttpRequest()
      xhr.onCreate = (req) -> requests.push(req)
      requests = []
      Locflow.initialize(false)

    it 'sends a GET request to the visit url path', ->
      visit = new Locflow.Visit '/home'
      visit.sendRequest()
      expect(requests).to.have.length(1)
      expect(requests[0].url).to.eq '/home'
      expect(requests[0].method).to.eq 'GET'

    it 'stores the response and status from the server', ->
      visit = new Locflow.Visit '/home'
      visit.sendRequest()
      requests[0].respond(200, {}, 'ok')
      expect(visit.requestResponse).to.eq 'ok'
      expect(visit.requestStatus).to.eq 200

    it 'calls visitRequestCompleted in the adapter if requst succeeds', ->
      visit = new Locflow.Visit '/home'
      visit.sendRequest()
      sinon.spy(Locflow.adapter, 'visitRequestCompleted')
      requests[0].respond(200, {}, 'ok')
      expect(Locflow.adapter.visitRequestCompleted.called).to.be.true

    it 'calls visitRequestFailedWithStatusCode in the adapter if request fails', ->
      visit = new Locflow.Visit '/home'
      visit.sendRequest()
      sinon.spy(Locflow.adapter, 'visitRequestFailedWithStatusCode')
      requests[0].respond(500, {}, 'fail')
      expect(Locflow.adapter.visitRequestFailedWithStatusCode.called).to.be.true

    it 'calls visitRequestTimeout in the adapter if the request timeouts', (done) ->
      visit = new Locflow.Visit '/home'
      visit.timeoutMillis = 2
      sinon.spy(Locflow.adapter, 'visitRequestTimeout')
      visit.sendRequest()
      setTimeout(->
        expect(Locflow.adapter.visitRequestTimeout.called).to.be.true
        done()
      , 3)
