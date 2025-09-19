# Use rocker/shiny-verse base image with latest R and Shiny packages
FROM rocker/shiny-verse:latest

# Install system libraries needed for R packages like sodium
RUN apt-get update && apt-get install -y libsodium-dev && rm -rf /var/lib/apt/lists/*

# Install essential R packages needed before your package installs
RUN R -e "install.packages(c('remotes', 'plotly'), repos='https://cloud.r-project.org')"

# Set working directory inside container
WORKDIR /app

# Copy your entire project source into the working directory
COPY . /app

# Optionally disable byte code compilation in this test build to avoid hanging on large packages
RUN R CMD INSTALL --no-byte-compile .

# Expose port 3838 for Shiny
EXPOSE 3838

# Default command to start your Shiny golem app
CMD ["R", "-e", "shiny::runApp(golem::app_sys('app'), port = 3838, host = '0.0.0.0')"]
