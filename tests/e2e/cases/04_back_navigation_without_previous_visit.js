module.exports = {
  'Visits home page': function(browser) {
    browser
      .url(browser.launch_url + '/04/home.html')
      .waitForElementVisible('body', 1000)
      .assert.containsText('body', 'Home page');
  },
  'Visits about page and refreshes': function(browser) {
    browser
      .click('a[href="/04/about.html"]')
      .pause(500)
      .assert.containsText('body', 'About page')
      .refresh()
  },
  'Visits home page and sees content': function(browser) {
    browser
      .back()
      .pause(500)
      .assert.containsText('body', 'Home page')
      .end();
  }
};
