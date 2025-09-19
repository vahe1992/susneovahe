app_server <- function(input, output, session) {
  creds <- mod_auth_server("auth1")  # server part for authentication
  output$auth_ui <- renderUI({
    if (!creds$auth) {
      mod_auth_ui("auth1")
    } else {
      mod_dashboard_ui("dash1")
    }
  })
  observeEvent(creds$auth, {
    if (creds$auth) {
      mod_dashboard_server("dash1")
    }
  })
}
