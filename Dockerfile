# Base R Shiny image
FROM rocker/shiny

# Make a directory in the container for your app
RUN mkdir /home/Ticket_tracker

# Install system dependencies required for R packages
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    build-essential \
    gfortran \
    default-jdk \
    libglpk-dev \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install R package manager and all required dependencies

ENV R_LIBS_SITE=/usr/local/lib/R/site-library

RUN apt-get update && apt-get install -y libsodium-dev
RUN R -e "install.packages('pacman', repos='http://cran.rstudio.com/')" \
    && R -e "pacman::p_load(shiny,shinyjs,htmltools,lubridate,mailR,sodium,googlesheets4,bslib,waiter,shinyalert,here,rio,shinycustomloader,dplyr,DT)"

# Copy your application files to the container
COPY . /home/Ticket_tracker/

# Create the secrets directory in the container
RUN mkdir -p /app/.secrets

# Copy the secrets file - adjust the filename if needed
COPY ./.secrets/7a6077d23f6776ccc63f8f70bc12b214_aureollerocher@gmail.com /app/.secrets/



# Set appropriate permissions for the secrets file
RUN chmod 600 /app/.secrets/7a6077d23f6776ccc63f8f70bc12b214_aureollerocher@gmail.com



# Set proper permissions
RUN chmod -R 755 /home/Ticket_tracker

# Expose the port Shiny will run on
EXPOSE 3838

# Run the R Shiny app
CMD ["R", "-e", "shiny::runApp('/home/Ticket_tracker', host='0.0.0.0', port=3838)"]