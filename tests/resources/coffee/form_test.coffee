describe 'Locflow.Form specs', ->
  xhr = requests = null

  beforeEach ->
    xhr = sinon.useFakeXMLHttpRequest()
    xhr.onCreate = (req) -> requests.push(req)
    requests = []

  afterEach ->
    for form in document.querySelectorAll('form.test')
      form.parentNode.removeChild(form)

  createForm = (html) ->
    form = document.createElement('form')
    form.className = 'test'
    form.innerHTML = html
    form.action = '/submit'
    form.method = 'POST'
    document.body.appendChild(form)
    new Locflow.Form(form)

  describe '#submit', ->
    it 'sends a POST request to the action url by default', ->
      form = createForm("""
      <input name="name" value="Luiz" />
      """)
      form.submit()
      expect(requests).to.have.length(1)
      expect(requests[0].url).to.eq(new Locflow.Url('/submit').toString())
      expect(requests[0].method).to.eq('post')

    it 'sends a PUT request if specified in data-method', ->
      form = createForm("""
      <input name="name" value="Luiz" />
      """)
      form.form.setAttribute('data-method', 'put')
      form.submit()
      expect(requests[0].method).to.eq('put')

    it 'serializes the form inputs', ->
      form = createForm("""
      <input name="name" value="Luiz " />
      <input name="age" value="23" />
      """)
      form.submit()
      expect(requests[0].requestBody).to.eq('name=Luiz%20&age=23') # url safe :)

    it 'triggers submit-success', ->
      callback = sinon.spy()
      form = createForm("")
      form.submit()
      form.form.addEventListener('locflow:submit-success', callback)
      requests[0].respond(200, {}, "ok")
      expect(callback.called).to.be.true

    it 'triggers submit-error', ->
      callback = sinon.spy()
      form = createForm("")
      form.submit()
      form.form.addEventListener('locflow:submit-error', callback)
      requests[0].respond(500, {}, "err")
      expect(callback.called).to.be.true

  describe '#serialize', ->
    it 'serializes an input text field', ->
      form = createForm("""
      <input name="fullname" value="Luiz Vasconcellos" />
      """)
      expect(form.serialize()).to.deep.eql(
        fullname: 'Luiz Vasconcellos'
      )

    it 'serializes an input password field', ->
      form = createForm("""
      <input type="password" name="password" value="123456" />
      """)
      expect(form.serialize()).to.deep.eql(password: '123456')

    it 'serializes an input email field', ->
      form = createForm("""
      <input type="email" name="email" value="luizpvasc@gmail.com" />
      """)
      expect(form.serialize()).to.deep.eql(email: 'luizpvasc@gmail.com')

    it 'serializes an input hidden field', ->
      form = createForm("""
      <input type="hidden" name="my_id" value="100" />
      """)
      expect(form.serialize()).to.deep.eql(my_id: '100')

    it 'serializes empty input fields with single value', ->
      form = createForm("""
      <input name="name" value="" />
      """)
      expect(form.serialize()).to.deep.eql(name: '')

    it 'serializes color input fields', ->
      form = createForm("""
      <input type="color" name="color" value="#ffffff" />
      """)
      expect(form.serialize()).to.deep.eql(color: '#ffffff')

    it 'serializes number input fields', ->
      form = createForm("""
      <input type="number" name="age" value="18" />
      """)
      expect(form.serialize()).to.deep.eql(age: '18')
      
    it 'serializes select fields', ->
      form = createForm("""
      <select name="color">
        <option value="red" selected>Red</option>
        <option value="blue">Blue</option>
      </select>
      """)
      expect(form.serialize()).to.deep.eql(color: 'red')

    it 'ignores empty select fields', ->
      form = createForm("""
      <select name="color">
        <option value="">Select one</option>
        <option value="red">Red</option>
        <option value="blue">Blue</option>
      </select>
      """)
      expect(form.serialize()).to.deep.eql({})

    it 'serializes textarea', ->
      form = createForm("""
      <textarea name="message">Hello, world!</textarea>
      """)
      expect(form.serialize()).to.deep.eql(message: 'Hello, world!')

    it 'serialize empty textarea', ->
      form = createForm("""
      <textarea name="message"></textarea>
      """)
      expect(form.serialize()).to.deep.eql(message: '')

    it 'serializes checkbox with multiple options', ->
      form = createForm("""
      <input type="checkbox" name="role" value="admin" />
      <input type="checkbox" name="role" value="manager" checked />
      """)
      expect(form.serialize()).to.deep.eql(role: ['manager'])

    it 'serializes checkbox with single option', ->
      form = createForm("""
      <input type="checkbox" name="enable_premium" checked />
      """)
      expect(form.serialize()).to.deep.eql('enable_premium': 'on')

    it 'ignores not selected checkbox', ->
      form = createForm("""
      <input type="checkbox" name="enable_premium" />
      """)
      expect(form.serialize()).to.deep.eql({})

    it 'serializes radio input', ->
      form = createForm("""
      <input type="radio" name="color" value="red" />
      <input type="radio" name="color" value="blue" checked />
      """)
      expect(form.serialize()).to.deep.eql(color: 'blue')

    it 'ignores empty radio input', ->
      form = createForm("""
      <input type="radio" name="color" value="red" />
      <input type="radio" name="color" value="blue" />
      """)
      expect(form.serialize()).to.deep.eql({})

    it 'serializes select-multiple', ->
      form = createForm("""
      <select multiple name="colors">
        <option value="red" selected>Red</option>
        <option value="blue" selected>Blue</option>
      </select>
      """)
      expect(form.serialize()).to.deep.eql(colors: ['red', 'blue'])

    it 'ignores empty select-multiple', ->
      form = createForm("""
      <select multiple name="colors">
        <option value="red">Red</option>
        <option value="blue">Blue</option>
      </select>
      """)
      expect(form.serialize()).to.deep.eql({})
    
