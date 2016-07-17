function incrementInnerHTML(elm) {
  var currentNumber = +elm.innerHTML;
  elm.innerHTML = currentNumber + 1;
}

window.addEventListener('load', function() {
  var banner = document.getElementById('banner');
  banner.addEventListener('click', function() {
    incrementInnerHTML(banner);
  });
});

Locflow.match('/03/home.html', function() {
  // do nothing
});

Locflow.match('/03/about.html', function() {
  // do nothing
});
