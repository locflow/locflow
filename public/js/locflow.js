(function() {
  var Locflow;

  Locflow = {
    version: '2.0.0',
    supported: (function() {
      return (window.history.pushState != null) && (window.requestAnimationFrame != null);
    })(),
    back: function() {
      return history.back();
    },
    forward: function() {
      return history.forward();
    },
    visit: function(path, opts) {
      var visit;
      visit = new Locflow.Visit(path, opts);
      visit.propose();
      return visit;
    },
    submit: function(target) {
      var form;
      form = new Locflow.Form(target);
      return form.submit();
    },
    match: function(path, callback) {
      this.handler || (this.handler = new Locflow.Handler());
      return this.handler.match(path, callback);
    },
    route: function(path, callbacks) {
      this.router || (this.router = new Locflow.Router());
      return this.router.register(path, callbacks);
    },
    initialize: function(sendInitialRequest) {
      var visit;
      if (sendInitialRequest == null) {
        sendInitialRequest = true;
      }
      this.adapter = new Locflow.Adapter.Browser();
      this.renderer = new Locflow.Renderer();
      this.router || (this.router = new Locflow.Router());
      this.handler || (this.handler = new Locflow.Handler());
      this.interceptor = new Locflow.Interceptor();
      this.interceptor.intercept(document.body.parentNode);
      if (sendInitialRequest) {
        visit = new Locflow.Visit(new Locflow.Url(document.location));
        this.router.invokeCustomRoute(visit);
        return visit.callHandlers();
      }
    },
    useAuthenticityTokenFromMeta: function(metaName, attrName) {
      return this.csrf = new Locflow.Csrf(metaName, attrName);
    }
  };

  Locflow.Encoding = {};

  Locflow.Adapter = {};

  if (Locflow.supported) {
    window.addEventListener('popstate', function(ev) {
      var url, visit;
      url = new Locflow.Url(document.location);
      visit = new Locflow.Visit(url, {
        action: 'restore'
      });
      return visit.propose();
    });
    window.addEventListener('load', function() {
      return Locflow.initialize(true);
    });
  }

}).call(this);

(function() {
  Locflow.Cache = (function() {
    function Cache() {
      this.data = {};
      this.limit = 9999;
    }

    Cache.prototype.setSize = function(limit) {
      this.limit = limit;
      return this.removeExceedingRecords();
    };

    Cache.prototype.sortedKeysByTime = function() {
      var key, sorted;
      sorted = [];
      for (key in this.data) {
        sorted.push([key, this.data[key].timestamp]);
      }
      return sorted.sort(function(a, b) {
        return a[1] - b[1];
      }).map(function(rec) {
        return rec[0];
      });
    };

    Cache.prototype.removeExceedingRecords = function() {
      var key, pending, results, sortedKeys;
      pending = Object.keys(this.data).length - this.limit;
      sortedKeys = this.sortedKeysByTime();
      results = [];
      while (pending > 0) {
        key = sortedKeys.shift();
        this.remove(key);
        results.push(pending -= 1);
      }
      return results;
    };

    Cache.prototype.put = function(key, value) {
      this.data[key] = {
        value: value,
        timestamp: new Date().getTime()
      };
      return this.removeExceedingRecords();
    };

    Cache.prototype.get = function(key, defaultValue) {
      var ref, value;
      value = (ref = this.data[key]) != null ? ref.value : void 0;
      if (value === void 0) {
        return defaultValue;
      } else {
        return value;
      }
    };

    Cache.prototype.has = function(key) {
      return this.get(key) !== void 0;
    };

    Cache.prototype.remove = function(key) {
      var val;
      val = this.get(key);
      delete this.data[key];
      return val;
    };

    Cache.prototype.removeAll = function() {
      var key, results;
      results = [];
      for (key in this.data) {
        results.push(this.remove(key));
      }
      return results;
    };

    return Cache;

  })();

}).call(this);

(function() {
  Locflow.Csrf = (function() {
    function Csrf(metaName, attrName) {
      this.metaName = metaName;
      this.attrName = attrName != null ? attrName : this.metaName;
    }

    Csrf.prototype.getFromMeta = function() {
      var meta;
      meta = document.querySelector('meta[name="' + this.metaName + '"]');
      if (meta) {
        return meta.content;
      }
    };

    Csrf.prototype.appendToken = function(obj) {
      var value;
      value = this.getFromMeta();
      if (value && obj) {
        return obj[this.attrName] = value;
      }
    };

    return Csrf;

  })();

}).call(this);

(function() {
  Locflow.Dispatcher = (function() {
    function Dispatcher(prefix) {
      this.prefix = prefix != null ? prefix : 'locflow:';
    }

    Dispatcher.prototype.dispatchOn = function(targets, eventName, data) {
      var i, len, results, target;
      results = [];
      for (i = 0, len = targets.length; i < len; i++) {
        target = targets[i];
        results.push(this.dispatch(eventName, {
          target: target,
          data: data
        }));
      }
      return results;
    };

    Dispatcher.prototype.dispatch = function(eventName, arg) {
      var data, ev, ref, target;
      ref = arg != null ? arg : {}, target = ref.target, data = ref.data;
      ev = document.createEvent('Events');
      ev.initEvent(this.normalizeName(eventName), true, true);
      ev.data = data != null ? data : {};
      (target != null ? target : document).dispatchEvent(ev);
      return ev;
    };

    Dispatcher.prototype.normalizeName = function(name) {
      return "" + this.prefix + name;
    };

    return Dispatcher;

  })();

  Locflow.dispatcher = new Locflow.Dispatcher();

}).call(this);

