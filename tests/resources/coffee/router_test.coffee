describe 'Locflow.router specs', ->
  beforeEach ->
    Locflow.initialize(false)
    Locflow.router.removeAll()

  describe '.register', ->
    it 'associated the given callbacks with the path', ->
      route = Locflow.router.register '/home',
        onVisit: (visit) ->
        onLeave: (visit) ->
      expect(Locflow.router.findMatch('/home')).to.eq(route)

    it 'returns the route object', ->
      route = Locflow.router.register '/home',
        onVisit: (visit) ->
        onLeave: (visit) ->
        restore: (visit, cache) ->
      expect(route.url.path).to.eq '/home'
      expect(route.onVisit).to.be.a('function')
      expect(route.onLeave).to.be.a('function')
      expect(route.restore).to.be.a('function')

    it 'generates an isolated cache object for each route', ->
      route = Locflow.router.register '/home',
        onVisit: (visit, cache) ->
        onLeave: (visit, cache) ->
      otherRoute = Locflow.router.register '/about',
        onVisit: (visit, cache) ->
        onLeave: (visit, cache) ->
      expect(route.cache).to.be.an.instanceof(Locflow.Cache)
      expect(otherRoute.cache).to.be.an.instanceof(Locflow.Cache)
      expect(route.cache).not.to.eq(otherRoute.cache)

  describe '.findMatch', ->
    it 'returns default navigation route if no custom route was found', ->
      expect(Locflow.router.findMatch('/home')).to.eq(Locflow.router.defaultNavigation)

    it 'returns the first match in the order routes are defined', ->
      first = { onVisit: (() -> ), onLeave: (() -> ) }
      secnd = { onVisit: (() -> ), onLeave: (() -> ) }
      Locflow.router.register '/home', first
      Locflow.router.register '/home', secnd
      match = Locflow.router.findMatch '/home'
      expect(match.onVisit).to.eq(first.onVisit)
      expect(match.onLeave).to.eq(first.onLeave)

  describe '.invokeVisit', ->
    homeRoute = null
    aboutRoute = null
    visit = null
    beforeEach ->
      homeRoute = Locflow.router.register '/home',
        onVisit: (visit) -> visit.going_to = 'home'
        onLeave: (visit) -> visit.leaving_from = 'home'
        restore: (visit) -> visit.restoring_in = 'home'
      aboutRoute = Locflow.router.register '/about',
        onVisit: (visit) -> visit.going_to = 'about'
        onLeave: (visit) -> visit.leaving_from = 'about'
        restore: (visit) -> visit.restoring_in = 'about'
      visit = new Locflow.Visit '/home'
      Locflow.router.invokeVisit visit

    it 'stores the given visit as the current route', ->
      expect(Locflow.router.currentRoute).to.eq homeRoute

    it 'stores the latest visit in the router', ->
      expect(Locflow.router.latestVisit).to.eq visit

    it 'invokes the `onVisit` callback in the found route', ->
      expect(visit.going_to).to.eq 'home'

    it 'invokes the `onLeave` callback in the previous route', ->
      latestVisit = Locflow.router.latestVisit
      visit = new Locflow.Visit '/about'
      Locflow.router.invokeVisit(visit)
      expect(latestVisit.leaving_from).to.eq 'home'
      expect(visit.going_to).to.eq 'about'

    it 'keeps the history in the current state (doesnt call changeHistory)', ->
      historyLength = history.length
      visit = new Locflow.Visit '/about'
      Locflow.router.invokeVisit(visit)
      expect(history.length).to.eq(historyLength)

  describe '#invokeCustomRoute', ->
    it 'calls user-defined route for the given visit', ->
      Locflow.router.register '/home',
        onVisit: (visit) -> visit.going_to = 'home'
        onLeave: (visit) -> visit.leaving_from = 'home'
      visit = new Locflow.Visit '/home'
      Locflow.router.invokeCustomRoute(visit)
      expect(visit.going_to).to.eq 'home'

    it 'doesnt call default navigation route if none was found', ->
      visit = new Locflow.Visit '/home'
      sinon.spy(Locflow.router.defaultNavigation, 'onVisit')
      Locflow.router.invokeCustomRoute(visit)
      expect(Locflow.router.defaultNavigation.onVisit.called).to.be.false
      Locflow.router.defaultNavigation.onVisit.restore()

  describe '.restore', ->
    it 'calls the route `restore` callback', ->
      Locflow.router.register '/home',
        restore: (visit) -> visit.restoring_in = 'home'
        onVisit: (visit) ->
        onLeave: (visit) ->
      visit = Locflow.visit('/home')
      Locflow.router.restore(visit)
      expect(visit.restoring_in).to.eq('home')
