#### Samuel und Sebastian Test####


# Import libraries
library(tidyverse)
library(quantmod)
library(tidyquant)
library(rvest)
library(magrittr)
library(ichimoku) # for converting xts to dataframe



################
## FUNCTIONS  ##
################

# Function for accessing APIs.
get_prices <- function(x, from_date, to_date, ohlc) {

  # If only one ticker, proceed here.
  if (length(x)==1) {

    # Extract stock price using inputs.
    prices <- try(getSymbols(x,
                             from = from_date,
                             to = to_date,
                             env = NULL,
                             auto.assign = FALSE)[,paste0(x, '.', ohlc)], silent = TRUE)

    # If no data available for selected time period,
    # return empty xts object.
    if ("try-error" %in% class(prices)) {

      len <- difftime(as.Date(to_date), as.Date(from_date)) %>%
        as.integer()

      prices <- xts(rep(NA_real_, (len+1)), seq.Date(as.Date(from_date), as.Date(to_date), by = "days"))
      names(prices) <- x

      # If data available, return data.
    } else {
      names(prices) <- x
    }
    prices

    # If more than one tickers, proceed here.
  } else {

    for (i in 1:length(x)) {

      # Extract stock price using inputs.
      price <- try(getSymbols(x[i],
                              from = from_date,
                              to = to_date,
                              env = NULL,
                              auto.assign = FALSE)[,paste0(x[i], '.', ohlc)], silent = TRUE)

      # If no data available for selected time period, return empty xts object.
      if ("try-error" %in% class(price)) {

        len <- difftime(as.Date(to_date), as.Date(from_date)) %>%
          as.integer()

        price <- xts(rep(NA_real_, (len+1)), seq.Date(as.Date(from_date), as.Date(to_date), by = "days"))
        names(price) <- x[i]

        # If data available, return data.
      } else {

        names(price) <- x[i]

      }
      if (i == 1) {
        prices <- price
      } else {
        prices <- merge(prices, price)
      }
    }
    prices
  }
}


# Function for scraping analyst forecasts and
# recommendation from CNN Money.
get_forecasts <- function(x) {

  # Create tibble.
  x <- tibble("symbol" = x)

  # Add columns with URLs, add empty columns for
  # storing results.
  preds <- x %>%
    unique() %>%
    mutate(ticker = gsub("\\.", "", symbol),
           ticker = gsub("-", "", symbol),
           ticker = str_to_lower(ticker),
           url = paste0('https://money.cnn.com/quote/forecast/forecast.html?symb=', ticker),
           text = rep(NA_character_, nrow(x)),
           median = rep(NA_real_, nrow(x)),
           high = rep(NA_real_, nrow(x)),
           low = rep(NA_real_, nrow(x)),
           recs = rep(NA_character_, nrow(x))) %>%
    select(-ticker) %>%
    suppressMessages()

  # Set xpaths to extract HTML nodes containing
  # forecasts and recommendations.
  xp_fc <- '//*[contains(concat( " ", @class, " " ), concat( " ", "clearfix", " " )) and (((count(preceding-sibling::*) + 1) = 2) and parent::*)]//p'
  xp_rec <- '//strong[contains(concat( " ", @class, " " ), concat( " ", "wsod_rating", " " ))]'

  # Get forecasts.
  for (i in 1:nrow(preds)) {

    # Scrape raw text containing forecasts.
    preds$text[i] <- preds$url[i] %>%
      read_html() %>%
      html_nodes(xpath=xp_fc) %>%
      html_text()

    # Extract median estimate.
    preds$median[i] <-  str_remove_all(preds$text[i], "^The .{60,110} target of ") %>%
      str_replace_all(., ",", "") %>%
      str_extract(., "^[^ with]*") %>%
      as.numeric()

    # Extract high estimate.
    preds$high[i] <- str_remove_all(preds$text[i], "^The .{75,140} high estimate of ") %>%
      str_replace_all(., ",", "") %>%
      str_extract(., "^[^ and a]*") %>%
      as.numeric()

    # Extract low estimate.
    preds$low[i] <- str_remove_all(preds$text[i], "^The .{110,170} low estimate of ") %>%
      str_replace_all(., ",", "") %>%
      str_extract(., "[^\\.]*\\.[^:\\.]*") %>%
      as.numeric()
  }

  # Get recommendations.
  for (i in 1:nrow(preds)) {

    # Scrape text containing forecast.
    rec <- preds$url[i] %>%
      read_html() %>%
      html_nodes(xpath=xp_rec) %>%
      html_text()

    # If there is no recommendation, assign NA.
    if(length(rec) == 0) {
      preds$recs[i] <- NA_character_

      # If there is a recommendation, assign store it.
    } else {
      preds$recs[i] <- rec
    }
  }

  # Delete helper columns.
  preds %<>%
    select(symbol, median, high, low, recs)

  # Return results.
  preds

}


# Get some data. (Note: Takes ~20mins for whole SP500. Don't do it for all
# stocks at once, or the website might refuse access.)
# get_forecasts(c('MSFT', 'BRK-B', 'TSLA', "HMST"))




###################
##  PREPARE DATA ##
###################

# Get tickers and names of SP500.
SP500 <- tq_index("SP500") %>%
  select(symbol, company) %>%
  unique() %>%
  mutate(symbol = gsub("\\.", "-", symbol)) %>%
  suppressMessages()

# Use only first 300 observations for now (API limit).
SP500 <- SP500[1:300,]

# Get stock data. Input either single string or vector of
# strings. Returns xts object.
prices <- get_prices(SP500$symbol,
                     from_date = today() - months(12),
                     to_date = today(),
                     ohlc = "Close")

# Get data on Nasdaq100 and SP500 as benchmarks.
benchmarks <- c("^NDX","^GSPC")
bench <- tq_get(benchmarks,
                get  = "stock.prices",
                from = (today()-months(12)),
                to   = today()) %>%
  select(symbol,date,close)


# Convert xts to dataframe.
prices_df <- xts_df(prices, keep.attrs = TRUE)

# Rename columns.
colnames(prices_df) <- colnames(prices_df) %>%
                            str_replace_all(., "index", "date") %>%
                            str_replace_all(., "\\.", "-")

# Reshape to long format, sort alphabetically by ticker.
prices_df %<>%
  pivot_longer(., all_of(SP500$symbol), names_to = "symbol", values_to = "close") %>%
  arrange(symbol)


# Get named vector.
names <- prices_df %>%
            select(symbol) %>%
            left_join(., SP500, by = "symbol") %>%
            unique()

choices <- names$symbol
names(choices) <- names$company


# Save in data folder.


##############################################################





















