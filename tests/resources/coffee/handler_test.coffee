describe 'Locflow.Handler specs', ->
  handler = null
  beforeEach -> handler = new Locflow.Handler()

  describe '#match', ->
    it 'stores a handler register', ->
      handler.match('/home', ->)
      expect(handler.find('/home')).to.have.length(1)
      handler.match('/about', ->)
      expect(handler.find('/about')).to.have.length(1)

    it 'stores multiple handlers for the same route', ->
      handler.match('/home', ->)
      handler.match('/home', ->)
      expect(handler.find('/home')).to.have.length(2)

    it 'stores multiple handlers for the same route with hash', ->
      handler.match('/home#latest', ->)
      handler.match('/home#newest', ->)
      expect(handler.find('/home')).to.have.length(0)
      expect(handler.find('/home#latest')).to.have.length(1)
      expect(handler.find('/home#newest')).to.have.length(1)

  describe '#call', ->
    it 'calls the first match for the given url', ->
      callback1 = sinon.spy()
      callback2 = sinon.spy()
      handler.match('/posts/:id', callback1)
      handler.match('/posts/10', callback2)

      handler.call('/posts/10')
      expect(callback1.called).to.be.true
      expect(callback2.called).to.be.false

    it 'calls multiple handlers for the first matching url', ->
      callback1 = sinon.spy()
      callback2 = sinon.spy()
      handler.match('/posts/:id', callback1)
      handler.match('/posts/:id', callback2)

      handler.call('/posts/10')
      expect(callback1.called).to.be.true
      expect(callback2.called).to.be.true

    it 'sends the matched arguments as the handler argument', (done) ->
      callback = (arg) ->
        expect(arg.user_id).to.eq '10'
        expect(arg.id).to.eq '15'
        done()
      handler.match('/users/:user_id#comment=:id', callback)
      handler.call('/users/10#comment=15')
