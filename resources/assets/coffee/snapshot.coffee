class Locflow.Snapshot
  constructor: ->
    @cache = new Locflow.Cache()

  stage: (path, title) ->
    @staged =
      path: path
      title: title

  cacheStagedBody: (body, scrollX, scrollY) ->
    if @staged
      @cache.put(@staged.path, {
        body, scrollX, scrollY, title: @staged.title
      })
      @staged = null

  render: (url) ->
    record = @cache.get(url)
    if record
      Locflow.renderer.replaceAndCacheStagedBody(record.body)
      Locflow.renderer.scrollTo(record.scrollX, record.scrollY)
      Locflow.renderer.updateTitle(record.title)

Locflow.snapshot = new Locflow.Snapshot()
