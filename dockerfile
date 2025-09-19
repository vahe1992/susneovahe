# Use rocker/shiny-verse as base (includes R, Shiny, and common packages)
FROM rocker/shiny-verse:latest

# Install system dependencies needed for some R packages (e.g. sodium)
RUN apt-get update && apt-get install -y libsodium-dev

# Copy R package source code and metadata into the container
COPY DESCRIPTION /app/DESCRIPTION
COPY NAMESPACE /app/NAMESPACE
COPY R /app/R
COPY inst /app/inst
COPY man /app/man

WORKDIR /app

# Install remotes then install your golem app and dependencies from source
RUN R -e "install.packages('remotes', repos='https://cloud.r-project.org')"
RUN R -e "remotes::install_local('.', dependencies = TRUE)"

# Expose the port Shiny listens on
EXPOSE 3838

# Run your app by loading the package and launching the golem app server
CMD ["R", "-e", "pkgload::load_all('.'); shiny::runApp(golem::app_sys('app'), port=3838, host='0.0.0.0')"]
