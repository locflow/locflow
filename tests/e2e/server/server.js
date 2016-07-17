let express = require('express')
let app = express()
let path = require('path')
let projectRoot = __dirname + '/../../../'
let bodyParser = require('body-parser');

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static(__dirname))
app.use(express.static(path.join(projectRoot, 'public/js')))

app.post('/06/items', function(req, res) {
  var itemLabel = req.body.item;
  res.set('Content-Type', 'text/javascript');
  res.send(`
    var items = document.getElementById('items');
    var item = document.createElement('li');
    item.innerHTML = "${itemLabel}";
    items.appendChild(item);
  `);
})

app.listen(3030, function() {
  console.log('server running on port [3030]')
})
