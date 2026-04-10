# This must be done first before running SparCC because of the environment issues with SpeicEasi
# extract_otu.R — run with CBI module R, not conda env

# Install phyloseq if not already present
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager", repos = "https://cran.r-project.org")

if (!requireNamespace("phyloseq", quietly = TRUE))
  BiocManager::install("phyloseq", ask = FALSE)

library(phyloseq)

phy <- readRDS("/wynton/group/lynch/eladdy/CANOE_AIRWAY_16S/SparCC/bacterial_networks_Mar2026/Prevalence_Phyloseq_10_10.rds")

taxa_names(phy) <- paste0('ASV_', 1:length(taxa_names(phy)))

otu <- as(otu_table(phy), "matrix")
if (taxa_are_rows(phy)) otu <- t(otu)

message("OTU matrix dimensions (samples x taxa): ", nrow(otu), " x ", ncol(otu))

saveRDS(otu,
        "/wynton/group/lynch/eladdy/CANOE_AIRWAY_16S/SparCC/bacterial_networks_Mar2026/canoe_otu_matrix.rds")
message("Saved. Ready for SparCC in conda env.")
