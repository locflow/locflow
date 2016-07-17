class Locflow.Request
  constructor: (@method, @url, @opts = {}) ->
    @timeoutMillis = @opts.timeoutMillis or 4000
    @xhr = null
    @aborted = false

  @GET: (url, opts) ->
    req = new Locflow.Request('GET', url, opts)
    req.send()
    req

  @POST: (url, data, opts) ->
    req = new Locflow.Request 'POST', url, opts
    req.send(data)
    req

  @PUT: (url, data, opts) ->
    req = new Locflow.Request 'PUT', url, opts
    req.send(data)
    req

  @DELETE: (url, data, opts) ->
    req = new Locflow.Request 'DELETE', url, opts
    req.send(data)
    req

  success: (callback) ->
    @opts.success = callback

  error: (callback) ->
    @opts.error = callback

  timeout: (callback) ->
    @opts.timeout = callback

  abort: ->
    @aborted = true
    @xhr?.abort()

  parseResponse: ->
    return @parsedResponse if @parsedResponse
    contentType = @xhr?.getResponseHeader('Content-Type')
    if contentType and contentType.indexOf('application/json') is 0
      @parsedResponse = JSON.parse(@xhr.responseText)
    else if contentType and contentType.indexOf('text/javascript') is 0
      @parsedResponse = @xhr.responseText
      try eval(@xhr.responseText)
      catch e then Locflow.handleInvalidJavascriptResponse?(@xhr.responseText)
    else
      @parsedResponse = @xhr.responseText
    @parsedResponse

  setAcceptHeader: ->
    format = new Locflow.Url(@url).format()
    if format is 'html'
      @xhr.setRequestHeader 'Accept', 'text/html, application/xhtml+xml, application/xml'
    else if format is 'json'
      @xhr.setRequestHeader 'Accept', 'application/json; charset=utf-8'
    else if format is 'js'
      @xhr.setRequestHeader 'Accept', 'text/javascript; charset=utf-8'

  setDefaultHeaders: ->
    @xhr.setRequestHeader 'X-Locflow', 'true'
    @xhr.setRequestHeader 'Content-Type', 'application/x-www-form-urlencoded'
    if Locflow.csrf?.getFromMeta()
      @xhr.setRequestHeader 'X-CSRF-Token', Locflow.csrf.getFromMeta()
    unless @opts.headers?['Accept']
      @setAcceptHeader()

  trigger: (action) ->
    @parseResponse()
    if @xhr and @xhr.readyState > 0
      @opts[action]?(@parseResponse(), @xhr.status, @xhr)

  send: (body = {}) ->
    @xhr = new XMLHttpRequest()
    @xhr.open(@method, @url, true)
    @setDefaultHeaders()
    for key, value of @opts.headers
      @xhr.setRequestHeader(key, value)
    @xhr.withCredentials = @opts.withCredentials
    @xhrTimeout = setTimeout(=>
      return if @aborted
      @trigger('timeout')
    , @timeoutMillis)
    @xhr.onerror = => @trigger('error')
    @xhr.onreadystatechange = =>
      return if @aborted
      if @xhr.readyState is 4
        clearTimeout(@xhrTimeout)
        if @xhr.status is 200
          @trigger('success')
        else
          @trigger('error')
    sendData = @formatBody(body)
    @xhr.send(sendData)

  formatBody: (body) ->
    return '' if @method is 'GET'
    if body and Locflow.csrf
      Locflow.csrf.appendToken(body)
    encoded = new Locflow.Encoding.Json(body).toQueryString()
    encoded
