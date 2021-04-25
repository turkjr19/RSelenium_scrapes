#----------------------------StartUp----------------------------------#
# Determine whether  requried libraries are installed, If not, install the libraries
# required to run the script
foo <- function(x) {
  for(i in x) {
    # require returns TRUE invisibly if it was able to load package
    if(! require(i, character.only = TRUE)) {
      # if package was not able to be loaded then re-install
      install.packages(i, dependencies = TRUE)
      # load package after installing
      require(i, character.only = TRUE)
    }
  }
}

# Then install/load packages...
foo(c('tidyverse', 'wdman', 'RSelenium', 'xml2', 'selectr', 'lubridate',
      'googlesheets4', 'rvest'))

#----------------------------Pipeline----------------------------------#
# using wdman to start a selenium server
selServ <- selenium(
  port = 4444L,
  version = 'latest',
  chromever = '90.0.4430.24', # set this to a chrome version that's available on your machine
)

# using RSelenium to start a chrome on the selenium server
remDr <- remoteDriver(
  remoteServerAddr = 'localhost',
  port = 4444L,
  browserName = 'chrome'
)

# open a new Tag on Chrome
remDr$open()

# navigate to the site you wish to analyze
report_url <- ("https://hockey.instatscout.com/login")
remDr$navigate(report_url)

# send username
username <- remDr$findElement(using = "name", value = "email")
username$sendKeysToElement(list("claircornish@gmail.com"))

# send password
passwd <- remDr$findElement(using = "name", value = "pass")
passwd$sendKeysToElement(list("1afc0"))

# submit
loginButton <- remDr$findElement(using = "name", "commit")
loginButton$clickElement()


#--------------------Go to a players page-----------------------#

remDr$navigate("https://hockey.instatscout.com/players/580731/games")
remDr$getCurrentUrl

# get all data before scraping table
# go to the gear button and select it
gearButton <- remDr$findElement("css", "button.styled__Button-sc-1bqv7p5-1.kNkBgv")
gearButton$clickElement()  

# click on all the categories
# need to code a loop or figure out how to call specific categories
xGButton <- remDr$findElement("css", "span.CheckBoxLabel-sc-1fz53c2.fNDZaj")
xGButton$clickElement()

xGButton <- remDr$findElement("css", "span.CheckBoxLabel-sc-1fz53c2.fNDZaj")
xGButton$clickElement()

xGButton <- remDr$findElement("css", "span.CheckBoxLabel-sc-1fz53c2.fNDZaj")
xGButton$clickElement()

xGButton <- remDr$findElement("css", "span.CheckBoxLabel-sc-1fz53c2.fNDZaj")
xGButton$clickElement()

xGButton <- remDr$findElement("css", "span.CheckBoxLabel-sc-1fz53c2.fNDZaj")
xGButton$clickElement()

xGButton <- remDr$findElement("css", "span.CheckBoxLabel-sc-1fz53c2.fNDZaj")
xGButton$clickElement()

xGButton <- remDr$findElement("css", "span.CheckBoxLabel-sc-1fz53c2.fNDZaj")
xGButton$clickElement()

xGButton <- remDr$findElement("css", "span.CheckBoxLabel-sc-1fz53c2.fNDZaj")
xGButton$clickElement()

xGButton <- remDr$findElement("css", "span.CheckBoxLabel-sc-1fz53c2.fNDZaj")
xGButton$clickElement()

xGButton <- remDr$findElement("css", "span.CheckBoxLabel-sc-1fz53c2.fNDZaj")
xGButton$clickElement()

xGButton <- remDr$findElement("css", "span.CheckBoxLabel-sc-1fz53c2.fNDZaj")
xGButton$clickElement()

xGButton <- remDr$findElement("css", "span.CheckBoxLabel-sc-1fz53c2.fNDZaj")
xGButton$clickElement()

# click ok to return to player stats page with selections from gear menu
okButton <- remDr$findElement("css", "input.PopupBtn-sc-1uzi0py.dViJzk")
okButton$clickElement()

# read in the page
readPlayerPage <- read_html(remDr$getPageSource()[[1]])

# get the stats
get_stats <- readPlayerPage %>% 
  html_nodes("table") %>% 
  .[[1]] %>% 
  html_table()

