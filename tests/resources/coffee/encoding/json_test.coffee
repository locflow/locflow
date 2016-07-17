describe 'Locflow.Encoding.Json', ->
  describe '#generateFlatArray', ->
    it 'inserts an entry for each key in the JSON', ->
      encode = new Locflow.Encoding.Json { name: 'luiz', age: 10 }
      expect(encode.generateFlatArray()).to.deep.eql([
        {key: ['name'], value: 'luiz'},
        {key: ['age'], value: 10}
      ])

    it 'keeps array values as array', ->
      encode = new Locflow.Encoding.Json { colors: ['red', 'blue'] }
      expect(encode.generateFlatArray()).to.deep.eql([
        { key: ['colors'], value: ['red', 'blue'] }
      ])

    it 'parses nested objects keys', ->
      encode = new Locflow.Encoding.Json { author: { name: 'Luiz' } }
      expect(encode.generateFlatArray()).to.deep.eql([
        { key: ['author', 'name'], value: 'Luiz' }
      ])

    it 'parses multiple nested object keys', ->
      encode = new Locflow.Encoding.Json {
        author: { name: 'Luiz' }, post: { title: 'Title' }
      }
      expect(encode.generateFlatArray()).to.deep.eql([
        { key: ['author', 'name'], value: 'Luiz' },
        { key: ['post', 'title'], value: 'Title' }
      ])

    it 'parses deep nested object keys', ->
      encode = new Locflow.Encoding.Json {
        post: { author: { name: { first: 'Luiz' } } }
      }
      expect(encode.generateFlatArray()).to.deep.eql([
        { key: ['post', 'author', 'name', 'first'], value: 'Luiz' }
      ])

  describe '#encodeKeyValuePair', ->
    encode = null
    beforeEach -> encode = new Locflow.Encoding.Json {}

    it 'uses the key if there is only one step', ->
      query = encode.encodeKeyValuePair key: ['name'], value: 'luiz'
      expect(query).to.deep.eql ['name=luiz']

    it 'wraps other keys in brackets', ->
      query = encode.encodeKeyValuePair key: ['author', 'name'], value: 'luiz'
      expect(query).to.deep.eql ['author[name]=luiz']

      query = encode.encodeKeyValuePair key: ['post', 'author', 'name'], value: 'luiz'
      expect(query).to.deep.eql ['post[author][name]=luiz']

    it 'inserts empty brackets if value is array for multiple keys', ->
      query = encode.encodeKeyValuePair key: ['colors'], value: ['red']
      expect(query).to.deep.eql ['colors[]=red']

    it 'inserts empty brackets if value is array for single key', ->
      query = encode.encodeKeyValuePair key: ['user', 'colors'], value: ['blue']
      expect(query).to.deep.eql ['user[colors][]=blue']

    it 'inserts multiple entries for each value in the array', ->
      query = encode.encodeKeyValuePair key: ['colors'], value: ['red', 'blue']
      expect(query).to.deep.eql(['colors[]=red', 'colors[]=blue'])

    it 'inserts multiple entries for nested keys', ->
      query = encode.encodeKeyValuePair key: ['user', 'colors'], value: ['red', 'blue']
      expect(query).to.deep.eql(['user[colors][]=red', 'user[colors][]=blue'])

  describe '#toQueryString', ->
    it 'encodes an empty object to an empty string', ->
      encode = new Locflow.Encoding.Json {}
      expect(encode.toQueryString()).to.eq ''

    it 'encodes a single key-value pair', ->
      encode = new Locflow.Encoding.Json { name: 'luiz' }
      expect(encode.toQueryString()).to.eql 'name=luiz'

    it 'encodes multiple key-value pairs separated by &', ->
      encode = new Locflow.Encoding.Json { name: 'luiz', age: 10 }
      expect(encode.toQueryString()).to.eql 'name=luiz&age=10'

    it 'encodes values with URI safe characters', ->
      encode = new Locflow.Encoding.Json { name: ' Luiz ' }
      expect(encode.toQueryString()).to.eql 'name=%20Luiz%20'

    it 'encodes nested objects', ->
      encode = new Locflow.Encoding.Json { user: { name: { first: 'Luiz' } } }
      expect(encode.toQueryString()).to.eql 'user[name][first]=Luiz'
