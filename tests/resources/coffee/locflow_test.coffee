describe 'Locflow specs', ->
  it 'is supported in the testing context', ->
    expect(Locflow.supported).to.be.true

  it 'has a version', ->
    expect(Locflow.version).to.be.ok

  describe '.initialize', ->
    it 'assigns the default browser `adapter`', ->
      Locflow.initialize false
      expect(Locflow.adapter).to.be.ok
