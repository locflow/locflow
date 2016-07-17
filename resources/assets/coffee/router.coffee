routes = []

class Locflow.Router
  constructor: ->
    @routes = []
    @defaultNavigation = new Locflow.Navigation()
    @defaultNavigation.cache = Locflow.navigationCache

  removeAll: ->
    @routes = []

  register: (path, callbacks) ->
    route =
      cache: new Locflow.Cache()
      url: new Locflow.Url(path)
      restore: callbacks.restore
      onVisit: callbacks.onVisit
      onLeave: callbacks.onLeave
    @routes.push route
    route

  findMatch: (path) ->
    for route in @routes
      return route if route.url.match(new Locflow.Url(path))
    @defaultNavigation

  invokeCustomRoute: (visit) ->
    route = @findMatch visit.url
    if route instanceof Locflow.Navigation
      @currentRoute = route
      @latestVisit = visit
    else
      @callRouteVisitActions visit, route

  invokeVisit: (visit) ->
    route = @findMatch visit.url
    @callRouteVisitActions visit, route

  callRouteVisitActions: (visit, route) ->
    @currentRoute?.onLeave(@latestVisit, @currentRoute.cache)
    @currentRoute = route
    @latestVisit = visit
    if visit.action isnt 'restore'
      route?.onVisit(visit, route.cache)

  restore: (visit) ->
    route = @findMatch visit.url
    route?.restore?(visit, route.cache)
    if visit.action is 'restore'
      setTimeout(-> visit.finish())
