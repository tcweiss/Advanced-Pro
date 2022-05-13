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

ui <- fluidPage(theme = shinytheme("cosmo"),

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
                   selected = prices_df$symbol[prices_df$symbol == c('AAPL', 'CSX', 'NKE')],
                   options = list(`actions-box` = TRUE),
                   multiple = T),

                 # Pick time period
                 radioButtons("period", label = h4("Period"),
                              choices = list("1 month" = 1, "3 months" = 2, "6 months" = 3, "12 months" = 4, "YTD" = 5),
                              selected = 4),

                 # Pick benchmark
                 radioButtons("benchmark", label = h4("Benchmark"),
                              choices = list("SP500" = 1, "Nasdaq100" = 2,"None" = 3),
                              selected = 3)),

    # Plot results
    mainPanel(
      tabsetPanel(type = "tabs",
                  tabPanel("Market Data", plotlyOutput("plot", height = 800)),
                  tabPanel("Portfolio", verbatimTextOutput("summary")))
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
                   ggplot(aes(x=date, y=value, color=symbol)) +
                   geom_line(size = 0.7, alpha = .9) +
                   scale_y_continuous() +
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
  })
}

# Run the application
shinyApp(ui = ui, server = server)

