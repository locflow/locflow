Locflow.match('/02/home.html', function() {
  document.getElementById('page-title').innerHTML = 'Home page updated'

  var messages = document.querySelector('.messages')
  var counter = 0
  document.getElementById('add-message').addEventListener('click', function() {
    counter += 1
    addMessage('Generated message ' + counter)
  })

  function addMessage(text) {
    var message = document.createElement('div')
    message.className = 'message'
    message.innerHTML = text
    messages.appendChild(message)
  }
  addMessage('First message!')
})

Locflow.match('/02/about.html', function() {
  document.getElementById('page-title').innerHTML = 'About page updated'
})

Locflow.match('/02/contact.html', function() {
  var message = document.createElement('div')
  message.className = 'message'
  message.innerHTML = 'First handler'
  document.body.appendChild(message)
})

Locflow.match('/02/contact.html', function() {
  var message = document.createElement('div')
  message.className = 'message'
  message.innerHTML = 'Second handler'
  document.body.appendChild(message)
})
