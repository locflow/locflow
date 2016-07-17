class Locflow.Url
  constructor: (url) ->
    if url instanceof Locflow.Url
      @copyFromUrl(url)
    else if url and url.host and url.pathname
      @copyFromLocation(url)
    else if 'string' is typeof url
      @initializeFromString(url)

  copyFromUrl: (url) ->
    @protocol = url.protocol
    @domain = url.domain
    @query = url.query
    @path = url.path
    @port = url.port
    @hash = url.hash

  copyFromLocation: (location) ->
    @protocol = location.protocol.replace ':', ''
    @domain = location.host
    @query = location.search
    @path = location.pathname
    @port = location.port
    @hash = location.hash
    if @domain.indexOf(':') isnt -1
      @domain = @domain.split(':')[0]

  initializeFromString: (url) ->
    regex = /(file|http[s]?:\/\/)?([^\/?#]*)?([^?#]*)([^#]*)([\s\S]*)/i
    matches = url.toLowerCase().match(regex)
    if matches
      @protocol = (matches[1] or '').replace('://', '')
      @domain = matches[2] or ''
      @path = matches[3]
      @query = matches[4]
      @hash = matches[5]
      @port = ''
      if @domain.indexOf(':') isnt -1
        parts = @domain.split ':'
        @domain = parts[0]
        @port = parts[1]

  toString: ->
    urlStr = ''
    urlStr += if @protocol then @protocol + '://' else document.location.protocol + '//'
    urlStr += if @domain then @domain else document.location.host
    urlStr += if @port then ':' + @port else ''
    urlStr + (@path or '/') + @query + @hash

  queryObject: ->
    new Locflow.Encoding.QueryString(@query).toJson()

  setQueryObject: (obj) ->
    @query = '?' + new Locflow.Encoding.Json(obj).toQueryString()

  withoutHash: ->
    hashless = new Locflow.Url(this)
    hashless.hash = ''
    hashless

  format: ->
    if @path.indexOf('.json') is @path.length - '.json'.length
      'json'
    else if @path.indexOf('.js') is @path.length - '.js'.length
      'js'
    else
      'html'

  match: (other) ->
    pathParams = @matchPath other
    hashParams = @matchHash other
    return false unless pathParams and hashParams
    Locflow.mergeObjects pathParams, hashParams

  matchPath: (other) ->
    other = new Locflow.Url(other) unless other instanceof Locflow.Url
    return {} if @path is other.path
    paths = @path.replace(/\/$/, '').split '/'
    otherPaths = other.path.replace(/\/$/, '').split '/'
    return false if paths.length isnt otherPaths.length
    namedParams = {}
    for path, index in paths
      otherPath = otherPaths[index]
      if /^\:/.test path
        path = path.replace /^\:/, ''
        if namedParams[path]
          throw new Error "url [#{@toString()}] has multiple named parameters [:#{path}]"
        namedParams[path] = otherPath
      else if path isnt otherPath
        return false
    namedParams

  matchHash: (url) ->
    url = new Locflow.Url(url) unless url instanceof Locflow.Url
    return {} if @hash is url.hash
    hashEncoding = new Locflow.Encoding.QueryString(@hash.replace('#', ''))
    targetHashEncoding = new Locflow.Encoding.QueryString(url.hash.replace('#', ''))
    return false unless hashEncoding.isValid() and targetHashEncoding.isValid()
    hashQuery = hashEncoding.toJson()
    targetHashQuery = targetHashEncoding.toJson()
    namedParams = {}
    for key, attr of hashQuery
      if attr.indexOf(':') is 0
        return false unless targetHashQuery[key]
        if namedParams[attr.replace(':', '')] isnt undefined
          throw new Error "hash [#{@hash}] has multiple parameters [#{attr}]"
        namedParams[attr.replace(':', '')] = targetHashQuery[key]
      else
        return false if attr isnt targetHashQuery[key]
    namedParams
