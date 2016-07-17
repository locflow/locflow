describe 'Locflow.Url specs', ->
  describe 'parsing', ->
    it 'parses from a string with every component', ->
      url = new Locflow.Url 'https://outme.co:8000/my/path?name=foo#bar'
      expect(url.protocol).to.eq 'https'
      expect(url.domain).to.eq 'outme.co'
      expect(url.port).to.eq '8000'
      expect(url.path).to.eq '/my/path'
      expect(url.query).to.eq '?name=foo'
      expect(url.hash).to.eq '#bar'

    it 'parses from a string without port', ->
      url = new Locflow.Url 'https://outme.co/my/path?name=foo#bar'
      expect(url.protocol).to.eq 'https'
      expect(url.domain).to.eq 'outme.co'
      expect(url.port).to.eq ''
      expect(url.path).to.eq '/my/path'
      expect(url.query).to.eq '?name=foo'
      expect(url.hash).to.eq '#bar'

    it 'parses from a string without port and hash', ->
      url = new Locflow.Url 'https://outme.co/my/path?name=foo'
      expect(url.protocol).to.eq 'https'
      expect(url.domain).to.eq 'outme.co'
      expect(url.port).to.eq ''
      expect(url.path).to.eq '/my/path'
      expect(url.query).to.eq '?name=foo'
      expect(url.hash).to.eq ''

    it 'parses from a string without port, hash and query', ->
      url = new Locflow.Url 'https://outme.co/my/path'
      expect(url.protocol).to.eq 'https'
      expect(url.domain).to.eq 'outme.co'
      expect(url.port).to.eq ''
      expect(url.path).to.eq '/my/path'
      expect(url.query).to.eq ''
      expect(url.hash).to.eq ''

    it 'parses from a string without port, hash and path', ->
      url = new Locflow.Url 'https://outme.co?name=foo'
      expect(url.protocol).to.eq 'https'
      expect(url.domain).to.eq 'outme.co'
      expect(url.port).to.eq ''
      expect(url.path).to.eq ''
      expect(url.query).to.eq '?name=foo'
      expect(url.hash).to.eq ''

    it 'parses from a string without port, hash, query and path', ->
      url = new Locflow.Url 'https://outme.co'
      expect(url.protocol).to.eq 'https'
      expect(url.domain).to.eq 'outme.co'
      expect(url.port).to.eq ''
      expect(url.path).to.eq ''
      expect(url.query).to.eq ''
      expect(url.hash).to.eq ''

    it 'parses from a string without port, hash, query, path and protocol', ->
      url = new Locflow.Url 'outme.co'
      expect(url.protocol).to.eq ''
      expect(url.domain).to.eq 'outme.co'
      expect(url.port).to.eq ''
      expect(url.path).to.eq ''
      expect(url.query).to.eq ''
      expect(url.hash).to.eq ''

    it 'parses from a string without port, domain, hash, query and protocol', ->
      url = new Locflow.Url '/posts/10'
      expect(url.protocol).to.eq ''
      expect(url.domain).to.eq ''
      expect(url.port).to.eq ''
      expect(url.path).to.eq '/posts/10'
      expect(url.query).to.eq ''
      expect(url.hash).to.eq ''

    it 'parses from a string without port, domain, hash and protocol', ->
      url = new Locflow.Url '/posts/10?view=column'
      expect(url.protocol).to.eq ''
      expect(url.domain).to.eq ''
      expect(url.port).to.eq ''
      expect(url.path).to.eq '/posts/10'
      expect(url.query).to.eq '?view=column'
      expect(url.hash).to.eq ''

    it 'parse path and hash only', ->
      url = new Locflow.Url '/posts#latest'
      expect(url.protocol).to.eq ''
      expect(url.domain).to.eq ''
      expect(url.port).to.eq ''
      expect(url.path).to.eq '/posts'
      expect(url.query).to.eq ''
      expect(url.hash).to.eq '#latest'

    it 'parse only the hash part', ->
      url = new Locflow.Url '#latest'
      expect(url.protocol).to.eq ''
      expect(url.domain).to.eq ''
      expect(url.port).to.eq ''
      expect(url.path).to.eq ''
      expect(url.query).to.eq ''
      expect(url.hash).to.eq '#latest'

  describe 'initializing from other urls', ->
    it 'copies all properties', ->
      url = new Locflow.Url 'https://outme.co:3000/my/path?name=luiz#target'
      other = new Locflow.Url(url)
      expect(url).not.to.eq(other)
      expect(url.protocol).to.eq other.protocol
      expect(url.domain).to.eq other.domain
      expect(url.port).to.eq other.port
      expect(url.path).to.eq other.path
      expect(url.query).to.eq other.query
      expect(url.hash).to.eq other.hash

  describe '#queryObject', ->
    it 'returns an empty object if there is no query in the url', ->
      url = new Locflow.Url 'outme.co/home'
      expect(url.queryObject()).to.deep.eql {}

    it 'encodes the url using the Locflow.Encoding.QueryString class', ->
      url = new Locflow.Url 'outme.co/home?name=luiz'
      expect(url.queryObject()).to.deep.eql {name: 'luiz'}

  describe '#setQueryObject', ->
    it 'encodes the given object and assigns to query', ->
      url = new Locflow.Url 'outme.co/home'
      url.setQueryObject { name: 'luiz' }
      expect(url.query).to.eql '?name=luiz'

  describe '#withoutHash', ->
    it 'retunrs a new url without the hash value', ->
      url = new Locflow.Url 'outme.co/home#target'
      hashless = url.withoutHash()
      expect(url).not.to.eq(hashless)
      expect(url.hash).to.eq '#target'
      expect(hashless.hash).to.eq ''

  describe '#matchPath', ->
    testCases = [
      ['/posts',                       '/posts',               {}],
      ['/users/10',                    '/users/10',            {}],
      ['/users/:id',                   '/users/10',            {id: '10'}],
      ['/users/:id/edit',              '/users/10/edit',       {id: '10'}],
      ['/users/:id/edit',              '/users//edit',         {id: ''}],
      ['/users/:id/edit',              '/users/edit',          false],
      ['/users/:user_id/comments/:id', '/users/10/comments/5', {user_id: '10', id: '5'}],
      ['/posts',                       '/POSTS',               {}],
      ['/posts',                       '/postz',               false],
      ['/users/:id',                   '/users',               false],
      ['/posts/latest',                '/posts/latest/',       {}],
      ['/posts#latest',                '/posts#latest',        {}]
    ]

    it 'assets the test cases works', ->
      for testCase in testCases
        url1 = new Locflow.Url testCase[0]
        url2 = new Locflow.Url testCase[1]
        errorMessage = "#{url1.toString()}\n#{url2.toString()}\nshould match"
        expect(url1.matchPath(url2), errorMessage).to.eql(testCase[2])

    it 'throws an error if two placeholders have the same name', ->
      url1 = new Locflow.Url '/users/:id/comments/:id'
      url2 = new Locflow.Url '/users/10/comments/10'
      matchUrl = -> url1.matchPath(url2)
      expect(matchUrl).to.throw /has multiple named parameters \[:id\]/

  describe '#matchHash', ->
    testCases = [
      ['#latest',                     '#latest',            {}],
      ['#foo&bar',                    '#foo&bar',           {}],
      ['#foo=:id',                    '#foo=50',            {id: '50'}],
      ['#id=:id&comment=:comment_id', '#id=10&comment=20',  {id: '10', comment_id: '20'}],
      ['#foo&bar=:bar',               '#foo&bar=10',        {bar: '10'}],
      ['#foo&bar=:bar',               '#qux&bar=10',        {bar: '10'}], # yep, that's expected
      ['#foo=bar',                    '#foo=bar',           {}],
      ['#foo=bar',                    '#foo=qux',           false],
      ['#foo=:id',                    '#',                  false],
      ['#foo=:id',                    '#foo',               false],
      ['#foo=:id',                    '#qux=10',            false],
    ]

    it 'works on the given test cases', ->
      for testCase in testCases
        url1 = new Locflow.Url testCase[0]
        url2 = new Locflow.Url testCase[1]
        errorMessage = "#{url1.toString()}\n#{url2.toString()}\nshould match hash"
        expect(url1.matchHash(url2), errorMessage).to.eql(testCase[2])

    it 'throws an error if two placeholders have the same name', ->
      url1 = new Locflow.Url '#foo=:id&bar=:id'
      url2 = new Locflow.Url '#foo=10&bar=20'
      matchUrl = -> url1.matchHash(url2)
      expect(matchUrl).to.throw(/has multiple parameters \[:id\]/)

  describe '#match', ->
    testCases = [
      ['/posts#latest',                  '/posts#latest',        {}],
      ['/posts/:id#latest',              '/posts/10#latest',     {id: '10'}],
      ['/posts/:id#comment=:comment_id', '/posts/10#comment=20', {id: '10', comment_id: '20'}],
      ['/posts/:id#comment=:id',         '/posts/10#comment=20', {id: '10'}] # careful!
    ]

    it 'works on the given test cases', ->
      for testCase in testCases
        url1 = new Locflow.Url testCase[0]
        url2 = new Locflow.Url testCase[1]
        errorMessage = "#{url1.toString()}\n#{url2.toString()}\nshould match"
        expect(url1.match(url2), errorMessage).to.eql(testCase[2])

    it 'accepts a string as well as a url object', ->
      url = new Locflow.Url '/users/:id'
      expect(url.match('/users/10')).to.deep.eql(id: '10')

  describe '#format', ->
    it 'identifies json formats', ->
      url = new Locflow.Url '/users.json'
      expect(url.format()).to.eq 'json'

    it 'identifies js formats', ->
      url = new Locflow.Url '/users.js'
      expect(url.format()).to.eq 'js'

    it 'identifies html formats', ->
      url = new Locflow.Url '/users.html'
      expect(url.format()).to.eq 'html'

      url = new Locflow.Url '/users', ->
      expect(url.format()).to.eq 'html'
