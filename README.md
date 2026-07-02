# rarefyr

A lightweight R package for rarefaction curves and plots from OTU/ASV
count tables, built for teaching in Colab, not as a vegan/phyloseq replacement.

## Install

```r
install.packages("remotes")  # if not already available
remotes::install_github("toryn13/rarefyr")

```

## Usage

```r
library(rarefyr)

# otu_table: taxa/OTUs in rows, samples in columns, row names = OTU IDs
curve <- rarefy_curve(otu_table, num_iterations = 20, seed = 1)

plot_rarefaction(curve)

# colour by a metadata grouping variable instead of by sample
plot_rarefaction(curve, metadata = sample_metadata, group_var = "treatment")
```





