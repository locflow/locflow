singleValueTypes = [
  'text', 'password', 'submit', 'textarea', 'email', 'hidden', 'color', 'number'
]

class Locflow.Form
  constructor: (@form) ->
    @serialized = {}

  serialize: ->
    for element in @form.elements
      @serializeInput(element)
    @serialized

  submit: ->
    ev = Locflow.dispatcher.dispatch('submit', data: { form: @form })
    return if ev.defaultPrevented
    method = @form.getAttribute('data-method') or @form.method
    @submitRequest = new Locflow.Request(method, @form.action,
      headers:
        'Accept': 'application/json, text/javascript'
    )
    @submitRequest.success(@onSubmitSuccess.bind(this))
    @submitRequest.error(@onSubmitError.bind(this))
    @submitRequest.send(@serialize())

  onSubmitSuccess: (response, status, xhr) ->
    Locflow.dispatcher.dispatchOn([document, @form], 'submit-success',
      data:
        form: @form
        response: response
        status: status
    )

  onSubmitError: (response, status, xhr) ->
    Locflow.dispatcher.dispatchOn([document, @form], 'submit-error',
      data:
        form: @form
        response: response
        status: status
    )

  serializeInput: (elm) ->
    if singleValueTypes.indexOf(elm.type) isnt -1
      @serializeSingleValue(elm)
    if 'select-one' is elm.type
      @serializeSelectOne(elm)
    if 'checkbox' is elm.type
      @serializeCheckbox(elm)
    if 'radio' is elm.type
      @serializeRadio(elm)
    if 'select-multiple' is elm.type
      @serializeSelectMultiple(elm)

  serializeSingleValue: (elm) ->
    @serialized[elm.name] = elm.value

  serializeSelectOne: (elm) ->
    selected = elm.options[elm.selectedIndex]?.value
    @serialized[elm.name] = selected if selected.trim() isnt ''

  serializeCheckbox: (elm) ->
    checkboxes = document.getElementsByName(elm.name)
    if checkboxes.length is 1 and elm.checked
      @serialized[elm.name] = 'on'
    else if checkboxes.length > 1
      values = []
      for checkbox in checkboxes
        values.push(checkbox.value) if checkbox.checked
      @serialized[elm.name] = values

  serializeRadio: (elm) ->
    radios = document.getElementsByName(elm.name)
    for radio in radios
      @serialized[elm.name] = radio.value if radio.checked

  serializeSelectMultiple: (elm) ->
    options = elm.options
    selected = []
    for option in options
      selected.push(option.value) if option.selected
    @serialized[elm.name] = selected if selected.length > 0

