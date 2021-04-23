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
      'googlesheets4'))

# get today's date to use as necessary
date <- as_tibble(Sys.Date()) %>% 
  mutate(date = as.character(value, format="%B %d"))

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
report_url <- "https://app.powerbi.com/view?r=eyJrIjoiMjU2MmEzM2QtNDliNS00ZmIxLWI5MzYtOTU0NTI1YmU5MjQ2IiwidCI6IjUyZDdjOWMyLWQ1NDktNDFiNi05YjFmLTlkYTE5OGRjM2YxNiJ9"
remDr$navigate(report_url)

#--------------------Suspected Cases by Department Pivot-----------------------#

# fetch the site source in XML
pivot_data_table <- read_html(remDr$getPageSource()[[1]]) %>%
  querySelector("div.pivotTableContainer")

col_headers <- pivot_data_table %>%
  querySelectorAll("div.columnHeaders div.pivotTableCellWrap") %>%
  map_chr(xml_text)

rownames <- pivot_data_table %>%
  querySelectorAll("div.rowHeaders div.pivotTableCellWrap") %>%
  map_chr(xml_text)

pivottable_data <- pivot_data_table %>%
  querySelectorAll("div.bodyCells div.pivotTableCellWrap") %>%
  map(xml_parent) %>%
  unique() %>%
  map(~ .x %>% querySelectorAll("div.pivotTableCellWrap") %>% map_chr(xml_text)) %>%
  setNames(col_headers) %>%
  bind_cols() %>% 
  add_column(situation = c("Reported Cases", "Deaths")) %>% 
  select(situation, everything())

# save scrape as data frame
weeklyCaseData <- pivottable_data
weeklyCaseData <- weeklyCaseData[, c(1, 8, 7, 6, 5, 4, 3, 2)]


# # add a sheet to google sheet named weeklyCaseData with today's date
sheet_write(weeklyCaseData, noahCovid, "weeklyCases")


#--------------------Cases per 100,000----------------------#

# Makes sure to click on check box for 7 day then
# Right-click on trend chart and choose `show as table`

# fetch the site source in XML
pivot_data_table_2 <- read_html(remDr$getPageSource()[[1]]) %>%
  querySelector("#pvExplorationHost > div > div > exploration > div > explore-canvas-modern > div > div.canvasFlexBox > div > div.displayArea.disableAnimations.fitToScreen > div.visualContainerHost > visual-container-repeat > visual-container-modern:nth-child(43) > transform > div > div:nth-child(4) > div > detail-visual-modern > div > visual-modern > div > div")

col_headers_2 <- pivot_data_table_2 %>%
  querySelectorAll("div.columnHeaders div.pivotTableCellWrap") %>%
  map_chr(xml_text) %>% 
  str_trim("right")

rownames_2 <- pivot_data_table_2 %>%
  querySelectorAll("div.pivotTable div.rowHeaders div.pivotTableCellWrap") %>%
  map_chr(xml_text)

pivottable_data_2 <- pivot_data_table_2 %>%
  querySelectorAll("div.bodyCells div.pivotTableCellWrap") %>%
  map(xml_parent) %>%
  unique() %>%
  map(~ .x %>% querySelectorAll("div.pivotTableCellWrap") %>% map_chr(xml_text)) %>%
  setNames(col_headers_2) %>%
  bind_cols()

municipality <- as.data.frame(rownames_2) %>% 
  rename(Municipality = "rownames_2")

# produce final data frame to write to csv
casesPer_df <- municipality %>%
  bind_cols(pivottable_data_2) %>% 
  arrange(-desc(municipality)) %>% 
  filter(Municipality != "Durham Region") %>%
  select(Municipality, !!date$date := "Cases Per 100,000")

# add a sheet to google sheet named casesPer with today's date
sheet_write(casesPer_df, noahCovid, "casesPer")


#--------------------Total Cases by Municipality----------------------#

# Right-click on total cases trend chart and choose `show as table`

