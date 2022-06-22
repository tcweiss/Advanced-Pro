

############################################################################################
####### A shiny app for monitoring a stock portfolio and comparing stock performance #######
############################################################################################

# Set your working directory to the 'portfolio_selection' folder.
# setwd("~/Desktop/Uni/Advanced Programming/Code/Advanced-Pro/portfolio_selection")

# Load functions and packages.
suppressPackageStartupMessages(
c(library(shiny),
library(shinyWidgets),
library(shinythemes),
library(PerformanceAnalytics),
library(tidyquant),
library(tidyverse),
library(magrittr),
library(reactable),
library(arrow),
library(bslib),
library(qs),
library(timetk),
library(dygraphs),
library(PortfolioAnalytics)))
source("code/functions.R")

# Load data.
bench <- read_feather("app_data/bench.feather")
prices <- read_feather("app_data/prices.feather")
prices_wl <- read_feather("app_data/prices_wl.feather")
choices_prices <- qread("app_data/choices_prices.qs")
choices_bench <- qread("app_data/choices_bench.qs")


#######################################
####### A shiny app development #######
#######################################

# -----------------------------------------------------
# USER INTERFACE
#-------------------------------------------------------

ui <- navbarPage("Investing@HSG", theme = bs_theme(bootswatch = "lux"),

      # CSS tag do remove "Select All button from dropdown menu".
      tags$head(tags$style(HTML(
      ".bs-select-all {
        display: none;
      }"
      ))),
      tags$head(tags$style(type = "text/css", "#table_lose th {display:none;}")),


      tabPanel("Market Info",

      fluidRow(
        column(3,
               wellPanel(
                 pickerInput( # Pick stocks.
                   inputId = "stocks",
                   label = h6("Stocks"),
                   choices = choices_prices,
                   selected = prices$symbol[prices$symbol %in% c("AAPL", "NFLX", "CVX", "AMZN", "IBM")],
                   options = pickerOptions(title = "Pick a stock...", actionsBox = TRUE, liveSearch = TRUE),
                   multiple = TRUE),
                 pickerInput( # Pick benchmark.
                   inputId = "benchmark",
                   label = h6("Benchmarks"),
                   choices = choices_bench,
                   selected = bench$symbol[bench$symbol == c("DJI")],
                   options = pickerOptions(title = "Pick a benchmark...", actionsBox = TRUE),
                   multiple = TRUE),
                 fluidRow(
                   column(6,
                      radioButtons( # Pick time period.
                        inputId = "period",
                        label = h6("Period"),
                        choices = list("1 month" = 1, "3 months" = 3, "6 months" = 6, "12 months" = 12, "YTD" = 100),
                        selected = 12)
                      ),
                   column(6,
                      radioButtons(  # Choose price transformation.
                        inputId = "standard",
                        label = h6("Price Scale"),
                        choices = list("Absolute" = 1, "Standardized" = 2),
                        selected = 2)
                      )
                   )
                 )
               ),
        column(9,
               fluidRow(dygraphOutput("plot", width = "1050px"))
               )
        ),
      br(),
      fluidRow(
        column(4,
               h6("Top Winners & Losers"),
               fluidRow(
                  reactableOutput("table_win", width = "400px")),
               fluidRow(
                 reactableOutput("table_lose",  width = "400px"))),
        column(6,
               reactableOutput("table", width = "700px"))
      )
    ),





    tabPanel("Portfolio Builder",

             fluidRow(
               column(4,
                      textInput(
                        inputId = "forecast",
                        label = "Interested in expert opinions? Scrape analyst forecasts from CNN Money!",
                        #value = "TSLA",
                        placeholder = "Enter a valid SP500 ticker..."),

                      ),
               column(1),
               column(4,
                      pickerInput( # Pick stocks.
                        inputId = "stocks_pf",
                        label = "Choose multiple stocks to get optimal weights",
                        choices = choices_prices,
                        #selected = prices$symbol[prices$symbol %in% c("AAPL", "NFLX", "CVX")],
                        options = pickerOptions(title = "Pick stocks...", actionsBox = TRUE, liveSearch = TRUE),
                        multiple = TRUE)
                      ),
               column(2),


             ),
             fluidRow(
               column(4,
                      dygraphOutput("forecast_plot"),
                      br(),
                      br(),
                      htmlOutput("forecast_msg")
               ),
               column(1),
               column(4,
                      dygraphOutput("pf_lineplot"),
                      br(),
                      br(),
                      textOutput("pf_msg")),
               column(2,
                      reactableOutput("pf_weights", width = "200px"))
               )
    )
)



