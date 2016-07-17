class Locflow.Encoding.Json
  constructor: (@json) ->

  toQueryString: ->
    flatMap = @generateFlatArray()
    return '' if Object.keys(flatMap).length is 0
    flatMap.map((pair) => @encodeKeyValuePair(pair))
    .reduce((arr, val) -> arr.concat(val))
    .reduce((query, pair) ->
      query += "#{pair}&"
    , '')
    .replace(/\&$/, '')

  generateFlatArray: (target = [], path = [], json = @json) ->
    for key, value of json
      keyPath = Locflow.cloneArray path
      keyPath.push key
      if typeof value is 'object' and not Array.isArray(value)
        @generateFlatArray target, keyPath, value
      else
        target.push {key: keyPath, value: value}
    target

  encodeKeyValuePair: ({ key, value }) ->
    if Array.isArray(value) and value.length > 1
      value.map((singleValue) =>
        @encodeSingleKeyValuePair({ key, value: [singleValue] })
      ).reduce((arr, val) -> arr.concat(val))
    else
      @encodeSingleKeyValuePair({ key, value })

  encodeSingleKeyValuePair: ({ key, value }) ->
    if Array.isArray value
      suffix = '[]'
      value = value[0]
    else
      suffix = ''
    value = encodeURI value
    if key.length is 1
      ["#{key[0]}#{suffix}=#{value}"]
    else
      joinedKey = key[0]
      joinedKey += "[#{path}]" for path in key.slice(1)
      ["#{joinedKey}#{suffix}=#{value}"]
