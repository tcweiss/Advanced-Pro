

library(tidyverse)
library(quantmod)
library(tidyquant)


# Get tickers and names of SP500.
sp500 <- tq_index("SP500") %>%
            select(symbol) %>%
            unique() %>%
            mutate(symbol = gsub("\\.", "-", symbol)) %>%
            pull(symbol) %>%
            suppressMessages()


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




# Get stock data.
get_prices(c('MSFT','BRK-B'),
           from_date = "2019-01-01",
           to_date = "2020-12-31",
           ohlc = "Close") %>% head()