# -----------------------------------------------------
# SERVER
#------------------------------------------------------

server <- function(input, output) {

  # Server logic based on user input.
  observeEvent(c(input$period, input$stocks, input$benchmark, input$standard), {

    # Subset to tickers chosen by user.
    prices_chart <- rbind(prices, bench) %>%
        filter(symbol %in% c(input$stocks, input$benchmark))

    # Subset by month/YTD period.
    if (input$period %in% c(1, 3, 6, 12)) {
      x <- as.integer(input$period)
      prices_chart <- prices_chart %>%
        filter(date >= today()-months(x))
    }
    if (input$period == 100) {
      prices_chart <- prices_chart %>%
        filter(year(date) == year(today()))
    }

    # Use absolute/standardized prices.
    if (input$standard == 1) {
      prices_chart <- prices_chart
    }
    if (input$standard == 2) {
      prices_chart <- prices_chart %>%
        group_by(symbol) %>%
        mutate(close = round(100*close/close[date==min(date)],1)) %>%
        ungroup()
    }

    # Create line plot.
    output$plot <- renderDygraph({

            if (length(input$stocks) == 0 & length(input$benchmark) == 0)
              {validate("Please choose stocks or benchmarks to display chart.")}

            prices_chart %>%
               select(date, name, close) %>%
               pivot_wider(., names_from = name, values_from = close) %>%
               tk_xts(., date_var = "date", silent = TRUE) %>%
               dygraph() %>%
               dyLegend(show = "onmouseover", labelsSeparateLines = TRUE, width = 100) %>%
               dyRangeSelector() %>%
                suppressWarnings() %>%
                suppressMessages()

    })

    # Create table displaying summmary statistics.
    output$table <- renderReactable({

      if (length(input$stocks) == 0 & length(input$benchmark) == 0)
        {validate("  ")}

      prices_chart %>%
        filter(symbol %in% c(input$stocks, input$benchmark)) %>% # Use same as in chart.
        group_by(name, symbol) %>%
        tq_transmute(select = close,
                     mutate_fun = periodReturn,
                     period = "monthly",
                     col_rename = "Ra") %>%
        mutate("Median" = round(100*median(Ra), 1),
               "Volatility" = round(100*sd(Ra), 1),
               "Minimum" = round(100*min(Ra), 1),
               "Maximum" = round(100*max(Ra), 1)) %>%
        ungroup() %>%
        select("Name" = name, "Ticker" = symbol,
               Median, Volatility, Minimum, Maximum) %>%
        unique() %>%
        reactable(showSortIcon = TRUE,
                  style = list(fontSize = "13px"),
                  defaultPageSize = 5,
                  columns = list(Name = colDef(minWidth = 200),
                                 Ticker = colDef(minWidth = 100),
                                 Median = colDef(minWidth = 100),
                                 Volatility = colDef(minWidth = 100),
                                 Minimum = colDef(minWidth = 100),
                                 Maximum = colDef(minWidth = 100)),
                  defaultColDef = colDef(align = "center"))

    })

  })


  # Create table with last month's top winners. The function turn negative values
  # red and positive ones green.
  output$table_win <- renderReactable({
                        prices_wl %>%
                          arrange(desc(`Return (%)`)) %>%
                          head(3) %>%
                          reactable(
                            style = list(fontSize = "12px"),
                            columns = list(
                            Ticker = colDef(maxWidth = 70),
                            Name = colDef(maxWidth = 300),
                            `Return (%)` = colDef(maxWidth = 90,
                              style = function(`Return (%)`) {
                                if (`Return (%)` > 0) {
                                  color <- "#008000"
                                } else if (`Return (%)` < 0) {
                                  color <- "#e00000"
                                } else {
                                  color <- "#777"
                                }
                                list(color = color, fontWeight = "bold")
                              })))

  })

  # Same code as above, but sorting returns in ascending order to get last
  # month's top losers.
  output$table_lose <- renderReactable({
                        prices_wl %>%
                          arrange(`Return (%)`) %>%
                          head(3) %>%
                          reactable(
                            style = list(fontSize = "12px"),
                            columns = list(Ticker = colDef(maxWidth = 70),
                            Name = colDef(maxWidth = 300),
                            `Return (%)` = colDef(maxWidth = 90,
                               style = function(`Return (%)`) {
                                  if (`Return (%)` > 0) {
                                    color <- "#008000"
                                  } else if (`Return (%)` < 0) {
                                    color <- "#e00000"
                                  } else {
                                    color <- "#777"
                                  }
                                  list(color = color, fontWeight = "bold")
                                })))

  })


  # Create forecast plot
  forecast_plot_msg <- reactive({
    req(input$forecast %in% choices_prices)
    ticker <- as.character(input$forecast)
    get_forecasts_plot(ticker)

  })

  output$forecast_plot <- renderDygraph({

    if (length(forecast_plot_msg()) == 0)
      {validate("Please enter a valid SP500 ticker.")}

    forecast_plot_msg()[[1]]
    })
  output$forecast_msg <- renderUI({

    if (length(forecast_plot_msg()) == 0)
    {validate("Please enter a valid SP500 ticker.")}

    if (length(forecast_plot_msg()) == 0)
    {validate("   ")}

     HTML(forecast_plot_msg()[[2]])
    })



 # Get optimal portfolio weights.
  wts <- reactive({

      req(length(input$stocks_pf) >= 2)

      unlist(input$stocks_pf) %>%
              get_weights()
  })

  #Use optimal weights to create barplot.
  output$pf_weights <- renderReactable({

    if (length(wts()) == 0)
      {validate("    ")}

                       tibble("Stock" = names(wts()),
                               "Weight" = wts()) %>%
                        arrange(desc(Weight)) %>%
                        reactable()
    })

  # Compute portfolio gain over five years.
  gain <- reactive({

    req(input$stocks_pf, wts())

    rets <- as.vector(unlist(input$stocks_pf)) %>%
              get_prices(.,
              from_date = (today()-years(5)),
              to_date = today()) %>%
            pivot_wider(names_from = symbol,
                       values_from = close) %>%
            tk_xts(., silent = TRUE) %>%
            Return.calculate() %>%
            na.approx()

    # Compute percentage gain.
    ((Return.portfolio(rets, wts())+1) %>%
               cumprod(.)-1)*100

  })

  # Plot portfolio gain.
  output$pf_lineplot <- renderDygraph({

    if (length(gain()) == 0)
      {validate("Please pick some stocks from the dropdown menu.")}

    # Plot the gain.
    dygraph(gain(), main = "Portfolio Gain (in %)") %>%
      dySeries("portfolio.returns", label = "Gain", color = "black") %>%
      dyRangeSelector()

  })

  # Create message for user.
  output$pf_msg <- renderText({

    if (length(gain()) == 0)
      {validate("   ")}

    if (tail(gain()[,1],1) > 0) {
      paste("Wow! If you invested 100$ five years ago, your portfolio would now be worth",
            paste0((100+round(tail(gain()[,1],1), 2)), "$."))
    } else {
      paste("Oops! If you invested 100$ five years ago, your portfolio would now be worth",
            paste0((100+round(tail(gain()[,1],1), 2)), "$."))
    }
  })

}


# Run the application
shinyApp(ui = ui, server = server)
