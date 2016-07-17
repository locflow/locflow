module.exports = {
  'Back and forth' : function (browser) {
    browser
      .url(browser.launch_url + '/01/home.html')
      .waitForElementVisible('body', 1000)
      .assert.containsText('#page-title', 'Home page')
      .click('a[href="/01/about.html"]')
      .pause(500)
      .assert.containsText('#page-title', 'About page')
      .back()
      .assert.containsText('#page-title', 'Home page')
      .forward()
      .assert.containsText('#page-title', 'About page')
      .back()
      .assert.containsText('#page-title', 'Home page')
      .end();
  }
};
