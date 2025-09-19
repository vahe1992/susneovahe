app_ui <- function(request) {
  fluidPage(
    
    #golem_add_external_resources(),
    uiOutput("auth_ui"),  # will show auth or dashboard depending on login state
  )
}
