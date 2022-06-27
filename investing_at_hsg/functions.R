

####################
##  STOCK PRICES  ##
####################

# Simple wrapper for tq_get access Yahoo API. This function prevents the API from
# reaching it's limit and returning errors, which happens if more than 300
# stocks are requested at once. Input 'x' is string or vector of strings for
# stock tickers, default today. Input 'from_date' is character or string for
# dates with format YYYY-MM-DD, default 12 months ago. Third argument 'to_date'
# same as second one, default today. Fourth argument 'ohlc' is string with
# either "Open", "High", "Low", or "Close", default Close.
get_prices <- function(x, from_date = (today()-months(12)), to_date = today(), ohlc = "close") {

  # Load dependencies.
  suppressPackageStartupMessages(
    c(require(tidyverse),
      require(magrittr),
      require(quantmod),
      require(tidyquant),
      require(timetk)))

  # Check if first argument is vector.
  if (is.vector(x) == FALSE){
    stop("Argument x requires stock tickers in vector format.")}

  # Check if first argument is character.
  if (is.character(x) == FALSE){
    stop("Argument x requires stock tickers of type character.")}

  # Check if second argument is date or character in format YYYY-MM-DD.
  tryCatch(as.Date(from_date),
           error = function(e){
             message("Error: Argument from_date requires date or string in format YYYY-MM-DD.")},
           finally = {})

  # Check if third argument is date or character in format YYYY-MM-DD.
  tryCatch(as.Date(to_date),
           error = function(e){
             message("Error: Argument to_date requires date or string in format YYYY-MM-DD.")},
           finally = {})

  # Check if fourth argument is any of the possible price specifications.
  if (any(!(all_of(ohlc) %in% c("open", "high", "low", "close")))) {
    stop("Argument ohlc must be any of 'open', 'high', 'low', 'close'.")}

  # Restrict to no more than 300 tickers at a time
  # to not exhaust API limit.
  if (length(x)>300) {

    x <- x[1:300]
    limited <- TRUE

  } else {

    limited <- FALSE

  }

  # Extract stock price using inputs. If start or end date
  # are public holidays, keep going and do not return warning.
  prices <- try(tq_get(x,
                       from = from_date,
                       to = to_date),
                silent = TRUE)[,c("symbol", "date", all_of(ohlc))] %>%
    suppressWarnings() %>%
    suppressMessages()

  # If user provides more than 300 tickers,
  # return first 300 stocks and print warning.
  if (limited == TRUE) {
    cat("Warning: API limit exceeded, returning only data for first 300 tickers.\nTo retrieve more data, please wait 15 minutes and try again.")
    prices

    # If user provides less than 300 ticker, return stocks.
  } else {
    prices
  }
}


#############################################
##  FORECASTS & RECOMMENDATIONS (SCRAPING) ##
#############################################

