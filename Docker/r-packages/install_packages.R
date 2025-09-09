if (!requireNamespace("BiocManager", quietly = TRUE))
   install.packages("BiocManager")
library(BiocManager)
install("DNAcopy")
install.packages("optparse")
install.packages("data.table",version="1.14.8",repos= "http://cran.us.r-project.org")
install.packages("dplyr",version="1.1.2",repos= "http://cran.us.r-project.org")

