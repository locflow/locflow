class Locflow.Dispatcher
  constructor: (@prefix = 'locflow:') ->

  dispatchOn: (targets, eventName, data) ->
    for target in targets
      @dispatch(eventName, {target: target, data: data})

  dispatch: (eventName, {target, data} = {}) ->
    ev = document.createEvent('Events')
    ev.initEvent(@normalizeName(eventName), true, true)
    ev.data = data ? {}
    (target ? document).dispatchEvent(ev)
    ev

  normalizeName: (name) ->
    "#{@prefix}#{name}"

Locflow.dispatcher = new Locflow.Dispatcher()