(function() {
  Locflow.Interceptor = (function() {
    function Interceptor() {}

    Interceptor.prototype.intercept = function(elm) {
      elm.addEventListener('click', this.onClick.bind(this));
      return elm.addEventListener('submit', this.onSubmit.bind(this));
    };

    Interceptor.prototype.shouldIgnore = function(elm) {
      if (this.getElementAction(elm) === 'accept') {
        return false;
      }
      if (this.getElementAction(elm) === 'ignore') {
        return true;
      }
      if (this.getParentAction(elm) === 'ignore') {
        return true;
      }
      return false;
    };

    Interceptor.prototype.getElementAction = function(elm) {
      var dataLocflow;
      dataLocflow = elm && elm.getAttribute && elm.getAttribute('data-locflow');
      if (dataLocflow === 'false') {
        return 'ignore';
      }
      if (dataLocflow === 'true') {
        return 'accept';
      }
      return 'default';
    };

    Interceptor.prototype.getParentAction = function(elm) {
      var action, parent;
      parent = elm.parentNode;
      while (parent) {
        action = this.getElementAction(parent);
        if (action !== 'default') {
          return action;
        }
        parent = parent.parentNode;
      }
      return 'default';
    };

    Interceptor.prototype.hasParentAnchor = function(elm) {
      return this.getParentAnchor(elm) !== null;
    };

    Interceptor.prototype.getParentAnchor = function(elm) {
      while (elm.parentNode) {
        if (elm.parentNode.tagName === 'A') {
          return elm.parentNode;
        }
        elm = elm.parentNode;
      }
      return null;
    };

    Interceptor.prototype.onClick = function(ev) {
      var target;
      target = ev.target;
      if (target.tagName === 'A' && target.href && !this.shouldIgnore(target)) {
        ev.preventDefault();
        return this.proposeVisitFromAnchor(target);
      } else if (this.hasParentAnchor(target) && !this.shouldIgnore(this.getParentAnchor(target))) {
        ev.preventDefault();
        return this.proposeVisitFromAnchor(this.getParentAnchor(target));
      }
    };

    Interceptor.prototype.proposeVisitFromAnchor = function(anchor) {
      var method, request;
      method = anchor.getAttribute('data-method') || 'GET';
      if (method.toUpperCase() !== 'GET') {
        request = new Locflow.Request(method, anchor.href);
        return request.send();
      } else {
        this.visit = new Locflow.Visit(anchor.href);
        return this.visit.propose();
      }
    };

    Interceptor.prototype.onSubmit = function(ev) {
      var form, targetForm;
      targetForm = ev.target;
      if (targetForm.getAttribute('data-locflow') === 'remote' && !this.shouldIgnore(targetForm)) {
        ev.preventDefault();
        form = new Locflow.Form(targetForm);
        return form.submit();
      }
    };

    return Interceptor;

  })();

}).call(this);

