# Use a more recent Rocker base to avoid outdated mirrors
FROM rocker/r-ver:4.2.2

# Install system dependencies in one layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cmake \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        unzip \
        wget \
        build-essential && \
    rm -rf /var/lib/apt/lists/*

# Download and build hmmcopy_utils
RUN wget https://github.com/shahcompbio/hmmcopy_utils/archive/29a8d1d.zip && \
    unzip 29a8d1d.zip && \
    cd hmmcopy_utils-29a8d1d18dfd301600d5d91832e5fe231935058c && \
    cmake . && make

# Install Bioconductor packages
RUN R -e "install.packages('BiocManager', dependencies=TRUE, repos='http://cran.rstudio.com/')" && \
    R -e "BiocManager::install(c('HMMcopy','GenomicRanges','GenomeInfoDb','BSgenome.Hsapiens.UCSC.hg19','BSgenome.Hsapiens.UCSC.hg38'), ask=FALSE, version='3.16')"

# Install CRAN packages including remotes
RUN R -e "install.packages(c('foreach', 'data.table', 'doMC', 'ggplot2', 'strings','remotes'), dependencies=TRUE, repos='http://cran.rstudio.com/')"

# Install ichorCNA from GitHub
RUN R -e "remotes::install_github('GavinHaLab/ichorCNA@v0.5.0', dependencies = TRUE)"

# Download support data for ichorCNA
RUN wget https://github.com/GavinHaLab/ichorCNA/archive/refs/tags/v0.6.0.zip && \
    unzip v0.6.0.zip && \
    mv ichorCNA-0.6.0/ ichorCNA/

# Set default shell
CMD ["/bin/bash"]

