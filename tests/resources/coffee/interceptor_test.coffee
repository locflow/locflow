describe 'Locflow.Interceptor specs', ->
  interceptor = null
  beforeEach ->
    interceptor = new Locflow.Interceptor
    TestSupport.removeAllElements()

  describe '#shouldIgnore', ->
    it 'ignores if element has data-locflow="false"', ->
      div = TestSupport.insertDiv()
      div.setAttribute 'data-locflow', 'false'
      expect(interceptor.shouldIgnore(div)).to.be.true

    it 'ignores if one of the parents has data-locflow="false"', ->
      parent = TestSupport.insertDiv()
      child = TestSupport.createDiv()
      parent.appendChild child
      parent.setAttribute 'data-locflow', 'false'
      expect(interceptor.shouldIgnore(child)).to.be.true

    it 'accepts if element has no data-locflow attribute', ->
      div = TestSupport.insertDiv()
      expect(interceptor.shouldIgnore(div)).to.be.false

    it 'accepts if element has data-locflow="true"', ->
      div = TestSupport.insertDiv()
      div.setAttribute 'data-locflow', 'true'
      expect(interceptor.shouldIgnore(div)).to.be.false

    it 'accepts if element has data-locflow="true" and parent data-locflow="false"', ->
      parent = TestSupport.insertDiv()
      child = TestSupport.createDiv()
      parent.appendChild child
      parent.setAttribute 'data-locflow', 'false'
      child.setAttribute 'data-locflow', 'true'

      expect(interceptor.shouldIgnore(child)).to.be.false

    it 'accepts if parent has data-locflow="true" and grandparent data-locflow="false"', ->
      grandparent = TestSupport.insertDiv()
      parent = TestSupport.createDiv()
      child = TestSupport.createDiv()
      grandparent.setAttribute 'data-locflow', 'false'
      parent.setAttribute 'data-locflow', 'true'
      parent.appendChild(child)
      grandparent.appendChild(parent)

      expect(interceptor.shouldIgnore(child)).to.be.false

  describe '#onClick', ->
    it 'ignores elements other than anchors', ->
      div = TestSupport.insertDiv()
      child = TestSupport.createDiv()
      div.appendChild(child)
      interceptor.intercept(div)
      child.click()
      expect(interceptor.visit).to.be.undefined
      expect(interceptor.shouldIgnore(child)).to.be.false

    it 'creates a visit and calls the `propose` method', ->
      div = TestSupport.insertDiv()
      child = TestSupport.createAnchor()
      child.href = '/home'
      div.appendChild(child)
      interceptor.intercept(div)
      child.click()
      expect(interceptor.visit).to.be.ok
      expect(interceptor.visit.stateHistory).to.include('proposed')

    it 'ignores if anchor doesnt have an href attribute', ->
      div = TestSupport.insertDiv()
      child = TestSupport.createAnchor()
      div.appendChild(child)
      interceptor.intercept(div)
      child.click()
      expect(interceptor.visit).not.to.be.ok
      expect(interceptor.shouldIgnore(child)).to.be.false

    it 'ignores the element using the #shouldIgnore rule', ->
      div = TestSupport.insertDiv()
      child = TestSupport.createAnchor()
      child.setAttribute 'data-locflow', 'false'
      div.appendChild(child)
      interceptor.intercept(div)
      child.click()
      expect(interceptor.visit).not.to.be.ok

    it 'detects click in elements inside an anchor element', ->
      div = TestSupport.insertDiv()
      anchor = TestSupport.createAnchor()
      anchor.href = '/home'
      text = document.createElement 'span'
      div.appendChild(anchor)
      anchor.appendChild(text)
      interceptor.intercept(div)
      text.click()
      expect(interceptor.visit).to.be.ok