# Function for scraping 12-month forecasts and analysts' recommendation from CNN
# Money. Input 'x' is string or vector of strings for stock tickers. Output is
# dataframe with 5 columns: 'ticker', 'low', 'median', 'high', and 'rec'.
get_forecasts <- function(x) {

  # Load dependencies.
  suppressPackageStartupMessages(
    c(require(tidyverse),
      require(magrittr),
      require(rvest)))

  # Check if first argument is vector.
  if (is.vector(x) == FALSE){
    stop("Argument x requires stock tickers in vector format.")}

  # Check if first argument is character.
  if (is.character(x) == FALSE){
    stop("Argument x requires stock tickers of type character.")}

  # If no errors, make sure that first argument is upper case.
  x <- str_to_upper(x)

  # Create tibble (=improved dataframe).
  x <- tibble("ticker" = x)

  # Remove duplicates, convert tickers to lower case and remove special symbols,
  # create column with URLs, and add empty columns for storing results.
  preds <- x %>%
    unique() %>%
    mutate(symbol = gsub("\\.", "", ticker),
           symbol = gsub("-", "", ticker),
           symbol = str_to_lower(symbol),
           url = paste0('https://money.cnn.com/quote/forecast/forecast.html?symb=', symbol),
           text = rep(NA_character_, nrow(x)),
           median = rep(NA_real_, nrow(x)),
           high = rep(NA_real_, nrow(x)),
           low = rep(NA_real_, nrow(x)),
           recs = rep(NA_character_, nrow(x))) %>%
    dplyr::select(-symbol) %>%
    suppressMessages()

  # Set xpaths to extract HTML nodes containing
  # forecasts and recommendations.
  xp_fc <- '//*[contains(concat( " ", @class, " " ), concat( " ", "clearfix", " " )) and (((count(preceding-sibling::*) + 1) = 2) and parent::*)]//p'
  xp_rec <- '//strong[contains(concat( " ", @class, " " ), concat( " ", "wsod_rating", " " ))]'

  # Loop through URLs to get 12-month forecasts.
  for (i in 1:nrow(preds)) {

    # Scrape raw text containing forecasts.
    preds$text[i] <- preds$url[i] %>%
      read_html() %>%
      html_nodes(xpath=xp_fc) %>%
      html_text()

    # Extract median estimate using regex patterns.
    preds$median[i] <- str_remove_all(preds$text[i], "^The .{60,110} target of ") %>%
      str_replace_all(., ",", "") %>%
      str_extract(., "^[^ with]*") %>%
      as.numeric()

    # Extract high estimate using regex patterns.
    preds$high[i] <- str_remove_all(preds$text[i], "^The .{75,140} high estimate of ") %>%
      str_replace_all(., ",", "") %>%
      str_extract(., "^[^ and a]*") %>%
      as.numeric()

    # Extract low estimate using regex patterns.
    preds$low[i] <- str_remove_all(preds$text[i], "^The .{110,170} low estimate of ") %>%
      str_replace_all(., ",", "") %>%
      str_extract(., "[^\\.]*\\.[^:\\.]*") %>%
      as.numeric()

    # Scrape text containing recommendation.
    rec <- preds$url[i] %>%
      read_html() %>%
      html_nodes(xpath=xp_rec) %>%
      html_text()

    # If there is no recommendation, assign NA.
    if(length(rec) == 0) {
      preds$recs[i] <- NA_character_

      # If there is a recommendation, store it.
    } else {
      preds$recs[i] <- rec
    }
  }

  # Only keep columns containing results.
  preds %<>%
    dplyr::select(ticker, median, high, low, recs)

  # Return results.
  preds

}



#########################################
##  FORECASTS & RECOMMENDATIONS (PLOT) ##
#########################################

# Function for creating plot and a message given analyst forecast of a stock.
# Uses get_prices and get_forecasts. Input 'x' is a single string for stock
# ticker. Output is a list with two elements, first one being the plot, second
# one being the message.
get_forecasts_plot <- function(x) {

  # Load dependencies.
  suppressPackageStartupMessages(
    c(require(tidyverse),
      require(magrittr),
      require(quantmod),
      require(tidyquant),
      require(timetk),
      require(rvest),
      require(dygraphs)))

  # Check if argument is vector.
  if (is.vector(x) == FALSE){
    stop("Argument x requires stock ticker in vector format.")}

  # Check if there is only one argument.
  if (length(x) != 1){
    stop("Argument x requires a single stock ticker in vector format.")}

  # Check if first argument is character.
  if (is.character(x) == FALSE){
    stop("Argument x requires stock ticker of type character.")}

  # Create empty list to store results.
  ls <- list()

  # Get price forecasts, price history and price today, store
  # length of price history.
  price_fc <- get_forecasts(x)
  price_hist <- get_prices(x) %>%
    select(-symbol)
  price_today <- tail(price_hist$close, 1)
  len <- nrow(price_hist)

  # Expand price history by one year and fill new rows with with NA, then add
  # three more empty columns for estimate series (low/median/high).
  add <- tibble("date" = (price_hist$date + years(1)),
                "close" = rep(NA, len))

  price_hist <- rbind(price_hist, add)
  price_hist$low <- NA_real_
  price_hist$median <- NA_real_
  price_hist$high <- NA_real_

  # Loop over three estimates (low/median/high) fill empty columns with linear
  # series from today's price to estimated price.
  for(i in c("low", "median", "high")) {

    # Compute linear series from today to estimate.
    series <- seq(price_today, pull(price_fc[i]), length = len)

    # Add NA values for time past year before to get complete series over 2 years,
    # then insert into respective column.
    price_hist[i] <- c(rep(NA_real_, len), series)

  }

  # Convert dataframe to xts format and create a plot.
  ls[[1]] <- tk_xts(price_hist, silent = TRUE) %>%
                dygraph(., main = paste("Forecast for", x)) %>%
                dyAxis("x", drawGrid = FALSE) %>%
                dyShading(from = today(), to = (today()+years(1))) %>%
                dyEvent(today()) %>%
                dyLegend(show = "always", labelsSeparateLines = TRUE) %>%
                dySeries("close", label = "Historical Price", color = "black") %>%
                dySeries("high", label = "High Estimate", color = "red") %>%
                dySeries("median", label = "Median Estimate", color = "blue") %>%
                dySeries("low", label = "Low Estimate", color = "red")

  # Create message.
  ls[[2]] <- paste("The highest estimate is:", paste0(price_fc$high, "$"),
                   "<br/>The median estimate is:", paste0(price_fc$median, "$"),
                   "<br/>The lowest estimate is:", paste0(price_fc$low, "$"),
                   "<br/>The consensus among analysts is:", paste0(str_to_upper(price_fc$recs)))

  # Return list with results.
  return(ls)

}


