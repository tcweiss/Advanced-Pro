
# Investing@HSG

Did you ever think about investing but didn't know how?
![Image](Image.png?) <br>

Selecting the right stocks can require a lot of work and expertise. Our goal was to develop a tool that simplifies this process and saves investors valuable time. If you are interested, we encourage you to read on and experience our web app by yourself. Happy investing!

1. [ General Information ](#desc)
2. [ Technologies/Setup ](#usage)
3. [ Overview of Features ](#feat)
4. [ Technical Background ](#tech)
5. [ Disclaimer ](#disc)
6. [ Appendix: Libraries Description ](#lib)


<a name="desc"></a>
## 1. General Information
The student project "Investing@HSG" is part of the courses "Programming - Introduction Level" & "Programming with Advanced Computer Languages" by Mario Silic at the University of St. Gallen (HSG). It is an interactive web application and can display historical market data, provide forecasts on future stock prices and optimize stock portfolios. <br>
<br>
Investing@HSG was developed by
- Armin Begic (20-614-582)
- Samuell Duerr (20-609-855)
- Sebastian Tragust (17-620-220)
- Thomas Weiss (17-620-360)
<br>

**Please note:** <br>
The folder [investing_at_hsg](https://github.com/tcweiss/Advanced-Pro/tree/main/investing_at_hsg) found on this repo includes all relevant files. The file [app.R](https://github.com/tcweiss/Advanced-Pro/blob/90e500c360bcb408a23733337e2e963c987a5bb2/investing_at_hsg/app.R) is the main script which executes the program. It accesses [functions.R](https://github.com/tcweiss/Advanced-Pro/blob/90e500c360bcb408a23733337e2e963c987a5bb2/portfolio_selection/code/functions.R), which includes self-written functions, and [app_data](https://github.com/tcweiss/Advanced-Pro/blob/90e500c360bcb408a23733337e2e963c987a5bb2/investing_at_hsg/app_data), which includes multiple datasets.<br>
A more detailed description on the structure is given below.

<a name="usage"></a>
## 2. Technologies/Setup

### Online

Since we deployed our web-app online, all you need is an internet connection. For best results, we recommend opening the app on a screen with at least 13 inches. Note that it may take a few second for the program to run.

Link to app: [Investing@HSG](https://thomas-weiss.shinyapps.io/investing_at_hsg/)


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

If everything worked, clone this repo and save it on your machine. Make sure to set your working directory to the 'investing_at_hsg' folder and open the 'app.R' file. Click the 'Run App' button in RStudio and the app should appear on you machine. NOTE: You may have to create an account on Rstudio Connect.

<a name="feat"></a>
## 3. Overview of Features





<a name="tech"></a>
## 4. Technical Background

### Step 0: Framework
Prior to getting started it is vital to install and import all the required libraries that are listed in the chapters above. Disregarding this step will lead to an incorrect execution of this program.

### Step 1: Input

The first step is to enter the desired stock ticker (e.g. 'AAPL' for Apple Inc. or 'MSFT' for Microsoft Corporation). Please note that for some smaller companies there is not enough data available to value the stock based on a DCF valuation. In this case, the program will display a corresponding error message.

### Step 2: Descriptive Statistics & Stock Price Development

After the user has chosen a stock for the valuation the program provides some descriptive statistics such as the mean, standard deviation, variance, minimum and maximum of the stock price and stock trading volume during the last year. Additionally, the program visualizes the adjusted closing price development for the same time period.

### Step 3: Assumptions

In this section the program makes some assumptions that are essential for the excecution of the valuation process.

In order to determine the appropriate risk and the corresponding cost of capital for any company, the program requires the interest rate of a risk-free asset. For this purpose, it assumes a risk-free rate of ```1.60%``` in accordance with the 10 Year US Treasury Rate.

Furthermore, the program requires the perpetual growth rate as an assumption to calculate the terminal value of a company. The perpetual growth rate is the growth rate at which a company is expected to continue growing into eternity. Since it cannot realistically be assumed that companies will continue to grow into perpetuity at high rates, a perpetual growth rate in line with the average growth of the GDP is a reasonable assumption. The program therefore applies a rate of ```3.00%``` in accordance with the growth rate of the global GDP.

Finally, a time horizon of ```5 years``` is assumed for the projection of future free cashflows. The shorter the projection period, the larger is the contribution of the terminal value to the total value of the company. On the other hand, an excessively long projection period is also not desirable, as it is extremely difficult to reasonably estimate the individual cash flows for each of the future years. Hence, a time span of 5 years provides a reasonable approach in corporate valuations. This number can of course be customized as desired by the user.

### Step 4: Historical Data & Free Cashflows

The next step is to gather all the historical data of a company that is required for the valuation process. The program automatically collects all the necessary figures (such as historical EBIT, Tax expenses, D&A, Capex and changes in Net Working Capital) from the Yahoo! Finance API and calculates the free cashflows of the past three years.

### Step 5: WACC (Cost of Capital)

In the fourth step the program derives the cost of capital used for discounting future cashflows. The weighted average cost of capital (WACC) consists of cost of equity and cost of dept.

#### Cost of Equity
To calculate cost of equity the program uses the CAPM model, which is a widely used tool in Finance. The CAPM is a special regression analysis that plots the returns of the target company (which represent the dependent variable) against the average market returns of the target company's geographical market (which represents the independent variable). To determine a value for cost of equity, the program pulls the stock's appropriate beta (measure of the individual enterprise risk) from the Yahoo! Finance API. For average market returns the program identifies where the business is located and automatically calculates the average market returns of the corresponding market index.

#### Cost of Dept
There are multiple approaches to calculate a company's cost of dept. To ensure excellent results across a wide range of companies, we have decided to use the credit default risk as a measure of the company's cost of dept. As not all companies have an official credit rating available, we are calculating a synthetic credit rating for the target company based on its interest coverage ratio. Therefore, we put the average operating income before interest payments in relation to the average company's interest expenses. From this, we can derive the associated credit rating and based on that the corresponding credit spread. Now we can compute the company's cost of dept by adding the credit spread to the risk-free rate.

#### Combined Cost of Capital
To derive the total WACC, we multiply the respective cost of capital by the proportion of equity or debt in the company and offset the cost of debt against the tax shield. This provides us with the discount rate for the future cashflows.


### Step 6: Cashflow Growth Rate & Free Cashflow Projection

Since we do not care about hictorical data, as we are valuing the firm based on the expected future development of the company, we need to predict free cashflows for the projection horizon (in this case for the next 5 years). In order to do that, the program calculates historical cashflow growth rates based on the free cashflows of the past three years (which we calculated in Step 3). To avoid excessively high growth rates due to one-off events, the program takes the lower growth rate or averages out extreme values if necessary.

To take into account the difference between future and present value of free cashflows, the program discounts every single cashflow of each year in the projection horizon back to the present value, using the weighted average cost of capital (WACC) that we calculated in the last step.

### Step 7: Terminal Value

To account for the 'going concern principle' (the assumption that the company will continue to exist in the future), we need to calculate the terminal value of the firm. Therefore, the program takes the last projected free cashflow (in this case the cashflow of year 5), grows it by the perpetual growth rate and uses the 'Gordon growth formula' to calculate the perpetual value. Discounting this value back to the present value provides us with the terminal value of the company.

### Step 8: Implied Value per Share

To arrive at the implied value per share, we need to sum up the present values of the projected free cashflows and the terminal value. As we are interested in the equity value of the firm, the program adds the value of the cash from the company's balance sheet and deducts the value of total dept. Dividing this value by the number of shares outstanding we obtain the fair value per share based on our prediction of the development of the firm's future free cashflows.

### Step 9: Current Share Price

Collect the current market value of the share as basis for the recommendation of the "Stock Investing Advisor".

### Step 10: Recommendation

In the last step the program provides the user with a recommendation. Depending on the difference between the implied value per share and the current market value of the share, the program indicates whether it considers the stock to be undervalued, overvalued or efficiently priced. In addition, based on this calculation, the program recommends holding, selling or buying the share.



<a name="discl"></a>
## 5. Disclaimer
This valuation model is based on the anticipation of future free cash flows. As with any intrinsic valuation method, it is essential to bear in mind that valuations are not equally applicable to all businesses. While some companies do not even meet the required criteria (e.g. generating positive cash flows), other companies' values are not directly linked to the generation of free cash flows (e.g. Tesla and other companies that are experiencing hype for various reasons). Therefore, it is important to consider the individual context of each company in order to correctly implement the output of this DCF valuation. The delivered value should never be considered as an isolated basis in any decision-making process.


<a name="lib"></a>
## 6. Appendix: Library Description

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

