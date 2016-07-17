describe 'Locflow.Request specs', ->
  xhr = null
  requests = null
  beforeEach ->
    xhr = sinon.useFakeXMLHttpRequest()
    xhr.onCreate = (req) -> requests.push(req)
    requests = []

  describe '#send', ->
    it 'sends a request with the given method, url and headers', ->
      home = new Locflow.Request('GET', '/home')
      home.send()
      expect(requests).to.have.length(1)
      req = requests[0]
      expect(req.url).to.eq('/home')
      expect(req.method).to.eq('GET')
      expect(req.requestHeaders['X-Locflow']).to.eq 'true'
      expect(req.requestHeaders['Content-Type']).to.eq(
        'application/x-www-form-urlencoded'
      )
      expect(req.requestHeaders['Accept']).to.eq(
        'text/html, application/xhtml+xml, application/xml'
      )

    it 'calls `success` if the server responds with 200', ->
      home = new Locflow.Request('GET', '/home')
      home.success(sinon.spy())
      home.send()
      requests[0].respond(200, {}, 'hi')
      expect(home.opts.success.called)

    it 'calls `error` if the server responds with != 200', ->
      home = new Locflow.Request('GET', '/home')
      home.error(sinon.spy())
      home.send()
      requests[0].respond(500, {}, 'err')
      expect(home.opts.error.called).to.be.true

    it 'calls `timeout` if the server doesnt respond withing time limit', (done) ->
      req = new Locflow.Request('GET', '/home')
      req.timeout(sinon.spy())
      req.timeoutMillis = 2
      req.send()
      setTimeout(->
        expect(req.opts.timeout.called).to.be.true
        done()
      , 5)

    it 'triggers `success` after `timeout` if request wasnt aborted', (done) ->
      home = new Locflow.Request('GET', '/home')
      home.timeout(sinon.spy())
      home.success(sinon.spy())
      home.timeoutMillis = 2
      home.send()
      setTimeout(->
        expect(home.opts.timeout.called).to.be.true
        requests[0].respond(200, {}, 'ok')
        expect(home.opts.success.called).to.be.true
        done()
      , 3)

    it 'accepts custom headers', ->
      home = new Locflow.Request('GET', '/home',
        headers:
          'MY-CUSTOM-HEADER': 'foo'
          'OTHER-FOO': 'bar'
      )
      home.send()
      req = requests[0]
      expect(req.requestHeaders['MY-CUSTOM-HEADER']).to.eq 'foo'
      expect(req.requestHeaders['OTHER-FOO']).to.eq 'bar'

    it 'encodes given data using the QueryString encoding', ->
      home = new Locflow.Request('POST', '/home')
      home.send(hello: 'world', age: 10)
      req = requests[0]
      expect(req.requestBody).to.eq 'hello=world&age=10'

    it 'uses the authenticity_token from the meta tag if specified', ->
      Locflow.useAuthenticityTokenFromMeta('authenticity_token')
      TestSupport.createAuthenticityToken()
      home = new Locflow.Request('POST', '/home')
      home.send()
      req = requests[0]
      expect(req.requestBody).to.eq 'authenticity_token=123456'
      TestSupport.removeAuthenticityToken()

    it 'ignores authenticity_token if request method is GET', ->
      Locflow.useAuthenticityTokenFromMeta('authenticity_token')
      TestSupport.createAuthenticityToken()
      home = new Locflow.Request('GET', '/home')
      home.send()
      req = requests[0]
      expect(req.requestBody).to.be.null
      TestSupport.removeAuthenticityToken()

  describe '#parseResponse', ->
    it 'parses JSON if response type is JSON', ->
      req = new Locflow.Request('GET', '/home')
      req.send()
      requests[0].respond(200, {'Content-Type': 'application/json'}, '{"hello":"world"}')
      expect(req.parseResponse()).to.deep.eql({hello: "world"})

    it 'evalutes Javascript response', ->
      window.__callbackFormTest = sinon.spy()
      req = Locflow.Request.GET('/home')
      requests[0].respond(200, {'Content-type': 'text/javascript'}, "__callbackFormTest();")
      expect(window.__callbackFormTest.called).to.be.true

  describe '#abort', ->
    it 'updates the `abort` property to true', ->
      req = new Locflow.Request 'GET', '/home'
      req.send()
      req.abort()
      expect(req.aborted).to.be.true

    it 'doesnt trigger `timeout` if aborted', (done) ->
      req = new Locflow.Request 'GET', '/home'
      req.timeoutMillis = 2
      req.timeout(sinon.spy())
      setTimeout(->
        expect(req.opts.timeout.called).to.be.false
        done()
      , 4)

  describe '.GET', ->
    it 'sends a GET request', ->
      req = Locflow.Request.GET '/home'
      expect(req.method).to.eq 'GET'
      expect(req.url).to.eq '/home'
      expect(requests).to.have.length(1)

  describe '.POST', ->
    it 'sends a POST request', ->
      req = Locflow.Request.POST '/home', {hello: 'world'}
      expect(req.method).to.eq 'POST'
      expect(req.url).to.eq '/home'
      expect(requests).to.have.length(1)
      expect(requests[0].requestBody).to.eq('hello=world')

  describe '.PUT', ->
    it 'sends a PUT request', ->
      req = Locflow.Request.PUT '/home', {hello: 'world'}
      expect(req.method).to.eq 'PUT'
      expect(req.url).to.eq '/home'
      expect(requests).to.have.length(1)
      expect(requests[0].requestBody).to.eq('hello=world')

  describe '.DELETE', ->
    it 'sends a DELETE request', ->
      req = Locflow.Request.DELETE '/home', {hello: 'world'}
      expect(req.method).to.eq 'DELETE'
      expect(req.url).to.eq '/home'
      expect(requests).to.have.length(1)
      expect(requests[0].requestBody).to.eq('hello=world')
