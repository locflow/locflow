class Locflow.Encoding.QueryString
  constructor: (query) ->
    @query = query.replace('?', '')

  toJson: ->
    @generateNestedMap(@generateFlatMap())

  isValid: ->
    flatMap = @generateFlatMap()
    return Object.keys(flatMap).length > 0

  generateNestedMap: (flatMap) ->
    nested = {}
    for key in Object.keys(flatMap)
      nestedPath = @findNestedPath(key)
      @assignNestedValue(nested, nestedPath, flatMap[key])
    nested

  findNestedPath: (key) ->
    pathRegex = /^[^\[\]]+(\[[^\[\]]*\])*$/
    return [key] unless key.match pathRegex
    key.split('[')
      .map((path) -> path.replace(']', '').trim())
      .filter((step) -> step.trim() isnt '')

  assignNestedValue: (map, path, value) ->
    originalMap = map
    for step, index in path
      map[step] = {} unless map[step]
      if index is path.length - 1
        map[step] = value
      else
        map = map[step]
    originalMap

  generateFlatMap: ->
    queryParts = @query.split('&')
    pairs = {}
    for queryPart in queryParts
      @mergeKeyValuePair(pairs, @splitKeyValue(queryPart))
    pairs

  mergeKeyValuePair: (pairs, { key, value } = {}) ->
    return pairs unless key and value
    if pairs[key] and Array.isArray(pairs[key])
      pairs[key].push value
    else if pairs[key]
      pairs[key] = [pairs[key], value]
    else
      pairs[key] = if /\[\]$/.test(key) then [value] else value

  splitKeyValue: (queryPart) ->
    values = queryPart.split '='
    return if values.length != 2
    { key: values[0], value: decodeURIComponent(values[1]) }
