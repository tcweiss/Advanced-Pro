
#####################
##      SETUP     ###
#####################

# Make sure to set your working directory to the 'portfolio_selection' folder.
#setwd("~/Desktop/Uni/Advanced Programming/Code/Advanced-Pro/portfolio_selection")

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

# Import data from 'app_data' folder.
bench <- read_feather("app_data/bench.feather")
prices <- read_feather("app_data/prices.feather")
prices_wl <- read_feather("app_data/prices_wl.feather")
choices_prices <- qread("app_data/choices_prices.qs")
choices_bench <- qread("app_data/choices_bench.qs")



#######################
##   SHINY WEB APP   ##
#######################

# ------------------------------------------------------
# USER INTERFACE
#-------------------------------------------------------

# Use the navbarPage format for main page
# Define title and use color theme 'lux'
ui <- navbarPage(title = "Investing@HSG", theme = bs_theme(bootswatch = "lux"),

      # CSS tag do remove 'Select All' button from dropdown menu
      tags$head(tags$style(HTML(
      ".bs-select-all {
        display: none;
      }"))),


      # Create first page.
      tabPanel(title = "Market Info",

        # Partition into first row (top half of first page)
        fluidRow(

          # Partition into a column (top left of first page)
          column(width = 3,

               # Grey panel for user input options
               wellPanel(

                   # Pick stocks from dropdown menu
                   pickerInput(
                     inputId = "stocks",
                     label = h6("Stocks"),
                     choices = choices_prices,
                     selected = prices$symbol[prices$symbol %in% c("AAPL", "NFLX", "CVX", "AMZN", "IBM")],
                     options = pickerOptions(title = "Pick a stock...", actionsBox = TRUE, liveSearch = TRUE),
                     multiple = TRUE),

                   # Pick benchmark from dropdown menu
                   pickerInput(
                     inputId = "benchmark",
                     label = h6("Benchmarks"),
                     choices = choices_bench,
                     selected = bench$symbol[bench$symbol == c("DJI")],
                     options = pickerOptions(title = "Pick a benchmark...", actionsBox = TRUE),
                     multiple = TRUE),

                   # Create another row
                   # Puts period and scale next to each other
                   fluidRow(

                     # Choose time period (left half of this row)
                     column(width = 6,
                        radioButtons(
                          inputId = "period",
                          label = h6("Period"),
                          choices = list("1 month" = 1, "3 months" = 3, "6 months" = 6, "12 months" = 12, "YTD" = 100),
                          selected = 12)
                        ),

                     # Choose price scale (right half of this row)
                     column(width = 6,
                        radioButtons(
                          inputId = "standard",
                          label = h6("Price Scale"),
                          choices = list("Absolute" = 1, "Standardized" = 2),
                          selected = 2)
                        )
                     )
                   )
               ),

          # Partition into second column (top right of first page)
          column(width = 9,

                 # Create lineplot using 'plot' object from server
                 dygraphOutput("plot", width = "1050px")
          )
        ),

        # Insert some empty space
        # Better separates upper and lower half
        br(),

        # Partition first page into another row (bottom half of first page)
        fluidRow(

          # Partition into a column (bottom left of first page)
          column(width = 4,
                 h6("Monthly Winners & Losers"),

                 # Create winner/loser tables using 'table_win' and 'table_lose' objects from server
                 reactableOutput("table_win", width = "400px"),
                 reactableOutput("table_lose",  width = "400px")
          ),

          # Partition into another column (bottom right of first page)
          column(width = 6, offset = 1,

                 # Create table with summary stats using 'table' object from server
                 h6("Monthly Return Statistics"),
                 reactableOutput("table", width = "700px"))
        )
      ),



    # Create second page.
    tabPanel("Investment Guide",

        # Partition into a row (top half of second page)
        fluidRow(

               # Partition into a first column (top left of second page)
               column(width = 4,

                      # Enter stock ticker.
                      textInput(
                        inputId = "forecast",
                        label = "Interested in expert opinions? Scrape analyst forecasts from CNN Money!",
                        placeholder = "Enter a valid SP500 ticker..."),
                      ),

               # Partition into second column
               # This is empty and separates tables better
               column(width = 1),

               # Partition into third column (top right of second page)
               column(width = 4,

                      # Pick multiple stocks.
                      pickerInput(
                        inputId = "stocks_pf",
                        label = "Choose multiple stocks to get optimal weights",
                        choices = choices_prices,
                        options = pickerOptions(title = "Pick stocks...", actionsBox = TRUE, liveSearch = TRUE),
                        multiple = TRUE)
                      ),

               # Partition into fourth column
               # Again empty to have enough space on right end
               column(width = 2),
        ),

        # Partition into row (bottom half of second page)
        fluidRow(

               # Partition into first column (bottom left of second page)
               column(width = 4,

                      # Create forecast plot
                      dygraphOutput("forecast_plot"),
                      br(),
                      br(),
                      # Create forecast message
                      htmlOutput("forecast_msg")
               ),

               # Partition into second column
               # This is empty for better separation
               column(width = 1),

               # Partition into third column (lower right/center of second page)
               column(width = 4,

                      # Create portfolio gain lineplot
                      dygraphOutput("pf_lineplot"),
                      br(),
                      br(),

                      # Create portfolio gain message
                      textOutput("pf_msg")),

               # Partition into fourth column (bottom right of second page)
               column(width = 2,
                      reactableOutput("pf_weights", width = "200px"))
           )
    )
)



# -----------------------------------------------------
# SERVER
#------------------------------------------------------

server <- function(input, output) {


  # COMPUTATIONS FOR FIRST PAGE

  # Uses input from UI to create lineplot and table with summary stats
  observeEvent(c(input$period, input$stocks, input$benchmark, input$standard), {

    # Subset to tickers chosen by user.
    prices_chart <- rbind(prices, bench) %>%
        filter(symbol %in% c(input$stocks, input$benchmark))

    # Subset to monthly period if chosen by user
    if (input$period %in% c(1, 3, 6, 12)) {

      x <- as.integer(input$period)
      prices_chart <- prices_chart %>%
        filter(date >= today()-months(x))

    }

    # Subset to YTD if chosen by user
    if (input$period == 100) {

      prices_chart <- prices_chart %>%
        filter(year(date) == year(today()))

    }

    # Use absolute price if chosen by user
    if (input$standard == 1) {

      prices_chart <- prices_chart

    }

    # Use standardized price if chosen by user
    if (input$standard == 2) {

      prices_chart <- prices_chart %>%
        group_by(symbol) %>%
        mutate(close = round(100*close/close[date==min(date)],1)) %>%
        ungroup()

    }

    # Create lineplot from adjusted data
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

    # Create table with summmary stats from adjusted data
    output$table <- renderReactable({

      if (length(input$stocks) == 0 & length(input$benchmark) == 0)
        {validate("Please choose stocks or benchmarks to display statistics.")}

      prices_chart %>%
        filter(symbol %in% c(input$stocks, input$benchmark)) %>%
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


  # Create table with last month's top winners
  output$table_win <- renderReactable({

                        # Subset data.
                        prices_wl %>%
                          arrange(desc(`Return (%)`)) %>%
                          head(3) %>%

                          # Create interactive table
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

  # Create table with last month's top winners
  output$table_lose <- renderReactable({

                        # Subset data
                        prices_wl %>%
                          arrange(`Return (%)`) %>%
                          head(3) %>%

                          # Create interactive table
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


  # COMPUTATIONS FOR SECOND PAGE

  # Use ticker entered by user to return list containing plot and message
  forecast_plot_msg <- reactive({

        # Check if correct ticker input exists
        req(input$forecast %in% choices_prices)

        # Scrape page to create plot and message
        ticker <- as.character(input$forecast)
        get_forecasts_plot(ticker)

  })


  # Use list created above to create forecast plot
  output$forecast_plot <- renderDygraph({

        # Check if list with plot and message exists, otherwise return message
        if (length(forecast_plot_msg()) == 0)
          {validate("Please enter a valid SP500 ticker.")}

        # Extract first object from list to create plot
        forecast_plot_msg()[[1]]

    })

  # Use list created create forecast message
  output$forecast_msg <- renderUI({

        # Check if list with plot and message exists, otherwise return message
        if (length(forecast_plot_msg()) == 0)
        {validate("   ")}

        # Extract second object from list to create message
        HTML(forecast_plot_msg()[[2]])

    })

  # User stock tickers chosen by user to compute optimal portfolio weights
  wts <- reactive({

        # Check if ticker input exists
        req(length(input$stocks_pf) >= 2)

        # Compute weights
        unlist(input$stocks_pf) %>%
                get_weights()
  })

  # Use weights to compute portfolio gain
  gain <- reactive({

      # Check if ticker input exists
      req(input$stocks_pf, wts())

      # Compute return of chosen stocks
      rets <- as.vector(unlist(input$stocks_pf)) %>%
        get_prices(.,
                   from_date = (today()-years(5)),
                   to_date = today()) %>%
        pivot_wider(names_from = symbol,
                    values_from = close) %>%
        tk_xts(., silent = TRUE) %>%
        Return.calculate() %>%
        na.approx()

      # Convert to returns to portfolio percentage gain
      ((Return.portfolio(rets, wts())+1) %>%
          cumprod(.)-1)*100

  })

  # Use weights to create table
  output$pf_weights <- renderReactable({

       # Check if weights object exist
       if (length(wts()) == 0)
         {validate("    ")}

       # Create dataframe and create table
       tibble("Stock" = names(wts()),
               "Weight" = wts()) %>%
       arrange(desc(Weight)) %>%
       reactable()

    })

  # Use portfolio gain to create plot
  output$pf_lineplot <- renderDygraph({

    # Check if gain object exists
    if (length(gain()) == 0)
      {validate("Please pick some stocks from the dropdown menu.")}

    # Plot the gain
    dygraph(gain(), main = "Portfolio Return (in %)") %>%
      dySeries("portfolio.returns", label = "Gain", color = "black") %>%
      dyRangeSelector()

  })

  # Use portfolio gain to create message
  output$pf_msg <- renderText({

    # Check if gain object exists.
    if (length(gain()) == 0)
      {validate("   ")}

    # Compute return on 100$ and create messsage
    if (tail(gain()[,1],1) > 0) {
      paste("Wow! If you invested 100$ five years ago, this portfolio would now be worth",
            paste0((100+round(tail(gain()[,1],1), 2)), "$."))
    } else {
      paste("Oops! If you invested 100$ five years ago, this portfolio would now be worth",
            paste0((100+round(tail(gain()[,1],1), 2)), "$."))
    }
  })

}


# -----------------------------------------------------
# COMBINE UI AND SERVER
#------------------------------------------------------

# Runs the application
shinyApp(ui, server)
