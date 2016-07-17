describe 'Locflow.Encoding.QueryString specs', ->
  describe '#splitKeyValue', ->
    encode = null
    beforeEach -> encode = new Locflow.Encoding.QueryString ''

    it 'returns an object with `key` and `value`', ->
      pair = encode.splitKeyValue 'name=luiz'
      expect(pair).to.deep.eql(key: 'name', value: 'luiz')

    it 'returns undefined if there was a syntax error', ->
      pair = encode.splitKeyValue 'name:luiz'
      expect(pair).to.be.undefined

    it 'preserves key and value spaces', ->
      pair = encode.splitKeyValue ' name = luiz '
      expect(pair).to.deep.eql(key: ' name ', value: ' luiz ')

    it 'decodes special URI characters', ->
      pair = encode.splitKeyValue 'age=%2610%26'
      expect(pair).to.deep.eql(key: 'age', value: '&10&')

      pair = encode.splitKeyValue 'name=%20Luiz%20'
      expect(pair).to.deep.eql(key: 'name', value: ' Luiz ')

  describe '#generateFlatMap', ->
    it 'generates an object with keys from the querystring', ->
      encode = new Locflow.Encoding.QueryString 'name=luiz&age=10'
      flatMap = encode.generateFlatMap()
      expect(flatMap).to.deep.eql
        'name': 'luiz'
        'age': '10'

    it 'uses the key exactly as it appears in the querystring (no trimming)', ->
      encode = new Locflow.Encoding.QueryString ' name = luiz&age  =10'
      flatMap = encode.generateFlatMap()
      expect(flatMap).to.deep.eql
        ' name ': ' luiz'
        'age  ': '10'

    it 'stores keys as flat values (ignoring brackets)', ->
      encode = new Locflow.Encoding.QueryString 'author[name][first]=luiz'
      flatMap = encode.generateFlatMap()
      expect(flatMap).to.deep.eql('author[name][first]': 'luiz')

    it 'stores multiple values for the same key as an array', ->
      encode = new Locflow.Encoding.QueryString 'color=red&color=blue'
      flatMap = encode.generateFlatMap()
      expect(flatMap).to.deep.eql('color': ['red', 'blue'])

    it 'stores multiple values if the key has empty brackets at the end', ->
      encode = new Locflow.Encoding.QueryString 'color[]=red&color[]=blue'
      flatMap = encode.generateFlatMap()
      expect(flatMap).to.deep.eql('color[]': ['red', 'blue'])

    it 'stores multiple values for nested keys', ->
      encode = new Locflow.Encoding.QueryString 'a[b]=10&a[b]=20&a[b]=30'
      flatMap = encode.generateFlatMap()
      expect(flatMap).to.deep.eql('a[b]': ['10', '20', '30'])

    it 'ignores bad formatted key-value pairs', ->
      encode = new Locflow.Encoding.QueryString 'name=foo&age:10'
      flatMap = encode.generateFlatMap()
      expect(flatMap).to.deep.eql('name': 'foo')

    it 'stores single value as array if key ends with []', ->
      encode = new Locflow.Encoding.QueryString 'color[]=red'
      flatMap = encode.generateFlatMap()
      expect(flatMap).to.deep.eql('color[]': ['red'])

  describe '#findNestedPath', ->
    encode = null
    beforeEach -> encode = new Locflow.Encoding.QueryString ''

    it 'returns the same key if there is no nesting', ->
      expect(encode.findNestedPath('name')).to.deep.eql(['name'])
      expect(encode.findNestedPath('age')).to.deep.eql(['age'])
      expect(encode.findNestedPath('my-long-key')).to.deep.eql(['my-long-key'])

    it 'returns an array with each path', ->
      expect(encode.findNestedPath('author[name]')).to.deep.eql(
        ['author', 'name']
      )

    it 'returns an array with multiple (deep nesting) paths', ->
      expect(encode.findNestedPath('post[author][name][first]')).to.deep.eql(
        ['post', 'author', 'name', 'first']
      )

    it 'returns the given key if it has invalid path', ->
      expect(encode.findNestedPath('author[na]me]')).to.deep.eql(
        ['author[na]me]']
      )

    it 'removes empty brackets at the end of the key', ->
      expect(encode.findNestedPath('colors[]')).to.deep.eql(['colors'])
      expect(encode.findNestedPath('author[colors][]')).to.deep.eql(['author', 'colors'])

  describe '#assignNestedValue', ->
    encode = null
    beforeEach -> encode = new Locflow.Encoding.QueryString ''

    it 'stores the given key -> value in the map', ->
      nestedMap = encode.assignNestedValue {}, ['name'], 'Luiz'
      expect(nestedMap).to.deep.eql('name': 'Luiz')

    it 'stores the given key path as nested map', ->
      nestedMap = encode.assignNestedValue {}, ['author', 'name'], 'Luiz'
      expect(nestedMap).to.deep.eql('author': {'name': 'Luiz'})

    it 'stores multiple values in the map preserving values', ->
      nestedMap = encode.assignNestedValue {'author': {'age': '10'}}, ['author', 'name'], 'Luiz'
      expect(nestedMap).to.deep.eql
        'author':
          'age': '10'
          'name': 'Luiz'

  describe '#toJson', ->
    it 'uses the given values as strings', ->
      encode = new Locflow.Encoding.QueryString 'name=luiz&age=20&switch=on'
      expect(encode.toJson()).to.deep.eql
        'name': 'luiz'
        'age': '20'
        'switch': 'on'

    it 'encodes properties in brackets as nested objects', ->
      encode = new Locflow.Encoding.QueryString 'card[name]=foo&card[age]=10'
      expect(encode.toJson()).to.deep.eql
        'card':
          'name': 'foo'
          'age': '10'

    it 'encodes multiple values for the same key as an array', ->
      encode = new Locflow.Encoding.QueryString 'color=red&color=blue'
      expect(encode.toJson()).to.deep.eql
        'color': ['red', 'blue']

    it 'ignores bad formatted key-value pairs', ->
      encode = new Locflow.Encoding.QueryString 'name=foo&age10&color=red'
      expect(encode.toJson()).to.deep.eql
        'name': 'foo'
        'color': 'red'

    it 'encodes deep nested properties', ->
      encode = new Locflow.Encoding.QueryString 'post[author][name][first]=luiz'
      expect(encode.toJson()).to.deep.eql({post: {author: {name: {first: 'luiz'}}}})

    it 'encodes nested arrays', ->
      encode = new Locflow.Encoding.QueryString 'a[b]=10&a[b]=20&a[b]=30'
      expect(encode.toJson()).to.deep.eql(a: {b: ['10', '20', '30']})

    it 'parses a single element with brackets in key as array', ->
      encode = new Locflow.Encoding.QueryString 'colors[]=red'
      expect(encode.toJson()).to.deep.eql('colors': ['red'])

    it 'decodes special URI characters', ->
      encode = new Locflow.Encoding.QueryString 'name=%20Luiz%20'
      expect(encode.toJson()).to.deep.eql(name: ' Luiz ')

  describe '#isValid', ->
    it 'returns true for key=value pairs', ->
      encode = new Locflow.Encoding.QueryString 'name=luiz'
      expect(encode.isValid()).to.be.true
      encode = new Locflow.Encoding.QueryString 'name=luiz&age=10'
      expect(encode.isValid()).to.be.true

    it 'returns false if there is no key value pairs', ->
      encode = new Locflow.Encoding.QueryString 'latest'
      expect(encode.isValid()).to.be.false
      encode = new Locflow.Encoding.QueryString 'foo:bar'
      expect(encode.isValid()).to.be.false

    it 'returns true if one of the key=value pair isnt valid', ->
      encode = new Locflow.Encoding.QueryString 'name=luiz&age:10'
      expect(encode.isValid()).to.be.true
