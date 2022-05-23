import time
from bs4 import BeautifulSoup
from seleniumwire import webdriver
from webdriver_manager.chrome import ChromeDriverManager

chromeOptions = webdriver.ChromeOptions()
chromeOptions.add_argument("--headless")

wire_options = {
    'request_storage': 'memory',
    'request_storage_max_size': 100  # Store no more than 100 requests in memory
}

#do the scrape
def get_pbp_from_website(url):
  
  #opening and closing driver each scrape
  #(a) this prevents zombie drivers from slowing down system
  #(b) makes dealing with errors easier (if it doesn't find anything, close at the end)
  #(c) navigating to one page, scraping, then going to another to scrape wasn't reliable
  
  driver = webdriver.Chrome('/home/ben/.wdm/drivers/chromedriver/101.0.4951.41/linux64/chromedriver', options = chromeOptions, seleniumwire_options = wire_options)
  
  # IF YOU NEED A NEW DRIVER, RUN THIS ONCE
  # driver = webdriver.Chrome(ChromeDriverManager().install(), options = chromeOptions)

  driver.get(url)
  time.sleep(12)
  
  for request in driver.requests:
    if 'realStartTime' in request.path:
      text = request.response.body
      driver.quit()
      return text
  
  #if we made it this far without finding something, close driver
  driver.quit()

