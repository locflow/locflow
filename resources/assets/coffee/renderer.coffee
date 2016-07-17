class Locflow.Renderer
  constructor: ->
    @cache = new Locflow.Cache()

  cloneBody: ->
    document.body.cloneNode(true)

  findPermanentElements: ->
    permanentElements = document.querySelectorAll(
      '*[data-locflow="permanent"]:not([data-shallow])'
    )
    for elm in permanentElements
      if !elm.id
        throw new Error('permanent element must have an id')
    permanentElements

  removePermanentElements: ->
    permanentElements = @findPermanentElements()
    for elm in permanentElements
      shallowClone = elm.cloneNode(false)
      shallowClone.setAttribute 'data-shallow', 'true'
      elm.parentNode.replaceChild(shallowClone, elm)
    permanentElements

  removeAndCachePermanentElements: ->
    permanents = @removePermanentElements()
    currentPermanents = @cache.get('elements') or []
    mergedPermanents = Array.prototype.slice.call(currentPermanents)
    for permanent in permanents
      found = false
      for currentPermanent in currentPermanents
        if permanent.id is currentPermanent.id
          found = true
          break
      if not found
        mergedPermanents.push permanent
    @cache.put('elements', mergedPermanents)
    mergedPermanents

  mergePermanentElements: (permanentElements) ->
    for elm in permanentElements
      shallowPlaceholder = document.getElementById(elm.id)
      if shallowPlaceholder
        shallowPlaceholder.parentNode.replaceChild(elm, shallowPlaceholder)

  mergeCachedPermanentElements: ->
    @mergePermanentElements(@cache.get('elements', []))

  scrollTo: (scrollX, scrollY) ->
    window.scrollTo(scrollX, scrollY)

  extractHeadTags: (html) ->
    head = html.getElementsByTagName('head')
    if head.length is 1
      head = head[0]
      head.getElementsByTagName 'meta'
    else
      []

  extractTitle: (html) ->
    titleTags = html.getElementsByTagName 'title'
    if titleTags.length is 1
      titleTags[0].innerHTML
    else
      document.title

  updateTitle: (title) ->
    document.title = title

  mergeHeadTags: (tags) ->
    for meta in tags
      continue unless meta and meta.name
      currentMeta = document.querySelector "meta[name=\"#{meta.name}\"]"
      if currentMeta
        currentMeta.content = meta.content
      else
        document.head.appendChild(meta)

  extractBody: (html) ->
    body = html.getElementsByTagName 'body'
    if body.length is 1
      body[0]
    else
      throw new Error("body tag not found in HTML")

  replaceAndCacheStagedBody: (body) ->
    scrollX = window.pageXOffset
    scrollY = window.pageYOffset
    @removeAndCachePermanentElements()
    stagedBody = document.body.parentNode.replaceChild(body, document.body)
    @mergeCachedPermanentElements()
    Locflow.snapshot.cacheStagedBody(stagedBody, scrollX, scrollY)

  render: (htmlString) ->
    el = document.createElement 'html'
    el.innerHTML = htmlString
    @updateTitle(@extractTitle(el))
    @mergeHeadTags(@extractHeadTags(el))
    @replaceAndCacheStagedBody(@extractBody(el))
