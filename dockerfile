FROM rocker/shiny-verse:latest

# Install system dependencies if needed (optional)

# Install R package dependencies
COPY DESCRIPTION /app/DESCRIPTION
COPY NAMESPACE /app/NAMESPACE
COPY R /app/R
COPY inst /app/inst
COPY man /app/man
COPY golem-config.yml /app/golem-config.yml
WORKDIR /app
RUN R -e "install.packages('remotes'); remotes::install_local('.', dependencies = TRUE)"

EXPOSE 3838

CMD ["R", "-e", "pkgload::load_all('.'); shiny::runApp(golem::app_sys('app'), port=3838, host='0.0.0.0')"]
