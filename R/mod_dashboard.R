library(shiny)
library(dplyr)
library(plotly)
source("business_logic/business_logic.R") # your existing logic

mod_dashboard_ui <- function(id) {
  ns <- NS(id)
  fluidRow(
    column(4,
      h3("Welcome to the dashboard!"),
      fileInput(ns("csvfile"), "Upload CSV File", accept = ".csv"),
      uiOutput(ns("upload_message")),
      uiOutput(ns("date_filter_ui")),
      uiOutput(ns("site_filter_ui")),
      uiOutput(ns("type_filter_ui")),
      uiOutput(ns("calc_button_ui")),
      uiOutput(ns("stats_error"))
    ),
    column(8,
      DT::DTOutput(ns("stats_table")),
      plotlyOutput(ns("site_type_sunburst")),
      plotlyOutput(ns("time_series"))
    )
  )
}

mod_dashboard_server <- function(id) {


  moduleServer(id, function(input, output, session) {

    # Server variables
    ns <- session$ns
    output$upload_message <- renderText({ "" })
    uploaded_df <- reactiveVal(NULL)
    pie_trigger <- reactiveVal(NULL)




    # Exctract filtered data based on the inputs
    filtered_data <- reactive({
      df <- uploaded_df()
      req(df)
      filtered_df <- df
      if (!is.null(input$date_filter)) {
        filtered_df <- filtered_df[filtered_df$date >= input$date_filter[1] & filtered_df$date <= input$date_filter[2], ]
      }
      if (!is.null(input$site_filter)) {
        filtered_df <- filtered_df[filtered_df$site %in% input$site_filter, ]
      }
      if (!is.null(input$type_filter)) {
        filtered_df <- filtered_df[filtered_df$type %in% input$type_filter, ]
      }
      filtered_df
    })



    # Filters based on the uploaded csv
    output$date_filter_ui <- renderUI({
      df <- uploaded_df()
      req(df)
      dates <- as.Date(df$date)
      if (any(is.na(dates))) return(NULL)
      dateRangeInput(ns("date_filter"), "Date range filter",
                     start = min(dates), end = max(dates),
                     min = min(dates), max = max(dates))
    })
    output$site_filter_ui <- renderUI({
      df <- uploaded_df()
      req(df)
      sites <- unique(df$site)
      selectInput(ns("site_filter"), "Select Sites", choices = sites,
                  selected = sites, multiple = TRUE)
    })
    output$type_filter_ui <- renderUI({
      df <- uploaded_df()
      req(df)
      types <- unique(df$type)
      selectInput(ns("type_filter"), "Select Types", choices = types,
                  selected = types, multiple = TRUE)
    })




    # Button related functions
    # If there are no inputs, don't show the button
    output$calc_button_ui <- renderUI({
      req(uploaded_df())
      actionButton(ns("calc_stats"), "Calculate statistics")
    })
    # What to do when the button is clicked
    observeEvent(input$calc_stats, {
      # Check if required inputs are available
      req(filtered_data())

      # Progress bar
      withProgress(message = "Calculating statistics...", value = 0, {
        incProgress(0.3, detail = "Calculating stats")
        res <- calc_statistics(filtered_data())
        incProgress(0.6, detail = "Finalizing")
      }) 

      # Check if the data validation has passed
      if (is.character(res)) {
        output$stats_error <- renderUI({
          tags$span(style = "color: red; font-weight: bold;", res)
        })
        output$stats_table <- DT::renderDT({ NULL })
      } else if (is.data.frame(res)) {
        pie_trigger(filtered_data())
        output$stats_table <- DT::renderDT({
          res
        }, options = list(paging = FALSE, searching = FALSE, lengthChange = FALSE))
        output$stats_error <- renderUI({ NULL })
      } else {
        output$stats_error <- renderUI({
          tags$span(style = "color: red;", "Unexpected result from calc_statistics.")
        })
        output$stats_table <- DT::renderDT({ NULL })
      }
    })



    # What to do when a file is uploaded
    observeEvent(input$csvfile, {
      req(input$csvfile)
      uploaded_df(NULL)
      pie_trigger(NULL)
      output$stats_table <- DT::renderDT({ NULL })
      ext <- tools::file_ext(input$csvfile$name)
      if (length(ext) == 0 || tolower(ext) != "csv") {
        showModal(modalDialog(title = "Invalid file", "Please upload a CSV file only.", easyClose = TRUE))
        output$upload_message <- renderUI({ "Please upload a CSV file only." })
        return()
      }
      df <- tryCatch(read.csv(input$csvfile$datapath), error = function(e) NULL)
      if (is.null(df)) {
        showModal(modalDialog(title = "Read error", "Unable to read CSV file. Please upload a valid CSV file.", easyClose = TRUE))
        output$upload_message <- renderUI({ "Unable to read CSV file. Please upload a valid CSV file." })
        return()
      }
      df <- validate_csv(df)
      if (!is.data.frame(df)) {
        showModal(modalDialog(title = "Invalid CSV structure", df, easyClose = TRUE))
        output$upload_message <- renderUI({ df })
        return()
      }
      uploaded_df(df)
      output$upload_message <- renderUI({
        tags$span(style = "color: green; font-weight: bold;", "File uploaded successfully!")
      })
    })








    # Function for plotting subburst
    output$site_type_sunburst <- renderPlotly({
      # Check if the data exists
      df <- pie_trigger()
      req(df)
      # If data exists
      agg_site <- df %>%
        group_by(site) %>%
        summarise(value = sum(value, na.rm = TRUE), .groups = "drop") %>%
        mutate(id = paste0("site_", site), parent = "")
      agg_type <- df %>%
        group_by(site, type) %>%
        summarise(value = sum(value, na.rm = TRUE), .groups = "drop") %>%
        mutate(id = paste0("type_", site, "_", type), parent = paste0("site_", site))
      sunburst_data <- bind_rows(
        agg_site %>% select(id, labels = site, parent, value),
        agg_type %>% select(id, labels = type, parent, value)
      )
      # Plot the sunburst
      plot_ly(
        data = sunburst_data,
        ids = ~id,
        labels = ~labels,
        parents = ~parent,
        values = ~value,
        type = 'sunburst',
        branchvalues = 'total',
        textinfo = "label+percent parent"
      ) %>%
        layout(title = "Value Breakdown by Site and Type", margin = list(t = 40))
    })





    # Function for rendering the time series
    output$time_series <- renderPlotly({
      # Check if df exists
      df <- pie_trigger()
      req(df)
      # If df exists
      total_sum <- sum(df$kg, na.rm = TRUE)
      ts_data <- df %>%
        group_by(date, type) %>%
        summarise(value_sum = sum(kg, na.rm = TRUE), .groups = "drop") %>%
        mutate(percent = (value_sum / total_sum) * 100)
      # Plot time series
      plot_ly(ts_data, x = ~date, y = ~percent, color = ~type, type = 'scatter', mode = 'lines+markers') %>%
        layout(
          title = "Time Series: % of total 'kg' by Type",
          yaxis = list(title = "Percentage of Total"),
          xaxis = list(title = "Date")
        )
    })






  })
}
