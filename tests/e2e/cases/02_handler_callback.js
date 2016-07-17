module.exports = {
  'Invokes the initial location handler': function (browser) {
    browser
      .url(browser.launch_url + '/02/home.html')
      .waitForElementVisible('body', 1000)
      .assert.containsText('#page-title', 'Home page updated')
      .assert.containsText('.messages', 'First message!')
      .click('#add-message')
      .assert.containsText('.messages', 'Generated message 1')
      .click('#add-message')
      .assert.containsText('.messages', 'Generated message 2');
  },
  'Invokes route handler callback': function(browser) {
    browser
      .click('a[href="/02/about.html"]')
      .pause(500)
      .assert.containsText('#page-title', 'About page updated');
  },
  'Goes back in history with existing handlers': function(browser) {
    browser
      .back()
      .click('#add-message')
      .assert.containsText('.messages', 'Generated message 3')
      .forward();
  },
  'Invokes multiple route handlers': function(browser) {
    browser
      .click('a[href="/02/contact.html"]')
      .pause(500)
      .elements('css selector', '.message', function(result) {
        browser.assert.equal(result.value.length, 2);
      })
      .end();
  }
};
