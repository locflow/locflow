describe 'Locflow.Renderer specs', ->
  renderer = null
  beforeEach ->
    renderer = new Locflow.Renderer()
    TestSupport.removeAllElements()

  describe '#cloneBody', ->
    it 'clones the current body', ->
      clonedBody = renderer.cloneBody()
      expect(clonedBody).to.be.ok
      expect(clonedBody).not.to.eq(document.body)

  describe '#findPermanentElements', ->
    elm0 = elm1 = elm2 = elm3 = null
    beforeEach ->
      elm0 = TestSupport.insertDiv('elm0')
      elm1 = TestSupport.insertDiv('elm1')
      elm2 = TestSupport.insertDiv('elm2')
      elm3 = TestSupport.insertDiv('elm3')

    it 'finds elements that are permanent on the current body', ->
      elm0.setAttribute 'data-locflow', 'permanent'
      elm1.setAttribute 'data-locflow', 'permanent'
      permanent = renderer.findPermanentElements()
      expect(permanent).to.have.length(2)
      expect(permanent[0]).to.eq(elm0)
      expect(permanent[1]).to.eq(elm1)

    it 'doesnt identify shallow elements as permanent', ->
      elm0.setAttribute 'data-locflow', 'permanent'
      elm1.setAttribute 'data-locflow', 'permanent'
      elm1.setAttribute 'data-shallow', 'true'
      permanent = renderer.findPermanentElements()
      expect(permanent).to.have.length(1)
      expect(permanent[0]).to.eq(elm0)

    it 'throws an error if the permanent element doesnt have an id', ->
      elm0.setAttribute 'data-locflow', 'permanent'
      elm1.setAttribute 'data-locflow', 'permanent'
      elm1.id = ''
      findPermanents = -> renderer.findPermanentElements()
      expect(findPermanents).to.throw /permanent element must have an id/

  describe '#removePermanentElements', ->
    elm0 = elm1 = elm2 = elm3 = null
    beforeEach ->
      elm0 = TestSupport.insertDiv('elm0')
      elm0.setAttribute 'data-locflow', 'permanent'
      elm1 = TestSupport.insertDiv('elm1')
      elm1.setAttribute 'data-locflow', 'permanent'

    it 'returns a node list of the removed elements', ->
      permanentElements = renderer.removePermanentElements()
      expect(permanentElements).to.have.length(2)
      expect(permanentElements[0]).to.eq(elm0)
      expect(permanentElements[1]).to.eq(elm1)

    it 'leaves a shallow copy of the permanent elements when removing', ->
      renderer.removePermanentElements()
      shallowElements = document.querySelectorAll('*[data-shallow]')
      expect(shallowElements).to.have.length(2)
      expect(shallowElements[0].id).to.eq 'elm0'
      expect(shallowElements[1].id).to.eq 'elm1'
      expect(renderer.findPermanentElements()).to.have.length 0

  describe '#removeAndCachePermanentElements', ->
    it 'stores the found permanent elements in Locflow cache', ->
      Locflow.initialize false
      elm0 = TestSupport.insertDiv('elm0')
      elm0.setAttribute 'data-locflow', 'permanent'
      renderer.removeAndCachePermanentElements()
      expect(renderer.cache.get('elements')).to.have.length(1)

    it 'appends new permanent elements to the cache', ->
      Locflow.initialize false
      elm0 = TestSupport.insertDiv('elm0')
      elm0.setAttribute 'data-locflow', 'permanent'
      renderer.removeAndCachePermanentElements()
      elm1 = TestSupport.insertDiv('elm1')
      elm1.setAttribute 'data-locflow', 'permanent'
      renderer.removeAndCachePermanentElements()
      expect(renderer.cache.get('elements')).to.have.length(2)

    it 'updates existing permanent elements in the cache', ->
      Locflow.initialize false
      elm0 = TestSupport.insertDiv('elm0')
      elm0.setAttribute 'data-locflow', 'permanent'
      permanents = renderer.removeAndCachePermanentElements()
      expect(permanents).to.have.length(1)
      renderer.mergePermanentElements(permanents)
      elm0.innerHTML = 'ok'
      inPagePermanent = document.getElementById('elm0')
      expect(inPagePermanent.innerHTML).to.eq 'ok'
      expect(renderer.cache.get('elements')[0].innerHTML).to.eq 'ok'

  describe '#mergePermanentElements', ->
    elm0 = elm1 = null
    beforeEach ->
      elm0 = TestSupport.insertDiv 'elm0'
      elm0.setAttribute 'data-locflow', 'permanent'
      elm0.id = 'elm0'
      elm1 = TestSupport.insertDiv 'elm1'
      elm1.setAttribute 'data-locflow', 'permanent'
      elm1.id = 'elm1'

    it 'removes data-shallow when merging elements', ->
      permanentElements = renderer.removePermanentElements()
      expect(renderer.findPermanentElements()).to.have.length(0)
      renderer.mergePermanentElements(permanentElements)
      expect(renderer.findPermanentElements()).to.have.length(2)

    it 'ignores if there is no shallow placeholder in the page', ->
      permanentElements = renderer.removePermanentElements()
      shallowPlaceholder = document.getElementById('elm0')
      shallowPlaceholder.parentNode.removeChild(shallowPlaceholder)
      renderer.mergePermanentElements(permanentElements)
      expect(renderer.findPermanentElements()).to.have.length(1)

  describe '#render', ->
    it 'updates the page title', ->
      html = """
      <html>
        <head>
          <title>new title</title>
        </head>
      </html>
      """
      renderer.render(html)
      expect(document.title).to.eq 'new title'

    it 'updates existing meta tags', ->
      meta = document.createElement 'meta'
      meta.name = 'my-meta'
      meta.content = 'my-content'
      document.head.appendChild(meta)

      html = """
      <html>
        <head>
          <meta name="my-meta" content="my-updated-content" />
        </head>
      </html>
      """
      renderer.render(html)

      expect(meta.content).to.eq 'my-updated-content'

      meta.parentNode.removeChild(meta)

    it 'inserts new meta tags', ->
      html = """
      <html>
        <head>
          <meta name="my-new-meta" content="my-new-content" />
        </head>
      </html>
      """
      renderer.render(html)

      newMeta = document.querySelector 'meta[name="my-new-meta"]'
      expect(newMeta).to.be.ok
      expect(newMeta.content).to.eq 'my-new-content'

      newMeta.parentNode.removeChild(newMeta)

    it 'replaces the current body', ->
      currentBody = document.body
      html = """
      <html>
        <body>
          <h1 id="my-title">My new body</h1>
        </body>
      </html>
      """
      renderer.render(html)
      title = document.getElementById 'my-title'
      expect(title.innerHTML).to.eq 'My new body'

    it 'merges permanent elements', ->
      Locflow.initialize false
      elm0 = TestSupport.insertDiv 'elm0'
      elm0.setAttribute 'data-locflow', 'permanent'
      elm0.innerHTML = 'my-content'
      renderer.removeAndCachePermanentElements()
      html = """
      <html>
        <body>
          <div id="elm0" data-locflow="permanent"></div>
        </body>
      </html>
      """
      renderer.render(html)
      currentElm0 = document.getElementById 'elm0'
      expect(currentElm0.innerHTML).to.eq 'my-content'
