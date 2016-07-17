describe 'Locflow.dispatch', ->
  dispatcher = null
  beforeEach -> dispatcher = new Locflow.Dispatcher()

  describe '#dispatch', ->
    it 'calls handlers attached with addEventListener', (done) ->
      document.addEventListener('locflow:test', ->
        done()
      )
      dispatcher.dispatch('test')

    it 'passes the given arguments in the event data property', (done) ->
      document.addEventListener('locflow:cat', (ev) ->
        expect(ev.data).to.deep.eql({hello: 'world'})
        done()
      )
      dispatcher.dispatch('cat', data: {hello: 'world'})

    it 'is cancelable', () ->
      callback = sinon.spy((ev) -> ev.preventDefault())
      document.addEventListener('locflow:dog', callback)
      ev = dispatcher.dispatch('dog')
      expect(callback.called).to.be.true
      expect(ev.defaultPrevented).to.be.true

