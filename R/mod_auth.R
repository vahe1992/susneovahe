#' Authentication UI
mod_auth_ui <- function(id) {
  ns <- NS(id)
  tagList(
    textInput(ns("user"), "User"),
    passwordInput(ns("pw"), "Password"),
    actionButton(ns("login"), "Login"),
    tags$hr(),
    h4("Register"),
    textInput(ns("reguser"), "New User"),
    passwordInput(ns("regpw"), "New Password"),
    actionButton(ns("register"), "Register"),
    textOutput(ns("message"))
  )
}

#' Authentication server logic
mod_auth_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    creds <- reactiveValues(auth = FALSE, user = NULL)
    observeEvent(input$login, {
      users <- read.csv("users.csv", stringsAsFactors = FALSE)
      current <- users[users$user == input$user, ]
      if (nrow(current) == 1 && sodium::password_verify(current$password, input$pw)) {
        creds$auth <- TRUE
        creds$user <- input$user
        output$message <- renderText("")
      } else {
        output$message <- renderText("Invalid login.")
      }
    })
    observeEvent(input$register, {
      users <- read.csv("users.csv", stringsAsFactors = FALSE)
      if (input$reguser == "" || input$regpw == "") {
        output$message <- renderText("Please fill in all registration fields.")
      } else if (input$reguser %in% users$user) {
        output$message <- renderText("Username exists.")
      } else {
        hash <- sodium::password_store(input$regpw)
        users <- rbind(users, data.frame(user = input$reguser, password = hash))
        write.csv(users, "users.csv", row.names = FALSE)
        output$message <- renderText("Registration successful! Please login.")
      }
    })
    return(creds)
  })
}
