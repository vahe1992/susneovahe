FROM rocker/shiny-verse:latest

COPY DESCRIPTION /app/DESCRIPTION
COPY NAMESPACE /app/NAMESPACE
COPY R /app/R
COPY inst /app/inst
COPY man /app/man
WORKDIR /app

RUN R -e "install.packages('sodium', repos='https://cloud.r-project.org')"
RUN R -e "install.packages('remotes', repos='https://cloud.r-project.org'); remotes::install_local('.', dependencies = TRUE)"

EXPOSE 3838

CMD ["R", "-e", "pkgload::load_all('.'); shiny::runApp(golem::app_sys('app'), port=3838, host='0.0.0.0')"]
