class Locflow.Csrf
  constructor: (@metaName, @attrName = @metaName) ->

  getFromMeta: ->
    meta = document.querySelector('meta[name="'+@metaName+'"]')
    return meta.content if meta

  appendToken: (obj) ->
    value = @getFromMeta()
    if value and obj
      obj[@attrName] = value
