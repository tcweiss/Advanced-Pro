############################################################################################
####### A shiny app for monitoring a stock portfolio and comparing stock performance #######
############################################################################################

# Import libraries
library(shiny)
library(shinyWidgets)
library(shinythemes)
library(plotly)
library(tidyverse)
library(tidyquant)
library(timetk)

# Load data.
prices_df <- readRDS("app_data/prices_df.RDS")
bench <- readRDS("app_data/bench.RDS")
choices <- readRDS("app_data/choices.RDS")



#######################################
####### A shiny app development #######
#######################################

# -----------------------------------------------------
# UI
#-------------------------------------------------------

ui <- fluidPage(#theme = shinytheme("cyborg"),

  # Title
  titlePanel("Investing@HSG"),

  # Sidebar
  sidebarLayout(
    sidebarPanel(width = 3,

                 # Let user pick stocks
                 pickerInput(
                   inputId = "stocks",
                   label = h4("Stocks"),
                   choices = choices,
                   selected = prices_df$symbol[prices_df$symbol == "AAPL"],
                   options = list(`actions-box` = TRUE),
                   multiple = T
                 ),

                 # Pick time period
                 radioButtons("period", label = h4("Period"),
                              choices = list("1 month" = 1, "3 months" = 2, "6 months" = 3, "12 months" = 4, "YTD" = 5),
                              selected = 4
                 ),

                 # Pick benchmark
                 radioButtons("benchmark", label = h4("Benchmark"),
                              choices = list("SP500" = 1, "Nasdaq100" = 2,"None" = 3),
                              selected = 3)
    ),

    # Plot results
    mainPanel(
        tabsetPanel(
          tabPanel("History", plotlyOutput("plot",height=800)),
          tabPanel("Porfolio Weights", plotOutput("weights"), height = 800),
          tabPanel("Efficient Frontier", plotOutput("ef"), height = 800)
      )
    )
  )
)




# -----------------------------------------------------
# SERVER
#-------------------------------------------------------

server <- function(input, output) {

  # server logic based on user input
  observeEvent(c(input$period,input$stocks,input$benchmark), {

    prices_df <- prices_df %>%
      filter(symbol %in% input$stocks)

    if (input$period == 1) {
      prices_df <- prices_df %>%
        filter(
          date >= today()-months(1)) }

    if (input$period == 2) {
      prices_df <- prices_df %>%
        filter(date >= today()-months(3)) }

    if (input$period == 3) {
      prices_df <- prices_df %>%
        filter(date >= today()-months(6)) }

    if (input$period == 5) {
      prices_df <- prices_df %>%
        filter(year(date) == year(today())) }

    if (input$benchmark == 1) {
      bench <- bench %>%
        filter(symbol=="^GSPC",
               date >= min(prices_df$date))
      prices_df <- rbind(prices_df,bench) }

    if (input$benchmark == 2) {
      bench <- bench %>%
        filter(symbol=="^NDX",
               date >= min(prices_df$date))
      prices_df <- rbind(prices_df,bench) }

    # Create plot
    output$plot <- renderPlotly({
      print(
        ggplotly(prices_df %>%
                   group_by(symbol) %>%
                   mutate(init_close = if_else(date == min(date),close,NA_real_)) %>%
                   mutate(value = round(100 * close / sum(init_close,na.rm=T),1)) %>%
                   ungroup() %>%
                   ggplot(aes(date, value,colour = symbol)) +
                   geom_line(size = 1, alpha = .9) +
                   # uncomment the line below to show area under curves
                   # geom_area(aes(fill=symbol),position="identity",alpha=.2) +
                   theme_minimal(base_size=16) +
                   theme(axis.title=element_blank(),
                         plot.background = element_rect(fill = "black"),
                         panel.background = element_rect(fill="black"),
                         panel.grid = element_blank(),
                         legend.text = element_text(colour="white"))
        )
      )
    })

    returns <- prices_df %>%
      group_by(symbol) %>%
      tq_transmute(select = close, mutate_fun = periodReturn, period = "daily", type = "log") %>%
      pivot_wider(names_from = symbol, values_from = daily.returns) %>%
      tk_xts()

    mu <- colMeans(returns)
    cov <- cov(returns)*252

    num_port <- 1000

    all_wts <- matrix(nrow = num_port,
                      ncol = length(input$stocks))

    all_port_returns <- vector("numeric", length = num_port)
    all_port_risk <- vector("numeric", length = num_port)
    all_port_sr <- vector("numeric", length = num_port)

    for (i in seq_along(all_port_returns)) {

      wts <- runif(length(input$stocks))
      wts_norm <- wts/sum(wts)

      # Storing weight in the matrix
      all_wts[i,] <- wts_norm

      # Portfolio returns

      port_ret <- ((sum(wts_norm * mu) + 1)^252) - 1

      # Storing Portfolio Returns values
      all_port_returns[i] <- port_ret


      # Creating and storing portfolio risk
      port_sd <- sqrt(t(wts_norm) %*% (cov  %*% wts_norm))
      all_port_risk[i] <- port_sd

      sr <- port_ret/port_sd
      all_port_sr[i] <- sr

    }

    port_values <- tibble(Return = all_port_returns, Risk = all_port_risk, Sharpe = all_port_sr)
    all_wts <- tk_tbl(all_wts)
    colnames(all_wts) <- colnames(returns)
    port_values <- tk_tbl(cbind(all_wts, port_values))

    min_var <- port_values[which.min(port_values$Risk), ]
    max_sr <- port_values[which.max(port_values$Sharpe), ]

    output$weights <- renderPlotly({
      print(
        ggplotly(min_var %>%
                   gather(1:length(names(returns)), key = Asset,
                          value = Weights) %>%
                   ggplot(aes(x = fct_reorder(Asset,Weights), y = Weights, fill = Asset)) +
                   geom_bar(stat = 'identity') +
                   theme_minimal() +
                   labs(x = 'Assets', y = 'Weights', title = "Minimum Variance Portfolio Weights") +
                   scale_y_continuous(labels = scales::percent)))
      })


    output$ef <- renderPlotly({
      print(
        ggplotly(port_values %>%
      ggplot(aes(x = Risk, y = Return, color = Sharpe)) +
      geom_point() +
      theme_classic() +
      scale_y_continuous(labels = scales::percent) +
      scale_x_continuous(labels = scales::percent) +
      labs(x = 'Annualized Risk',
           y = 'Annualized Returns',
           title = "Portfolio Optimization & Efficient Frontier") +
      geom_point(aes(x = Risk,
                     y = Return), data = min_var, color = 'red') +
      geom_point(aes(x = Risk,
                     y = Return), data = max_sr, color = 'red')))
    })

  })



}

# Run the application
shinyApp(ui = ui, server = server)
