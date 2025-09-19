FROM rocker/shiny-verse:latest

RUN apt-get update && apt-get install -y libsodium-dev && rm -rf /var/lib/apt/lists/*

# Install all R dependencies your package needs
RUN R -e "install.packages(c('remotes', 'plotly', 'config', 'golem', 'sodium'), repos='https://cloud.r-project.org')"

WORKDIR /app

COPY . /app

# Install your package without byte compilation (faster install, can help avoid hangs)
RUN R CMD INSTALL --no-byte-compile .

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp(golem::app_sys('app'), port=3838, host='0.0.0.0')"]
