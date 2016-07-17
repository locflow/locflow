class Locflow.Handler
  constructor: ->
    @handlers = []

  match: (path, callback) ->
    url = new Locflow.Url(path)
    @handlers.push
      url: url
      callback: callback

  sameMatchRule: (handler1, handler2) ->
    handler1.url.path is handler2.url.path and handler1.url.hash is handler2.url.hash

  find: (path) ->
    url = new Locflow.Url(path)
    firstMatch = null
    @handlers.filter (handler) =>
      return @sameMatchRule(firstMatch, handler) if firstMatch
      if handler.url.match(url)
        firstMatch = handler
        return true

  call: (path) ->
    for handler in @find(path)
      handler.callback(handler.url.match(new Locflow.Url(path)))
