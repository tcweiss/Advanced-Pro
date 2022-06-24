
# Set your working directory to the 'portfolio_selection' folder.
# setwd("~/Desktop/Uni/Advanced Programming/Code/Advanced-Pro/portfolio_selection")

# Load functions and packages.
source("code/functions.R")
library(tidyverse)
library(magrittr)
library(tidyquant)
library(arrow)
library(qs)

#####################
##   PREPARE DATA  ##
#####################

# Get tickers and names of SP500.
SP500 <- tq_index("SP500") %>%
  select(symbol, "name" = company) %>%
  unique() %>%
  mutate(symbol = gsub("\\.", "-", symbol)) %>%
  suppressMessages()

# Split up into first 300 observations and 301 onward (API only allows for 300
# observations at a time).
SP500_one <- SP500[1:300,]
SP500_two <- SP500[301:nrow(SP500),]

# Get stock price data for last 12 months using both subsets, then combine to
# single dataframe. CAUTION: Wait at least five minutes or use different VPN
# after running the first line. If you don't do this and immediately run the
# second line afterwards, the API will not return all requested stocks.
prices_1 <- get_prices(SP500_one$symbol)
prices_2 <- get_prices(SP500_two$symbol)
prices <- rbind(prices_1, prices_2)

# Join 'prices' with 'SP500' to add company name, then round prices
# for better visibility later on, finally reorder columns.
prices <- left_join(prices, SP500, by = "symbol") %>%
                  mutate(close = round(close, 2)) %>%
                  select(symbol, name, date, close)

# Create named vector with company names (used for dropdown menu in app).
choices_prices <- unique(prices$symbol)
names(choices_prices) <- unique(prices$name)
choices_prices <- choices_prices[sort(names(choices_prices))]

# Store different index tickers (used as benchmark in app).
bench   <- c("^GSPC", # SP500
             "^DJI",  # Dow Jones
             "^IXIC", # Nasdaq Composite
             "CL=F",  # Crude Oil
             "GC=F")  # Gold)

# Get index price price data for last 12 months. Then remove ^ from tickers, add
# new variable containing full index names, round prices, reorder columns.
bench <- get_prices(bench) %>%
              mutate(symbol = str_remove_all(symbol, "\\^"),
                     "name" = case_when(symbol == "GSPC" ~ "SP500",
                                         symbol == "DJI" ~ "Dow Jones Industrial Average",
                                         symbol == "IXIC" ~ "Nasdaq Composite",
                                         symbol == "CL=F" ~ "Crude Oil",
                                         symbol == "GC=F" ~ "Gold"),
                     close = round(close, 2)) %>%
              filter(is.na(close) == FALSE) %>%
              dplyr::select(symbol, name, date, close)

# Create named vector with benchmark names (used for dropdown menu in app).
choices_bench <- unique(bench$symbol)
names(choices_bench) <- unique(bench$name)
choices_bench <- choices_bench[sort(names(choices_bench))]

# Create dataframe with stock returns (used to create table of monthly winners
# and losers in app).
prices_wl <- prices %>%
                group_by(name, symbol) %>%
                tq_transmute(select     = close,
                             mutate_fun = periodReturn,
                             period     = "monthly",
                             col_rename = "Return (%)") %>%
                ungroup() %>%
                filter(date == max(date)) %>%
                mutate(`Return (%)` = round(100*`Return (%)`, 1)) %>%
                select("Ticker" = symbol, "Name" = name, `Return (%)`)

#####################
##     SAVE DATA   ##
#####################

# Save benchmark prices, stock prices, stock returns and named vectors in app's
# data folder. Note that feather/qs reduce the write and read time, but it does
# not affect the data itself.
write_feather(bench, "app_data/bench.feather")
write_feather(prices, "app_data/prices.feather")
write_feather(prices_wl, "app_data/prices_wl.feather")
qsave(choices_prices, "app_data/choices_prices.qs")
qsave(choices_bench, "app_data/choices_bench.qs")




