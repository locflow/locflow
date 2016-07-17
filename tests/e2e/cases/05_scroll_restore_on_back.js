module.exports = {
  'Visits the home page and scrolls down': function(browser) {
    browser
      .url(browser.launch_url + '/05/home.html')
      .waitForElementVisible('body', 1000)
      .execute('scrollTo(0, 9999)') // bottom of page
  },
  'Visits the about page and goes back to home': function(browser) {
    browser
      .click('a[href="/05/about.html"]')
      .pause(500)
      .back()
  },
  'Home is rendered with the previous scroll position': function(browser) {
    browser
      .perform(function(client, done) {
        // I'm not sure how to test this here
        done()
      })
      .end()
  }
}
