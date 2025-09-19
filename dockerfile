FROM rocker/shiny-verse:latest

RUN apt-get update && apt-get install -y libsodium-dev

# Install R package dependencies explicitly before installing your package
RUN R -e "install.packages(c('remotes', 'plotly'), repos='https://cloud.r-project.org')"

COPY DESCRIPTION /app/DESCRIPTION
COPY NAMESPACE /app/NAMESPACE
COPY R /app/R
COPY inst /app/inst
COPY man /app/man
COPY business_logic /app/business_logic
WORKDIR /app

# Install your golem app and dependencies using remotes
RUN R -e "remotes::install_local('.', dependencies = TRUE)"

EXPOSE 3838

CMD ["R", "-e", "pkgload::load_all('.'); shiny::runApp(golem::app_sys('app'), port=3838, host='0.0.0.0')"]
