
# Investing@HSG

Did you ever think about investing but didn't know how?
![Image](images/Image.png?) <br>

Selecting the right stocks can require a lot of work and expertise. The goal of this project was to develop a tool that simplifies this process and saves investors valuable time. If you are interested, we encourage you to read on and experience it by yourself. Happy investing!

1. [ General Information ](#desc)
2. [ Running the Project ](#usage)
3. [ Overview of Features ](#feat)
4. [ Technical Background ](#tech)
5. [ Appendix: Libraries Description ](#lib)

<br><br>
<a name="desc"></a>
## 1. General Information
The student project "Investing@HSG" is part of the courses "Programming - Introduction Level" & "Programming with Advanced Computer Languages" by Mario Silic at the University of St. Gallen (HSG). It is an interactive web application and can display historical market data, provide forecasts on future stock prices and optimize stock portfolios. 

Investing@HSG was developed by
- Armin Begic (20-614-582)
- Samuell Duerr (20-609-855)
- Sebastian Tragust (17-620-220)
- Thomas Weiss (17-620-360)


<a name="usage"></a>
## 2. Running the Project

### Online

Since we deployed our web-app online, all you need is an internet connection. For best results, we recommend opening the app on a screen with at least 13 inches. Note that it may take a few second for the program to run. 

Link to app: Investing@HSG


### Locally

Alternatively, you can also run the app locally. This requires the following programs:
- R version 4.2.0: https://cran.rstudio.com 
- RStudio: https://www.rstudio.com/products/rstudio/download/
- Required libraries: ```shiny``` ```shinyWidgets``` ```shinythemes``` ```PerformanceAnalytics``` ```PortfolioAnalytics``` ```tidyquant``` ```tidyverse``` ```magrittr``` ```reactable``` ```arrow``` ```bslib``` ```qs``` ```timetk``` ```dygraphs``` ```rvest```

In order to properly use our "Investing@HSG"-App, it is essential to have installed the above listed libraries prior to running this program. To install all libraries, run the following code in your R console:

```
install.packages(c("shiny",                
                   "shinyWidgets",        
                   "shinythemes",          
                   "bslib",                
                   "PerformanceAnalytics", 
                   "PortfolioAnalytics",
                   "tidyquant",
                   "tidyverse",
                   "magrittr",
                   "reactable",
                   "arrow",
                   "qs",
                   "timetk",
                   "dygraphs",
                   "rvest"))
```

If everything worked, clone this repo and save it on your machine. Make sure to set your working directory to the 'investing_at_hsg' folder and open the 'app.R' file. Click the 'Run App' button in RStudio and the app should appear on you machine. *Note: you may have to create an account on Rstudio Connect.*

![Gif](images/run_locally.gif?) <br>


<a name="feat"></a>
## 3. Overview of Features

The app consists of two tabs: 'Market Info' and 'Investment Guide'.

The 'Market Info' tab offers the possibility to compare historical stock prices. Once you have found some interesting stocks, you can use the 'Investment Guide' tab to check if it would actually be a good investment. 

### Market Info

A panel on the left side allows to control what is displayed. The user can choose from all stocks in the SP500 as well as popular benchmark indices. One can also set different time horizons and decide whether prices should be standardized or not. If the input changes, the lineplot is updated accordingly, and the table below displays monthly return statistics of the selected stocks.


![Gif](images/tab_1_use.gif?) <br>

In addition, the stocks with the highest and lowest return in the past month are displayed at the bottom left. Note that this input is not influenced by the panel.


### Investment Guide

Opening the second tab, one can see two input fields. The input field on the left accepts text in the form of SP500 stock tickers. If the user enters a ticker, a 12-month forecast of the stock price and a BUY/HOLD/SELL recommendation will be displayed. The data is scraped directly from CNN Money and is based on the latest analyst estimates.


![Gif](images/tab_2_use_1.gif?) <br>


The second input field is a dropdown menu with SP500 stocks. Selecting two or more stock returns a table with optimal portfolio weights, i.e. the proportion of money to be invested in each stock. In addition, a plot displays the historical return of the portfolio, and the user gets a message telling him his return over the last 5 years.


![Gif](images/tab_2_use_2.gif?) <br>



<a name="tech"></a>
## 4. Technical Background

The folder [investing_at_hsg](https://github.com/tcweiss/Advanced-Pro/tree/main/investing_at_hsg) includes all relevant files. 

The first file is [app.R](https://github.com/tcweiss/Advanced-Pro/blob/main/investing_at_hsg/app.R), which is the main script that builds the app. It contains regular R code, wrapped inside functions from the Shiny package. The R code works as usual and creates all the output you see in the app. The Shiny functions simply embed the output into HTML code, which is what turns it into a web page. The basic functionality is the same for all features in the app. If you open app.R, you can see two main sections: user interface and server. First, the UI takes takes inputs from the user, e.g. stocks from a dropdown menu. Second, the input is sent to the server doing some calculations. Third, the output is sent back to the UI and shown to the user. This process is repeated constantly, so if the user changes the input, the output changes too.

The second and third files are [functions.R](https://github.com/tcweiss/Advanced-Pro/blob/main/code/functions.R), which contains self written functions, and [app_data](https://github.com/tcweiss/Advanced-Pro/blob/main/investing_at_hsg/ap_data), which contains multiple datasets. Both are accessed by the main script to perform calculations in the server section.

Below you can find more detailed descriptions of how each feature works.


### First Tab: Lineplot

To create the line plot, the app first accesses the app_data folder and imports prices.feather. This file contains price data of all stocks in the SP500 and five benchmarks over the past year, and has been downloaded from the Yahoo API. The data is then filtered for the assets and periods chosen by the user. If the user has chosen a standardized scale, all prices are then transformed to start at 100 in the first period. Finally, the adjusted dataset is then plotted.


### First Tab: Table with Decriptives

The table below the line plot follows a similar approach. After importing prices.feather, the data is filtered for the assets chosen by the user. However, for performance reasons, dates are always filtered for the last 30 days. No price standardization is performed either, since descriptive statistics are already a way to standardize results. Next, the app computes each asset’s returns over the past month. The return series are then used to compute the descriptive statistics. Finally, the results are formatted as a table.


### First Tab: Tables with Winners/Losers

To create the two tables on the bottom left corner, no user input is required. In a first step, the app accesses the app_data folder to import prices_wl.feather. This dataset contains the current percentage returns of all stocks in the SP500, computed over the last 30 days. It also comes from the Yahoo Finance API. The data is then sorted in descending (for winners) or ascending order (for losers). Next, the top three observations are extracted and formatted as a table. This is done for each table.


### Second Tab: Analyst Forecasts

After the user entered a ticker, the function checks if it corresponds to a SP500 ticker. If not, no operation will be performed. If the ticker is valid, the app proceeds as follows.

First, the ticker is passed as input to get_forecasts() in functions.R. This function uses the ticker to construct a URL leading to the stock’s page on CNN Money. The page’s source code is then downloaded, filtered for relevant tags, and the text contained in them is returned. Since the scraped text consists of whole paragraphs, the function then uses regex patterns to extract only the 12-month price forecasts and the BUY/HOLD/SELL recommendation. 

Second, the output from get_forecasts() is used by get_forecasts_plot(), which is also contained in functions.R. This function first fetches the stock’s price series for the last 12 months, using the Yahoo API. Next, it expands price series linearly by a year, starting from today’s price and ending with input containing the 12-month estimates. This is then used to create a plot, showing the past price followed by straight lines which represent the estimates. In addition, it prints a nicely formatted message to the user, which is displayed below the plot.


### Second Tab: Optimal Portfolio Weights

Once the user selects stocks from the dropdown menu, they are passed as input to get_weights() in functions.R. This functions first fetches stock prices for the last 12 months using the Yahoo API, and the compute each stock’s returns. Next, the functions defines multiple constraints: weights sum to 1 (full investment), weights must be in [0,1] (no short sales), and volatility per unit of return should be as low as possible (the industry standard). This is then solved as an optimization problem using the stock returns. Once the problem has been solved, the function returns the optimal weights.

Next, data from the last five years is fetched from the Yahoo API. The optimal weights are applied to construct an optimal portfolio, whose return is plotted and displayed to the user. In addition, the final return is extracted to show a message, telling the user how much a could have earned. Finally, the optimal weights are formatted as a table, which will show up on the right end of the page.


<a name="lib"></a>
## 5. Appendix: Library Description

### shinyWidgets
```shinyWidgets```boffers custom widgets and other components to enhance your shiny applications. You can replace classical checkboxes with switch button, add colors to radio buttons and checkbox group, use buttons as radio or checkboxes. Each widget has an update method to change the value of an input from the server. [(1)](https://github.com/dreamRs/shinyWidgets)
### shinythemes
```shinythemes``` provides some Bootstrap themes for use with Shiny. The themes are from from https://bootswatch.com/. [(2)](https://github.com/rstudio/shinythemes)
### bslib
```bslib``` provides tools for customizing Bootstrap themes directly from R, making it much easier to customize the appearance of Shiny apps & R Markdown documents. [(3)](https://rstudio.github.io/bslib/)
### PerformanceAnalytics
```PerformanceAnalytics``` provides econometric functions for performance and risk analysis of financial instruments or portfolios. This package aims to aid practitioners and researchers in using the latest research for analysis of both normally and non-normally distributed return streams. [(4)](https://cran.r-project.org/web/packages/PerformanceAnalytics/PerformanceAnalytics.pdf)
### PortfolioAnalytics
```PortfolioAnalytics``` provides numerical solutions for portfolio problems with complex constraints and objective sets. The goal of the package is to aid practicioners and researchers in solving portfolio optimization problems with complex constraints and objectives that mirror real-world applications. [(5)](https://cran.r-project.org/web/packages/PortfolioAnalytics/PortfolioAnalytics.pdf)
### tidyquant
```tidyquant``` integrates the best resources for collecting and analyzing financial data with the tidy data infrastructure of the tidyverse allowing for seamless interaction between each. You can now perform complete financial analyses in the tidyverse. [(6)](https://cran.r-project.org/web/packages/tidyquant/index.html)
### tidyverse
```tidyverse``` is an opinionated collection of R packages designed for data science. All packages share an underlying design philosophy, grammar, and data structures. [(7)](https://cran.r-project.org/web/packages/tidyverse/index.html)
### magrittr
```magrittr``` has two aims: decrease development time and improve readability and maintainability of code. To achieve its humble aims, magrittr provides a new “pipe”-like operator, ```%>%```, with which you may pipe a value forward into an expression or function call; something along the lines of ```x %>% f```, rather than ```f(x)```. [(8)](https://cran.r-project.org/web/packages/magrittr/vignettes/magrittr.html)
### reactable
```reactable``` provides interactive data tables for R, based on the 'React Table' JavaScript library. It provides an HTML widget that can be used in 'R Markdown' documents and 'Shiny' applications, or viewed from an R console. [(9)](https://glin.github.io/reactable/)
### arrow
```arrow``` (Apache Arrow) is a cross-language development platform for in-memory data. It specifies a standardized language-independent columnar memory format for flat and hierarchical data, organized for efficient analytic operations on modern hardware. It also provides computational libraries and zero-copy streaming messaging and interprocess communication. [(10)](https://arrow.apache.org/docs/r/)
### qs
```qs``` provides functions for quickly writing and reading any R object to and from disk. [(11)](https://cran.r-project.org/web/packages/qs/index.html)
### timetk
```timetk``` is a package that is part of the modeltime ecosystem for time series analysis and forecasting. [(12)](https://business-science.github.io/timetk/)
### dygraphs
```dygraphs``` is an R interface to the dygraphs JavaScript charting library. It provides rich facilities for charting time-series data in R. [(13)](https://rstudio.github.io/dygraphs/)
### rvest
```rvest``` helps you scrape (or harvest) data from web pages. It is designed to work with magrittr to make it easy to express common web scraping tasks, inspired by libraries like beautiful soup and RoboBrowser. [(14)](https://github.com/tidyverse/rvest)