# fetch the site source in XML
pivot_data_table_3 <- read_html(remDr$getPageSource()[[1]]) %>%
  querySelector("#pvExplorationHost > div > div > exploration > div > explore-canvas-modern > div > div.canvasFlexBox > div > div.displayArea.disableAnimations.fitToScreen > div.visualContainerHost > visual-container-repeat > visual-container-modern:nth-child(5) > transform > div > div:nth-child(4) > div > detail-visual-modern > div > visual-modern > div > div")

col_headers_3 <- pivot_data_table_3 %>%
  querySelectorAll("div.columnHeaders div.pivotTableCellWrap") %>%
  map_chr(xml_text) %>% 
  str_trim("right")

rownames_3 <- pivot_data_table_3 %>%
  querySelectorAll("div.pivotTable div.rowHeaders div.pivotTableCellWrap") %>%
  map_chr(xml_text)

pivottable_data_3 <- pivot_data_table_3 %>%
  querySelectorAll("div.bodyCells div.pivotTableCellWrap") %>%
  map(xml_parent) %>%
  unique() %>%
  map(~ .x %>% querySelectorAll("div.pivotTableCellWrap") %>% map_chr(xml_text)) %>%
  setNames(col_headers_3) %>%
  bind_cols()

municipality3 <- as.data.frame(rownames_3) %>% 
  rename(Municipality = "rownames_3")

# produce final data frame to write to csv
totalCases_df <- municipality3 %>%
  bind_cols(pivottable_data_3) %>% 
  arrange(-desc(municipality))

# add a sheet to google sheet named totalCases with today's date
sheet_write(totalCases_df, noahCovid, "totalCases")


#--------------------Total VoC Cases by Municipality----------------------#

# Right-click on total cases trend chart and choose `show as table`

# fetch the site source in XML
pivot_data_table_4 <- read_html(remDr$getPageSource()[[1]]) %>%
  querySelector("#pvExplorationHost > div > div > exploration > div > explore-canvas-modern > div > div.canvasFlexBox > div > div.displayArea.disableAnimations.fitToScreen > div.visualContainerHost > visual-container-repeat > visual-container-modern:nth-child(75) > transform > div > div:nth-child(4) > div > detail-visual-modern > div > visual-modern > div > div")


col_headers_4 <- pivot_data_table_4 %>%
  querySelectorAll("div.columnHeaders div.pivotTableCellWrap") %>%
  map_chr(xml_text) %>% 
  str_trim("right")

rownames_4 <- pivot_data_table_4 %>%
  querySelectorAll("div.pivotTable div.rowHeaders div.pivotTableCellWrap") %>%
  map_chr(xml_text)

pivottable_data_4 <- pivot_data_table_4 %>%
  querySelectorAll("div.bodyCells div.pivotTableCellWrap") %>%
  map(xml_parent) %>%
  unique() %>%
  map(~ .x %>% querySelectorAll("div.pivotTableCellWrap") %>% map_chr(xml_text)) %>%
  setNames(col_headers_4) %>%
  bind_cols()

municipality4 <- as.data.frame(rownames_4) %>% 
  rename(Municipality = "rownames_4")

# produce final data frame to write to csv
totalVOCCases_df <- municipality4 %>%
  bind_cols(pivottable_data_4) %>% 
  arrange(-desc(Municipality))


# add a sheet to google sheet named totalCases with today's date
sheet_write(totalVOCCases_df, noahCovid, "VOC")


# ******* Google sheet code below *******
# create new Google sheet
# code below has to be done first and then just use the overwrite code
#gs4_create(name = "noahCovid", sheets = "blank")

# read in existing Google workbook sheet link
# code below has to be done second and then just use the add a sheet code
#noahCovid <- ("https://docs.google.com/spreadsheets/d/1eiRjowgqIPwJ_iKR6S9GfGSeqpZRZoDFJQqfdqei5iQ/edit?usp=sharing")









