class Locflow.Navigation
  onVisit: (visit, cache) ->
    if visit.action isnt 'restore'
      visit.sendRequest()

  onLeave: (visit, cache) ->
    Locflow.snapshot.stage(visit.url.toString(), document.title)

  restore: (visit, cache) ->
    if Locflow.snapshot.cache.has(visit.url.toString())
      Locflow.snapshot.render(visit.url.toString())
    else
      visit.sendRequest()
