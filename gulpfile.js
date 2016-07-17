var elixir = require('laravel-elixir');

elixir(function(mix) {
  mix.coffee([
    'locflow.coffee',
    'cache.coffee',
    'csrf.coffee',
    'dispatcher.coffee',
    'interceptor.coffee',
    'form.coffee',
    'request.coffee',
    'navigation.coffee',
    'progressbar.coffee',
    'router.coffee',
    'renderer.coffee',
    'snapshot.coffee',
    'url.coffee',
    'utils.coffee',
    'visit.coffee',
    'handler.coffee',
    'adapter/browser.coffee',
    'adapter/cordova_android.coffee',
    'adapter/cordova_ios.coffee',
    'encoding/json.coffee',
    'encoding/querystring.coffee'
  ], 'public/js/locflow.js');
});
