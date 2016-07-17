describe 'Locflow.Csrf specs', ->
  csrf = meta = null
  beforeEach -> csrf = new Locflow.Csrf('authenticity_token')

  describe '#getFromMeta', ->
    it 'returns null if no meta is present in the page', ->
      expect(csrf.getFromMeta()).to.be.undefined
  
    it 'returns the value from the meta tag with the given name', ->
      TestSupport.createAuthenticityToken()
      expect(csrf.getFromMeta()).to.eq('123456')
      TestSupport.removeAuthenticityToken()

  describe '#appendToken', ->
    it 'appends a key->value with the given token name', ->
      TestSupport.createAuthenticityToken()
      obj = {}
      csrf.appendToken(obj)
      expect(obj).to.deep.eql({authenticity_token: '123456'})
      TestSupport.removeAuthenticityToken()

    it 'doesnt modify the object if there is no meta tag on the page', ->
      obj = {}
      csrf.appendToken(obj)
      expect(obj).to.deep.eql({})
