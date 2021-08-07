import time
from bs4 import BeautifulSoup
from seleniumwire import webdriver
from webdriver_manager.chrome import ChromeDriverManager

chromeOptions = webdriver.ChromeOptions()
chromeOptions.add_argument("--headless")

#do the scrape
def get_pbp_from_website(url):
  
  #opening and closing driver each scrape
  #(a) this prevents zombie drivers from slowing down system
  #(b) makes dealing with errors easier (if it doesn't find anything, close at the end)
  #(c) navigating to one page, scraping, then going to another to scrape wasn't reliable
  
  driver = webdriver.Chrome('/home/ben/.wdm/drivers/chromedriver/89.0.4389.23/linux64/chromedriver', options = chromeOptions)
  
  # IF YOU NEED A NEW DRIVER, RUN THIS ONCE
  # driver = webdriver.Chrome(ChromeDriverManager().install(), options = chromeOptions)

  driver.get(url)
  time.sleep(12)
  
  for request in driver.requests:
    if 'realStartTime' in request.path:
      text = request.response.body
      driver.close()
      return text
  
  #if we made it this far without finding something, close driver
  driver.close()