#########################################
##       PORTFOLIO OPTIMIZATION        ##
#########################################

# Function for getting optimal portfolio weights. Uses get_prices. Input 'x is
# single string or vector of strings for stock tickers. Input 'from_date' is
# character or string for dates with format YYYY-MM-DD, default 12 months ago.
# Input 'to_date' same as second one, default today. Output is vector of
# weights, named by tickers.
get_weights <- function(x) {

  # Load dependencies.
  suppressPackageStartupMessages(
    c(require(tidyverse),
      require(magrittr),
      require(quantmod),
      require(tidyquant),
      require(timetk),
      require(rvest),
      library(PortfolioAnalytics),
      library(PortfolioAnalytics),
      library(ROI),
      library(ROI.plugin.glpk),
      library(ROI.plugin.quadprog)))

  # Check if first argument is vector.
  if (is.vector(x) == FALSE){
    stop("Argument x requires stock tickers in vector format.")}

  # Check if first argument is character.
  if (is.character(x) == FALSE){
    stop("Argument x requires stock tickers of type character.")}

  # Compute returns.
  # Step 1: Get raw data using tidyquant API.
  returns <-  get_prices(x) %>%

  # Step 2: Group by stocks to get calculation results by stock.
  group_by(symbol) %>%

  # Step 3: Calculate daily logarithmic returns for chosen stocks.
  tq_transmute(select = close,
               mutate_fun = periodReturn,
               period = "daily",
               type = "log") %>%

  # Step 4: Reshape data from wide to long format.
  pivot_wider(names_from = symbol,
              values_from = daily.returns) %>%

  # Step 5: Convert from dataframe to an xts object (=special time series
  # format).
  tk_xts(., silent = TRUE) %>%

  # Step 6: Replace NAs with interpolated values.
  na.approx()

  # Create portfolio specification (object holding relevant information for
  # portfolio optimization).
  port_spec <- portfolio.spec(colnames(returns))

  # Add constraint: "Full Investment". Effect: asset weights sum to 1.
  port_spec <- add.constraint(portfolio = port_spec,
                              type = "full_investment")

  # Add constraint: "Long Only". Effect: no short sales are allowed, so asset
  # weights are in [0,1].
  port_spec <- add.constraint(portfolio = port_spec,
                              type = "long_only")

  # Add specification: "Risk function" = "Standard Deviation". Effect: Find optimal weights
  # by minimizing standard deviation per unit of return, which is the industry standard.
  port_spec <- add.objective(portfolio = port_spec,
                             type = "risk",
                             name = "StdDev")

  # Perform portfolio optimization using return on investment as goal function.
  opt <- optimize.portfolio(returns,
                            portfolio = port_spec,
                            optimize_method = "ROI")

  # Extract and return portfolio weights from optimization.
  return(extractWeights(opt) %>%
            round(., 2))

}



