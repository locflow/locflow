describe 'Locflow utils', ->
  describe '.cloneArray', ->
    it 'returns a different array from the given one', ->
      source = [10, 20]
      cloned = Locflow.cloneArray source
      expect(source).not.to.eq(cloned)
      expect(source).to.deep.eql(cloned)

    it 'keeps the same referenced values', ->
      obj = {}
      source = [obj]
      cloned = Locflow.cloneArray source
      expect(source).to.not.eq(cloned)
      expect(cloned[0]).to.eq(source[0])

  describe '.mergeObjects', ->
    it 'returns an object with properties from both arguments', ->
      obj = Locflow.mergeObjects {a: 10}, {b: 20}
      expect(obj).to.eql(a: 10, b: 20)

    it 'overwrites the value from the second object with value from the first', ->
      obj = Locflow.mergeObjects {a: 10}, {a: 20}
      expect(obj).to.eql(a: 10)

    it 'doesnt modify the given objects', ->
      first = a: 10
      second = b: 20
      merge = Locflow.mergeObjects first, second
      expect(first).to.eql a: 10
      expect(second).to.eql b: 20
      expect(merge).to.eql a: 10, b: 20

    it 'shallow copies each value', ->
      first = {a: { b: 20 }}
      merge = Locflow.mergeObjects first, {}
      expect(merge).to.eql {a: { b: 20 }}
      expect(merge.a).to.eq(first.a)

    it 'ignores if the first argument isnt an object', ->
      merge = Locflow.mergeObjects null, {a: 10}
      expect(merge).to.eql a: 10

    it 'ignores if the second argument isnt an object', ->
      merge = Locflow.mergeObjects {a: 10}, null
      expect(merge).to.eql a: 10
