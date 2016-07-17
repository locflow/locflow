module.exports = {
  'Visits the home page with a permanent banner': function(browser) {
    browser
      .url(browser.launch_url + '/03/home.html')
      .waitForElementVisible('body', 1000)
      .click('#banner')
      .assert.containsText('#banner', '1')
  },
  'Visits the about page': function(browser) {
    browser
      .click('a[href="/03/about.html"]')
      .pause(500)
      .assert.containsText('#banner', '1')
      .click('#banner')
      .assert.containsText('#banner', '2')
      .back()
  },
  'Keeps the element on navigation backwards': function(browser) {
    browser
      .assert.containsText('#banner', '2')
      .click('#banner')
      .assert.containsText('#banner', '3')
      .forward()
  },
  'Keeps the element on navigation forwards': function(browser) {
    browser
      .assert.containsText('#banner', '3')
      .click('#banner')
      .assert.containsText('#banner', '4')
      .end();
  }
};
