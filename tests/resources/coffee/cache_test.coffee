describe 'Locflow.Cache specs', ->
  cache = null
  beforeEach -> cache = new Locflow.Cache()

  describe '#set and #get', ->
    it 'stores the given value associated with key', ->
      cache.put('name', 'luiz')
      cache.put('number', 100)
      cache.put('colors', ['red', 'blue'])

      expect(cache.get('name')).to.eq('luiz')
      expect(cache.get('number')).to.eq(100)
      expect(cache.get('colors')).to.deep.eql(['red', 'blue'])

    it 'overwrites existing value', ->
      cache.put('name', 'luiz')
      expect(cache.get('name')).to.eq('luiz')
      cache.put('name', 'paulo')
      expect(cache.get('name')).to.eq('paulo')

    it 'stores NULL values (null !== undefined)', ->
      cache.put('my-null', null)
      expect(cache.get('my-null')).to.be.null
      expect(cache.get('my-undefined')).to.be.undefined

    it 'returns the given value if key wasnt found', ->
      expect(cache.get('my-value', 10)).to.eq(10)
      cache.put('my-value', null)
      expect(cache.get('my-value', 10)).to.be.null

  describe '#has', ->
    it 'returns true for existing keys (even with null value)', ->
      expect(cache.has('name')).to.be.false
      cache.put('name', 'luiz')
      expect(cache.has('name')).to.be.true
      cache.put('name', null)
      expect(cache.has('name')).to.be.true

  describe '#remove', ->
    it 'deletes the value associated with key', ->
      cache.put('name', 'luiz')
      expect(cache.remove('name')).to.eq('luiz')
      expect(cache.get('name')).to.be.undefined

    it 'ignores if the key doesnt exist', ->
      expect(cache.remove('my-undefined')).to.be.undefined

  describe '#removeAll', ->
    it 'deletes all entries in the cache', ->
      cache.put('name', 'luiz')
      cache.put('number', 100)
      cache.removeAll()
      expect(cache.get('name')).to.be.undefined
      expect(cache.get('number')).to.be.undefined

  describe '#keepLatest', ->
    it 'removes oldest items if limit is exceeded', ->
      cache.setSize(2)
      cache.put('name', 'Luiz')
      cache.put('color', 'red')
      expect(cache.get('name')).to.eq('Luiz')
      cache.put('email', 'luizpvasc@gmail.com')
      expect(cache.get('name')).to.be.undefined
      expect(cache.get('color')).to.eq('red')
      expect(cache.get('email')).to.eq('luizpvasc@gmail.com')
      cache.put('pet', 'cat')
      expect(cache.get('color')).to.be.undefined

    it 'removes oldest items when limit is updated', ->
      cache.put('name', 'Luiz')
      cache.put('color', 'red')
      cache.put('email', 'luizpvasc@gmail.com')
      cache.put('pet', 'cat')
      cache.setSize(2)
      expect(cache.get('name')).to.be.undefined
      expect(cache.get('color')).to.be.undefined
      expect(cache.get('email')).to.eq('luizpvasc@gmail.com')
      expect(cache.get('pet')).to.eq('cat')
