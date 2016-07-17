describe 'Locflow.Navigation specs', ->
  navigation = null
  beforeEach ->
    navigation = new Locflow.Navigation

  describe '#onVisit', ->
    it 'sends a request in the given visit', ->
      visit = new Locflow.Visit '/home'
      navigation.onVisit(visit)
      expect(visit.request).to.be.ok

    it 'doesnt send a request if visit action is restore', ->
      visit = new Locflow.Visit '/home', action: 'restore'
      navigation.onVisit(visit)
      expect(visit.request).not.to.be.ok

    it 'calls sendRequest if action is restore but there is no cached snapshot'


  describe '#onLeave', ->
    it 'stores the current body reference in the route cache'

  describe '#restore', ->
