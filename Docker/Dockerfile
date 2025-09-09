# ------------------------------------------------------------
# Stage 1: Base R environment (Ubuntu + R 4.2.2)
# ------------------------------------------------------------
FROM rocker/r-ver:4.2.2 AS base

ENV DEBIAN_FRONTEND=noninteractive
ENV R_LIBS_SITE=/usr/local/lib/R/site-library

# Install essential system dependencies (including libbz2-dev)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    gfortran \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    unzip \
    wget \
    zlib1g-dev \
    libbz2-dev \
    libfontconfig1-dev \
    libxt-dev \
    libx11-dev \
    libtiff5-dev \
    libjpeg-dev \
    libpng-dev \
    libudunits2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Stage 2: Install R packages (multi-layered for reliability)
# ------------------------------------------------------------
FROM base AS r-packages

# Core R helpers
RUN R -e ".libPaths(Sys.getenv('R_LIBS_SITE')); \
          install.packages(c('remotes','BiocManager','devtools','pkgbuild'), repos='https://cloud.r-project.org/')"

# Core Bioconductor dependencies, including Rhtslib etc.
RUN R -e ".libPaths(Sys.getenv('R_LIBS_SITE')); \
          BiocManager::install(c('DNAcopy','HMMcopy','GenomicRanges','GenomeInfoDb','IRanges','S4Vectors','Rhtslib','Rsamtools'), ask=FALSE, update=FALSE)"

# Genome-specific packages
RUN R -e ".libPaths(Sys.getenv('R_LIBS_SITE')); \
          BiocManager::install(c('BSgenome','BSgenome.Hsapiens.UCSC.hg19','BSgenome.Hsapiens.UCSC.hg38'), ask=FALSE, update=FALSE)"

# CRAN extras
RUN R -e ".libPaths(Sys.getenv('R_LIBS_SITE')); \
          install.packages(c('foreach','data.table','dplyr','doMC','ggplot2','stringr'), repos='https://cloud.r-project.org/')"

# ichorCNA from GitHub
RUN R -e ".libPaths(Sys.getenv('R_LIBS_SITE')); \
          remotes::install_github('GavinHaLab/ichorCNA@v0.6.0', dependencies=TRUE, upgrade='never')"


# ------------------------------------------------------------
# Stage 3: Final runtime image
# ------------------------------------------------------------
FROM base AS final

# Copy installed R packages into final image
COPY --from=r-packages /usr/local/lib/R/site-library /usr/local/lib/R/site-library

# Default command: verify ichorCNA loads successfully
CMD ["R", "-e", "library(ichorCNA); message('ichorCNA loaded successfully!')"]

# ------------------------------------------------------------
# Stage 4:
# ------------------------------------------------------------
RUN wget https://github.com/shahcompbio/hmmcopy_utils/archive/29a8d1d.zip && unzip 29a8d1d.zip 
RUN cmake ./hmmcopy_utils-29a8d1d18dfd301600d5d91832e5fe231935058c && make

# ------------------------------------------------------------
# Stage 5:
# ------------------------------------------------------------
RUN wget https://github.com/GavinHaLab/ichorCNA/archive/refs/tags/v0.6.0.zip && unzip v0.6.0.zip && mv ichorCNA-0.6.0/ ichorCNA/