(function() {
  var singleValueTypes;

  singleValueTypes = ['text', 'password', 'submit', 'textarea', 'email', 'hidden', 'color', 'number'];

  Locflow.Form = (function() {
    function Form(form) {
      this.form = form;
      this.serialized = {};
    }

    Form.prototype.serialize = function() {
      var element, i, len, ref;
      ref = this.form.elements;
      for (i = 0, len = ref.length; i < len; i++) {
        element = ref[i];
        this.serializeInput(element);
      }
      return this.serialized;
    };

    Form.prototype.submit = function() {
      var ev, method;
      ev = Locflow.dispatcher.dispatch('submit', {
        data: {
          form: this.form
        }
      });
      if (ev.defaultPrevented) {
        return;
      }
      method = this.form.getAttribute('data-method') || this.form.method;
      this.submitRequest = new Locflow.Request(method, this.form.action, {
        headers: {
          'Accept': 'application/json, text/javascript'
        }
      });
      this.submitRequest.success(this.onSubmitSuccess.bind(this));
      this.submitRequest.error(this.onSubmitError.bind(this));
      return this.submitRequest.send(this.serialize());
    };

    Form.prototype.onSubmitSuccess = function(response, status, xhr) {
      return Locflow.dispatcher.dispatchOn([document, this.form], 'submit-success', {
        data: {
          form: this.form,
          response: response,
          status: status
        }
      });
    };

    Form.prototype.onSubmitError = function(response, status, xhr) {
      return Locflow.dispatcher.dispatchOn([document, this.form], 'submit-error', {
        data: {
          form: this.form,
          response: response,
          status: status
        }
      });
    };

    Form.prototype.serializeInput = function(elm) {
      if (singleValueTypes.indexOf(elm.type) !== -1) {
        this.serializeSingleValue(elm);
      }
      if ('select-one' === elm.type) {
        this.serializeSelectOne(elm);
      }
      if ('checkbox' === elm.type) {
        this.serializeCheckbox(elm);
      }
      if ('radio' === elm.type) {
        this.serializeRadio(elm);
      }
      if ('select-multiple' === elm.type) {
        return this.serializeSelectMultiple(elm);
      }
    };

    Form.prototype.serializeSingleValue = function(elm) {
      return this.serialized[elm.name] = elm.value;
    };

    Form.prototype.serializeSelectOne = function(elm) {
      var ref, selected;
      selected = (ref = elm.options[elm.selectedIndex]) != null ? ref.value : void 0;
      if (selected.trim() !== '') {
        return this.serialized[elm.name] = selected;
      }
    };

    Form.prototype.serializeCheckbox = function(elm) {
      var checkbox, checkboxes, i, len, values;
      checkboxes = document.getElementsByName(elm.name);
      if (checkboxes.length === 1 && elm.checked) {
        return this.serialized[elm.name] = 'on';
      } else if (checkboxes.length > 1) {
        values = [];
        for (i = 0, len = checkboxes.length; i < len; i++) {
          checkbox = checkboxes[i];
          if (checkbox.checked) {
            values.push(checkbox.value);
          }
        }
        return this.serialized[elm.name] = values;
      }
    };

    Form.prototype.serializeRadio = function(elm) {
      var i, len, radio, radios, results;
      radios = document.getElementsByName(elm.name);
      results = [];
      for (i = 0, len = radios.length; i < len; i++) {
        radio = radios[i];
        if (radio.checked) {
          results.push(this.serialized[elm.name] = radio.value);
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    Form.prototype.serializeSelectMultiple = function(elm) {
      var i, len, option, options, selected;
      options = elm.options;
      selected = [];
      for (i = 0, len = options.length; i < len; i++) {
        option = options[i];
        if (option.selected) {
          selected.push(option.value);
        }
      }
      if (selected.length > 0) {
        return this.serialized[elm.name] = selected;
      }
    };

    return Form;

  })();

}).call(this);

(function() {
  Locflow.Request = (function() {
    function Request(method, url1, opts1) {
      this.method = method;
      this.url = url1;
      this.opts = opts1 != null ? opts1 : {};
      this.timeoutMillis = this.opts.timeoutMillis || 4000;
      this.xhr = null;
      this.aborted = false;
    }

    Request.GET = function(url, opts) {
      var req;
      req = new Locflow.Request('GET', url, opts);
      req.send();
      return req;
    };

    Request.POST = function(url, data, opts) {
      var req;
      req = new Locflow.Request('POST', url, opts);
      req.send(data);
      return req;
    };

    Request.PUT = function(url, data, opts) {
      var req;
      req = new Locflow.Request('PUT', url, opts);
      req.send(data);
      return req;
    };

    Request.DELETE = function(url, data, opts) {
      var req;
      req = new Locflow.Request('DELETE', url, opts);
      req.send(data);
      return req;
    };

    Request.prototype.success = function(callback) {
      return this.opts.success = callback;
    };

    Request.prototype.error = function(callback) {
      return this.opts.error = callback;
    };

    Request.prototype.timeout = function(callback) {
      return this.opts.timeout = callback;
    };

    Request.prototype.abort = function() {
      var ref;
      this.aborted = true;
      return (ref = this.xhr) != null ? ref.abort() : void 0;
    };

    Request.prototype.parseResponse = function() {
      var contentType, e, error, ref;
      if (this.parsedResponse) {
        return this.parsedResponse;
      }
      contentType = (ref = this.xhr) != null ? ref.getResponseHeader('Content-Type') : void 0;
      if (contentType && contentType.indexOf('application/json') === 0) {
        this.parsedResponse = JSON.parse(this.xhr.responseText);
      } else if (contentType && contentType.indexOf('text/javascript') === 0) {
        this.parsedResponse = this.xhr.responseText;
        try {
          eval(this.xhr.responseText);
        } catch (error) {
          e = error;
          if (typeof Locflow.handleInvalidJavascriptResponse === "function") {
            Locflow.handleInvalidJavascriptResponse(this.xhr.responseText);
          }
        }
      } else {
        this.parsedResponse = this.xhr.responseText;
      }
      return this.parsedResponse;
    };

    Request.prototype.setAcceptHeader = function() {
      var format;
      format = new Locflow.Url(this.url).format();
      if (format === 'html') {
        return this.xhr.setRequestHeader('Accept', 'text/html, application/xhtml+xml, application/xml');
      } else if (format === 'json') {
        return this.xhr.setRequestHeader('Accept', 'application/json; charset=utf-8');
      } else if (format === 'js') {
        return this.xhr.setRequestHeader('Accept', 'text/javascript; charset=utf-8');
      }
    };

    Request.prototype.setDefaultHeaders = function() {
      var ref, ref1;
      this.xhr.setRequestHeader('X-Locflow', 'true');
      this.xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
      if ((ref = Locflow.csrf) != null ? ref.getFromMeta() : void 0) {
        this.xhr.setRequestHeader('X-CSRF-Token', Locflow.csrf.getFromMeta());
      }
      if (!((ref1 = this.opts.headers) != null ? ref1['Accept'] : void 0)) {
        return this.setAcceptHeader();
      }
    };

    Request.prototype.trigger = function(action) {
      var base;
      this.parseResponse();
      if (this.xhr && this.xhr.readyState > 0) {
        return typeof (base = this.opts)[action] === "function" ? base[action](this.parseResponse(), this.xhr.status, this.xhr) : void 0;
      }
    };

    Request.prototype.send = function(body) {
      var key, ref, sendData, value;
      if (body == null) {
        body = {};
      }
      this.xhr = new XMLHttpRequest();
      this.xhr.open(this.method, this.url, true);
      this.setDefaultHeaders();
      ref = this.opts.headers;
      for (key in ref) {
        value = ref[key];
        this.xhr.setRequestHeader(key, value);
      }
      this.xhr.withCredentials = this.opts.withCredentials;
      this.xhrTimeout = setTimeout((function(_this) {
        return function() {
          if (_this.aborted) {
            return;
          }
          return _this.trigger('timeout');
        };
      })(this), this.timeoutMillis);
      this.xhr.onerror = (function(_this) {
        return function() {
          return _this.trigger('error');
        };
      })(this);
      this.xhr.onreadystatechange = (function(_this) {
        return function() {
          if (_this.aborted) {
            return;
          }
          if (_this.xhr.readyState === 4) {
            clearTimeout(_this.xhrTimeout);
            if (_this.xhr.status === 200) {
              return _this.trigger('success');
            } else {
              return _this.trigger('error');
            }
          }
        };
      })(this);
      sendData = this.formatBody(body);
      return this.xhr.send(sendData);
    };

    Request.prototype.formatBody = function(body) {
      var encoded;
      if (this.method === 'GET') {
        return '';
      }
      if (body && Locflow.csrf) {
        Locflow.csrf.appendToken(body);
      }
      encoded = new Locflow.Encoding.Json(body).toQueryString();
      return encoded;
    };

    return Request;

  })();

}).call(this);

(function() {
  Locflow.Navigation = (function() {
    function Navigation() {}

    Navigation.prototype.onVisit = function(visit, cache) {
      if (visit.action !== 'restore') {
        return visit.sendRequest();
      }
    };

    Navigation.prototype.onLeave = function(visit, cache) {
      return Locflow.snapshot.stage(visit.url.toString(), document.title);
    };

    Navigation.prototype.restore = function(visit, cache) {
      if (Locflow.snapshot.cache.has(visit.url.toString())) {
        return Locflow.snapshot.render(visit.url.toString());
      } else {
        return visit.sendRequest();
      }
    };

    return Navigation;

  })();

}).call(this);

(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Locflow.ProgressBar = (function() {
    var ANIMATION_DURATION;

    ANIMATION_DURATION = 300;

    ProgressBar.defaultCSS = ".locflow-progress-bar {\n  position: fixed;\n  display: block;\n  top: 0;\n  left: 0;\n  height: 3px;\n  background: #0076ff;\n  z-index: 9999;\n  transition: width " + ANIMATION_DURATION + "ms ease-out, opacity " + (ANIMATION_DURATION / 2) + "ms " + (ANIMATION_DURATION / 2) + "ms ease-in;\n  transform: translate3d(0, 0, 0);\n}";

    function ProgressBar() {
      this.trickle = bind(this.trickle, this);
      this.stylesheetElement = this.createStylesheetElement();
      this.progressElement = this.createProgressElement();
    }

    ProgressBar.prototype.show = function() {
      if (!this.visible) {
        this.visible = true;
        this.installStylesheetElement();
        this.installProgressElement();
        return this.startTrickling();
      }
    };

    ProgressBar.prototype.hide = function() {
      if (this.visible && !this.hiding) {
        this.hiding = true;
        return this.fadeProgressElement((function(_this) {
          return function() {
            _this.uninstallProgressElement();
            _this.stopTrickling();
            _this.visible = false;
            return _this.hiding = false;
          };
        })(this));
      }
    };

    ProgressBar.prototype.setValue = function(value) {
      this.value = value;
      return this.refresh();
    };

    ProgressBar.prototype.installStylesheetElement = function() {
      return document.head.insertBefore(this.stylesheetElement, document.head.firstChild);
    };

    ProgressBar.prototype.installProgressElement = function() {
      this.progressElement.style.width = 0;
      this.progressElement.style.opacity = 1;
      document.documentElement.insertBefore(this.progressElement, document.body);
      return this.refresh();
    };

    ProgressBar.prototype.fadeProgressElement = function(callback) {
      this.progressElement.style.opacity = 0;
      return setTimeout(callback, ANIMATION_DURATION * 1.5);
    };

    ProgressBar.prototype.uninstallProgressElement = function() {
      if (this.progressElement.parentNode) {
        return document.documentElement.removeChild(this.progressElement);
      }
    };

    ProgressBar.prototype.startTrickling = function() {
      return this.trickleInterval != null ? this.trickleInterval : this.trickleInterval = setInterval(this.trickle, ANIMATION_DURATION);
    };

    ProgressBar.prototype.stopTrickling = function() {
      clearInterval(this.trickleInterval);
      return this.trickleInterval = null;
    };

    ProgressBar.prototype.trickle = function() {
      return this.setValue(this.value + Math.random() / 100);
    };

    ProgressBar.prototype.refresh = function() {
      return requestAnimationFrame((function(_this) {
        return function() {
          return _this.progressElement.style.width = (10 + (_this.value * 90)) + "%";
        };
      })(this));
    };

    ProgressBar.prototype.createStylesheetElement = function() {
      var element;
      element = document.createElement("style");
      element.type = "text/css";
      element.textContent = this.constructor.defaultCSS;
      return element;
    };

    ProgressBar.prototype.createProgressElement = function() {
      var element;
      element = document.createElement("div");
      element.className = "locflow-progress-bar";
      return element;
    };

    return ProgressBar;

  })();

}).call(this);

(function() {
  var routes;

  routes = [];

  Locflow.Router = (function() {
    function Router() {
      this.routes = [];
      this.defaultNavigation = new Locflow.Navigation();
      this.defaultNavigation.cache = Locflow.navigationCache;
    }

    Router.prototype.removeAll = function() {
      return this.routes = [];
    };

    Router.prototype.register = function(path, callbacks) {
      var route;
      route = {
        cache: new Locflow.Cache(),
        url: new Locflow.Url(path),
        restore: callbacks.restore,
        onVisit: callbacks.onVisit,
        onLeave: callbacks.onLeave
      };
      this.routes.push(route);
      return route;
    };

    Router.prototype.findMatch = function(path) {
      var i, len, ref, route;
      ref = this.routes;
      for (i = 0, len = ref.length; i < len; i++) {
        route = ref[i];
        if (route.url.match(new Locflow.Url(path))) {
          return route;
        }
      }
      return this.defaultNavigation;
    };

    Router.prototype.invokeCustomRoute = function(visit) {
      var route;
      route = this.findMatch(visit.url);
      if (route instanceof Locflow.Navigation) {
        this.currentRoute = route;
        return this.latestVisit = visit;
      } else {
        return this.callRouteVisitActions(visit, route);
      }
    };

    Router.prototype.invokeVisit = function(visit) {
      var route;
      route = this.findMatch(visit.url);
      return this.callRouteVisitActions(visit, route);
    };

    Router.prototype.callRouteVisitActions = function(visit, route) {
      var ref;
      if ((ref = this.currentRoute) != null) {
        ref.onLeave(this.latestVisit, this.currentRoute.cache);
      }
      this.currentRoute = route;
      this.latestVisit = visit;
      if (visit.action !== 'restore') {
        return route != null ? route.onVisit(visit, route.cache) : void 0;
      }
    };

    Router.prototype.restore = function(visit) {
      var route;
      route = this.findMatch(visit.url);
      if (route != null) {
        if (typeof route.restore === "function") {
          route.restore(visit, route.cache);
        }
      }
      if (visit.action === 'restore') {
        return setTimeout(function() {
          return visit.finish();
        });
      }
    };

    return Router;

  })();

}).call(this);

(function() {
  Locflow.Renderer = (function() {
    function Renderer() {
      this.cache = new Locflow.Cache();
    }

    Renderer.prototype.cloneBody = function() {
      return document.body.cloneNode(true);
    };

    Renderer.prototype.findPermanentElements = function() {
      var elm, i, len, permanentElements;
      permanentElements = document.querySelectorAll('*[data-locflow="permanent"]:not([data-shallow])');
      for (i = 0, len = permanentElements.length; i < len; i++) {
        elm = permanentElements[i];
        if (!elm.id) {
          throw new Error('permanent element must have an id');
        }
      }
      return permanentElements;
    };

    Renderer.prototype.removePermanentElements = function() {
      var elm, i, len, permanentElements, shallowClone;
      permanentElements = this.findPermanentElements();
      for (i = 0, len = permanentElements.length; i < len; i++) {
        elm = permanentElements[i];
        shallowClone = elm.cloneNode(false);
        shallowClone.setAttribute('data-shallow', 'true');
        elm.parentNode.replaceChild(shallowClone, elm);
      }
      return permanentElements;
    };

    Renderer.prototype.removeAndCachePermanentElements = function() {
      var currentPermanent, currentPermanents, found, i, j, len, len1, mergedPermanents, permanent, permanents;
      permanents = this.removePermanentElements();
      currentPermanents = this.cache.get('elements') || [];
      mergedPermanents = Array.prototype.slice.call(currentPermanents);
      for (i = 0, len = permanents.length; i < len; i++) {
        permanent = permanents[i];
        found = false;
        for (j = 0, len1 = currentPermanents.length; j < len1; j++) {
          currentPermanent = currentPermanents[j];
          if (permanent.id === currentPermanent.id) {
            found = true;
            break;
          }
        }
        if (!found) {
          mergedPermanents.push(permanent);
        }
      }
      this.cache.put('elements', mergedPermanents);
      return mergedPermanents;
    };

    Renderer.prototype.mergePermanentElements = function(permanentElements) {
      var elm, i, len, results, shallowPlaceholder;
      results = [];
      for (i = 0, len = permanentElements.length; i < len; i++) {
        elm = permanentElements[i];
        shallowPlaceholder = document.getElementById(elm.id);
        if (shallowPlaceholder) {
          results.push(shallowPlaceholder.parentNode.replaceChild(elm, shallowPlaceholder));
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    Renderer.prototype.mergeCachedPermanentElements = function() {
      return this.mergePermanentElements(this.cache.get('elements', []));
    };

    Renderer.prototype.scrollTo = function(scrollX, scrollY) {
      return window.scrollTo(scrollX, scrollY);
    };

    Renderer.prototype.extractHeadTags = function(html) {
      var head;
      head = html.getElementsByTagName('head');
      if (head.length === 1) {
        head = head[0];
        return head.getElementsByTagName('meta');
      } else {
        return [];
      }
    };

    Renderer.prototype.extractTitle = function(html) {
      var titleTags;
      titleTags = html.getElementsByTagName('title');
      if (titleTags.length === 1) {
        return titleTags[0].innerHTML;
      } else {
        return document.title;
      }
    };

    Renderer.prototype.updateTitle = function(title) {
      return document.title = title;
    };

    Renderer.prototype.mergeHeadTags = function(tags) {
      var currentMeta, i, len, meta, results;
      results = [];
      for (i = 0, len = tags.length; i < len; i++) {
        meta = tags[i];
        if (!(meta && meta.name)) {
          continue;
        }
        currentMeta = document.querySelector("meta[name=\"" + meta.name + "\"]");
        if (currentMeta) {
          results.push(currentMeta.content = meta.content);
        } else {
          results.push(document.head.appendChild(meta));
        }
      }
      return results;
    };

    Renderer.prototype.extractBody = function(html) {
      var body;
      body = html.getElementsByTagName('body');
      if (body.length === 1) {
        return body[0];
      } else {
        throw new Error("body tag not found in HTML");
      }
    };

    Renderer.prototype.replaceAndCacheStagedBody = function(body) {
      var scrollX, scrollY, stagedBody;
      scrollX = window.pageXOffset;
      scrollY = window.pageYOffset;
      this.removeAndCachePermanentElements();
      stagedBody = document.body.parentNode.replaceChild(body, document.body);
      this.mergeCachedPermanentElements();
      return Locflow.snapshot.cacheStagedBody(stagedBody, scrollX, scrollY);
    };

    Renderer.prototype.render = function(htmlString) {
      var el;
      el = document.createElement('html');
      el.innerHTML = htmlString;
      this.updateTitle(this.extractTitle(el));
      this.mergeHeadTags(this.extractHeadTags(el));
      return this.replaceAndCacheStagedBody(this.extractBody(el));
    };

    return Renderer;

  })();

}).call(this);

(function() {
  Locflow.Snapshot = (function() {
    function Snapshot() {
      this.cache = new Locflow.Cache();
    }

    Snapshot.prototype.stage = function(path, title) {
      return this.staged = {
        path: path,
        title: title
      };
    };

    Snapshot.prototype.cacheStagedBody = function(body, scrollX, scrollY) {
      if (this.staged) {
        this.cache.put(this.staged.path, {
          body: body,
          scrollX: scrollX,
          scrollY: scrollY,
          title: this.staged.title
        });
        return this.staged = null;
      }
    };

    Snapshot.prototype.render = function(url) {
      var record;
      record = this.cache.get(url);
      if (record) {
        Locflow.renderer.replaceAndCacheStagedBody(record.body);
        Locflow.renderer.scrollTo(record.scrollX, record.scrollY);
        return Locflow.renderer.updateTitle(record.title);
      }
    };

    return Snapshot;

  })();

  Locflow.snapshot = new Locflow.Snapshot();

}).call(this);

(function() {
  Locflow.Url = (function() {
    function Url(url) {
      if (url instanceof Locflow.Url) {
        this.copyFromUrl(url);
      } else if (url && url.host && url.pathname) {
        this.copyFromLocation(url);
      } else if ('string' === typeof url) {
        this.initializeFromString(url);
      }
    }

    Url.prototype.copyFromUrl = function(url) {
      this.protocol = url.protocol;
      this.domain = url.domain;
      this.query = url.query;
      this.path = url.path;
      this.port = url.port;
      return this.hash = url.hash;
    };

    Url.prototype.copyFromLocation = function(location) {
      this.protocol = location.protocol.replace(':', '');
      this.domain = location.host;
      this.query = location.search;
      this.path = location.pathname;
      this.port = location.port;
      this.hash = location.hash;
      if (this.domain.indexOf(':') !== -1) {
        return this.domain = this.domain.split(':')[0];
      }
    };

    Url.prototype.initializeFromString = function(url) {
      var matches, parts, regex;
      regex = /(file|http[s]?:\/\/)?([^\/?#]*)?([^?#]*)([^#]*)([\s\S]*)/i;
      matches = url.toLowerCase().match(regex);
      if (matches) {
        this.protocol = (matches[1] || '').replace('://', '');
        this.domain = matches[2] || '';
        this.path = matches[3];
        this.query = matches[4];
        this.hash = matches[5];
        this.port = '';
        if (this.domain.indexOf(':') !== -1) {
          parts = this.domain.split(':');
          this.domain = parts[0];
          return this.port = parts[1];
        }
      }
    };

    Url.prototype.toString = function() {
      var urlStr;
      urlStr = '';
      urlStr += this.protocol ? this.protocol + '://' : document.location.protocol + '//';
      urlStr += this.domain ? this.domain : document.location.host;
      urlStr += this.port ? ':' + this.port : '';
      return urlStr + (this.path || '/') + this.query + this.hash;
    };

    Url.prototype.queryObject = function() {
      return new Locflow.Encoding.QueryString(this.query).toJson();
    };

    Url.prototype.setQueryObject = function(obj) {
      return this.query = '?' + new Locflow.Encoding.Json(obj).toQueryString();
    };

    Url.prototype.withoutHash = function() {
      var hashless;
      hashless = new Locflow.Url(this);
      hashless.hash = '';
      return hashless;
    };

    Url.prototype.format = function() {
      if (this.path.indexOf('.json') === this.path.length - '.json'.length) {
        return 'json';
      } else if (this.path.indexOf('.js') === this.path.length - '.js'.length) {
        return 'js';
      } else {
        return 'html';
      }
    };

    Url.prototype.match = function(other) {
      var hashParams, pathParams;
      pathParams = this.matchPath(other);
      hashParams = this.matchHash(other);
      if (!(pathParams && hashParams)) {
        return false;
      }
      return Locflow.mergeObjects(pathParams, hashParams);
    };

    Url.prototype.matchPath = function(other) {
      var i, index, len, namedParams, otherPath, otherPaths, path, paths;
      if (!(other instanceof Locflow.Url)) {
        other = new Locflow.Url(other);
      }
      if (this.path === other.path) {
        return {};
      }
      paths = this.path.replace(/\/$/, '').split('/');
      otherPaths = other.path.replace(/\/$/, '').split('/');
      if (paths.length !== otherPaths.length) {
        return false;
      }
      namedParams = {};
      for (index = i = 0, len = paths.length; i < len; index = ++i) {
        path = paths[index];
        otherPath = otherPaths[index];
        if (/^\:/.test(path)) {
          path = path.replace(/^\:/, '');
          if (namedParams[path]) {
            throw new Error("url [" + (this.toString()) + "] has multiple named parameters [:" + path + "]");
          }
          namedParams[path] = otherPath;
        } else if (path !== otherPath) {
          return false;
        }
      }
      return namedParams;
    };

    Url.prototype.matchHash = function(url) {
      var attr, hashEncoding, hashQuery, key, namedParams, targetHashEncoding, targetHashQuery;
      if (!(url instanceof Locflow.Url)) {
        url = new Locflow.Url(url);
      }
      if (this.hash === url.hash) {
        return {};
      }
      hashEncoding = new Locflow.Encoding.QueryString(this.hash.replace('#', ''));
      targetHashEncoding = new Locflow.Encoding.QueryString(url.hash.replace('#', ''));
      if (!(hashEncoding.isValid() && targetHashEncoding.isValid())) {
        return false;
      }
      hashQuery = hashEncoding.toJson();
      targetHashQuery = targetHashEncoding.toJson();
      namedParams = {};
      for (key in hashQuery) {
        attr = hashQuery[key];
        if (attr.indexOf(':') === 0) {
          if (!targetHashQuery[key]) {
            return false;
          }
          if (namedParams[attr.replace(':', '')] !== void 0) {
            throw new Error("hash [" + this.hash + "] has multiple parameters [" + attr + "]");
          }
          namedParams[attr.replace(':', '')] = targetHashQuery[key];
        } else {
          if (attr !== targetHashQuery[key]) {
            return false;
          }
        }
      }
      return namedParams;
    };

    return Url;

  })();

}).call(this);

(function() {
  Locflow.cloneArray = function(source) {
    return source.map(function(elm) {
      return elm;
    });
  };

  Locflow.mergeObjects = function(obj1, obj2) {
    var key, merged, value;
    merged = {};
    for (key in obj2) {
      value = obj2[key];
      merged[key] = value;
    }
    for (key in obj1) {
      value = obj1[key];
      merged[key] = value;
    }
    return merged;
  };

}).call(this);

(function() {
  Locflow.Visit = (function() {
    function Visit(url, opts) {
      this.url = url;
      this.opts = opts != null ? opts : {
        action: 'advance'
      };
      this.action = this.opts.action;
      this.state = 'initialized';
      this.stateHistory = [this.state];
      this.timing = {};
      this.timeoutMillis = 4000;
    }

    Visit.prototype.setState = function(state) {
      this.state = state;
      return this.stateHistory.push(this.state);
    };

    Visit.prototype.propose = function() {
      var ref;
      this.setState('proposed');
      return (ref = Locflow.adapter) != null ? ref.visitProposed(this) : void 0;
    };

    Visit.prototype.restore = function() {
      this.setState('restored');
      this.trackTiming('restore');
      return Locflow.router.restore(this);
    };

    Visit.prototype.loadCachedSnapshot = function() {
      return Locflow.snapshot.render(this.url.toString());
    };

    Visit.prototype.start = function() {
      var ref;
      this.setState('started');
      this.trackTiming('start');
      Locflow.router.invokeVisit(this);
      return (ref = Locflow.adapter) != null ? ref.visitRequestStarted(this) : void 0;
    };

    Visit.prototype.callHandlersIfNotRestore = function() {
      if (this.action !== 'restore') {
        return this.callHandlers();
      }
    };

    Visit.prototype.callHandlers = function() {
      var ref;
      return (ref = Locflow.handler) != null ? ref.call(this.url) : void 0;
    };

    Visit.prototype.render = function() {
      var ref;
      if ((ref = Locflow.renderer) != null) {
        ref.render(this.requestResponse);
      }
      return this.finish();
    };

    Visit.prototype.finish = function() {
      var ref;
      return (ref = Locflow.adapter) != null ? ref.visitRequestFinished(this) : void 0;
    };

    Visit.prototype.progress = function(value) {
      var ref;
      return (ref = Locflow.adapter) != null ? ref.visitRequestProgressed(value) : void 0;
    };

    Visit.prototype.sendRequest = function() {
      return this.request = Locflow.Request.GET(this.url, {
        success: this.onRequestSuccess.bind(this),
        error: this.onRequestError.bind(this),
        timeout: this.onRequestTimeout.bind(this),
        timeoutMillis: this.timeoutMillis
      });
    };

    Visit.prototype.onRequestSuccess = function(requestResponse, requestStatus, xhr) {
      var ref;
      this.requestResponse = requestResponse;
      this.requestStatus = requestStatus;
      return (ref = Locflow.adapter) != null ? ref.visitRequestCompleted(this) : void 0;
    };

    Visit.prototype.onRequestError = function(requestResponse, requestStatus, xhr) {
      var ref;
      this.requestResponse = requestResponse;
      this.requestStatus = requestStatus;
      return (ref = Locflow.adapter) != null ? ref.visitRequestFailedWithStatusCode(this) : void 0;
    };

    Visit.prototype.onRequestTimeout = function() {
      var ref;
      return (ref = Locflow.adapter) != null ? ref.visitRequestTimeout(this) : void 0;
    };

    Visit.prototype.changeHistory = function() {
      if (this.opts.action === 'advance') {
        return this.advanceHistory();
      }
      if (this.opts.action === 'replace') {
        return this.replaceHistory();
      }
    };

    Visit.prototype.advanceHistory = function() {
      return history.pushState({
        locflow: true
      }, null, this.url);
    };

    Visit.prototype.replaceHistory = function() {
      return history.replaceState({
        locflow: true
      }, null, this.url);
    };

    Visit.prototype.trackTiming = function(step) {
      return this.timing[step] = new Date().getTime();
    };

    return Visit;

  })();

}).call(this);

(function() {
  Locflow.Handler = (function() {
    function Handler() {
      this.handlers = [];
    }

    Handler.prototype.match = function(path, callback) {
      var url;
      url = new Locflow.Url(path);
      return this.handlers.push({
        url: url,
        callback: callback
      });
    };

    Handler.prototype.sameMatchRule = function(handler1, handler2) {
      return handler1.url.path === handler2.url.path && handler1.url.hash === handler2.url.hash;
    };

    Handler.prototype.find = function(path) {
      var firstMatch, url;
      url = new Locflow.Url(path);
      firstMatch = null;
      return this.handlers.filter((function(_this) {
        return function(handler) {
          if (firstMatch) {
            return _this.sameMatchRule(firstMatch, handler);
          }
          if (handler.url.match(url)) {
            firstMatch = handler;
            return true;
          }
        };
      })(this));
    };

    Handler.prototype.call = function(path) {
      var handler, i, len, ref, results;
      ref = this.find(path);
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        handler = ref[i];
        results.push(handler.callback(handler.url.match(new Locflow.Url(path))));
      }
      return results;
    };

    return Handler;

  })();

}).call(this);

(function() {
  Locflow.Adapter.Browser = (function() {
    function Browser() {
      this.progressBar = new Locflow.ProgressBar();
    }

    Browser.prototype.visitProposed = function(visit) {
      return visit.start();
    };

    Browser.prototype.visitRequestStarted = function(visit) {
      visit.changeHistory();
      if (visit.action === 'restore') {
        visit.restore();
      } else {
        visit.loadCachedSnapshot();
      }
      this.progressBar.setValue(0);
      return this.progressBar.show();
    };

    Browser.prototype.visitRequestProgressed = function(value) {
      return this.progressBar.setValue(value);
    };

    Browser.prototype.visitRequestCompleted = function(visit) {
      return visit.render();
    };

    Browser.prototype.visitRequestFinished = function(visit) {
      this.progressBar.setValue(100);
      setTimeout((function(_this) {
        return function() {
          return _this.progressBar.hide();
        };
      })(this), 50);
      return visit.callHandlersIfNotRestore();
    };

    Browser.prototype.visitRequestFailedWithStatusCode = function(visit) {
      return console.log('VISIT FAILED');
    };

    Browser.prototype.visitRequestTimeout = function(visit) {
      return console.log('VISIT TIMEOUTED');
    };

    return Browser;

  })();

}).call(this);

(function() {


}).call(this);

(function() {


}).call(this);

(function() {
  Locflow.Encoding.Json = (function() {
    function Json(json1) {
      this.json = json1;
    }

    Json.prototype.toQueryString = function() {
      var flatMap;
      flatMap = this.generateFlatArray();
      if (Object.keys(flatMap).length === 0) {
        return '';
      }
      return flatMap.map((function(_this) {
        return function(pair) {
          return _this.encodeKeyValuePair(pair);
        };
      })(this)).reduce(function(arr, val) {
        return arr.concat(val);
      }).reduce(function(query, pair) {
        return query += pair + "&";
      }, '').replace(/\&$/, '');
    };

    Json.prototype.generateFlatArray = function(target, path, json) {
      var key, keyPath, value;
      if (target == null) {
        target = [];
      }
      if (path == null) {
        path = [];
      }
      if (json == null) {
        json = this.json;
      }
      for (key in json) {
        value = json[key];
        keyPath = Locflow.cloneArray(path);
        keyPath.push(key);
        if (typeof value === 'object' && !Array.isArray(value)) {
          this.generateFlatArray(target, keyPath, value);
        } else {
          target.push({
            key: keyPath,
            value: value
          });
        }
      }
      return target;
    };

    Json.prototype.encodeKeyValuePair = function(arg) {
      var key, value;
      key = arg.key, value = arg.value;
      if (Array.isArray(value) && value.length > 1) {
        return value.map((function(_this) {
          return function(singleValue) {
            return _this.encodeSingleKeyValuePair({
              key: key,
              value: [singleValue]
            });
          };
        })(this)).reduce(function(arr, val) {
          return arr.concat(val);
        });
      } else {
        return this.encodeSingleKeyValuePair({
          key: key,
          value: value
        });
      }
    };

    Json.prototype.encodeSingleKeyValuePair = function(arg) {
      var i, joinedKey, key, len, path, ref, suffix, value;
      key = arg.key, value = arg.value;
      if (Array.isArray(value)) {
        suffix = '[]';
        value = value[0];
      } else {
        suffix = '';
      }
      value = encodeURI(value);
      if (key.length === 1) {
        return ["" + key[0] + suffix + "=" + value];
      } else {
        joinedKey = key[0];
        ref = key.slice(1);
        for (i = 0, len = ref.length; i < len; i++) {
          path = ref[i];
          joinedKey += "[" + path + "]";
        }
        return ["" + joinedKey + suffix + "=" + value];
      }
    };

    return Json;

  })();

}).call(this);

(function() {
  Locflow.Encoding.QueryString = (function() {
    function QueryString(query) {
      this.query = query.replace('?', '');
    }

    QueryString.prototype.toJson = function() {
      return this.generateNestedMap(this.generateFlatMap());
    };

    QueryString.prototype.isValid = function() {
      var flatMap;
      flatMap = this.generateFlatMap();
      return Object.keys(flatMap).length > 0;
    };

    QueryString.prototype.generateNestedMap = function(flatMap) {
      var i, key, len, nested, nestedPath, ref;
      nested = {};
      ref = Object.keys(flatMap);
      for (i = 0, len = ref.length; i < len; i++) {
        key = ref[i];
        nestedPath = this.findNestedPath(key);
        this.assignNestedValue(nested, nestedPath, flatMap[key]);
      }
      return nested;
    };

    QueryString.prototype.findNestedPath = function(key) {
      var pathRegex;
      pathRegex = /^[^\[\]]+(\[[^\[\]]*\])*$/;
      if (!key.match(pathRegex)) {
        return [key];
      }
      return key.split('[').map(function(path) {
        return path.replace(']', '').trim();
      }).filter(function(step) {
        return step.trim() !== '';
      });
    };

    QueryString.prototype.assignNestedValue = function(map, path, value) {
      var i, index, len, originalMap, step;
      originalMap = map;
      for (index = i = 0, len = path.length; i < len; index = ++i) {
        step = path[index];
        if (!map[step]) {
          map[step] = {};
        }
        if (index === path.length - 1) {
          map[step] = value;
        } else {
          map = map[step];
        }
      }
      return originalMap;
    };

    QueryString.prototype.generateFlatMap = function() {
      var i, len, pairs, queryPart, queryParts;
      queryParts = this.query.split('&');
      pairs = {};
      for (i = 0, len = queryParts.length; i < len; i++) {
        queryPart = queryParts[i];
        this.mergeKeyValuePair(pairs, this.splitKeyValue(queryPart));
      }
      return pairs;
    };

    QueryString.prototype.mergeKeyValuePair = function(pairs, arg) {
      var key, ref, value;
      ref = arg != null ? arg : {}, key = ref.key, value = ref.value;
      if (!(key && value)) {
        return pairs;
      }
      if (pairs[key] && Array.isArray(pairs[key])) {
        return pairs[key].push(value);
      } else if (pairs[key]) {
        return pairs[key] = [pairs[key], value];
      } else {
        return pairs[key] = /\[\]$/.test(key) ? [value] : value;
      }
    };

    QueryString.prototype.splitKeyValue = function(queryPart) {
      var values;
      values = queryPart.split('=');
      if (values.length !== 2) {
        return;
      }
      return {
        key: values[0],
        value: decodeURIComponent(values[1])
      };
    };

    return QueryString;

  })();

}).call(this);

//# sourceMappingURL=locflow.js.map
