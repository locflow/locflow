module.exports = {
  'Visits the home page and submits the form': function(browser) {
    browser
      .url(browser.launch_url + '/06/home.html')
      .waitForElementVisible('body', 1000)
      .setValue('input[name="item"]', 'my new item')
      .click('button[type=submit]')
      .pause(500)
  },
  'Sees the new item on the list': function(browser) {
    browser
      .assert.containsText('#items', 'my new item')
      .end()
  }
};
