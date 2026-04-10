#Note that this has to be done in the conda environment /wynton/home/lynchlab/eladdeiss1/.conda/envs/r_spieceasi_env. For step 2 you do not need to use SpiecEasi so you can deactivate the conda environment

library(SpiecEasi)

otu <- readRDS("/wynton/group/lynch/eladdy/CANOE_AIRWAY_16S/SparCC/bacterial_networks_Mar2026/canoe_otu_matrix.rds")

message("Loaded OTU matrix: ", nrow(otu), " samples x ", ncol(otu), " taxa")

# Call sparcc() directly, bypassing the spiec.easi wrapper bug
sparcc_result <- sparcc(
  otu,
  iter       = 20,   # outer iterations — default, standard
  inner_iter = 10,   # inner iterations — default, standard
  th         = 0.1   # convergence threshold — default, standard
)

saveRDS(sparcc_result,
        "/wynton/group/lynch/eladdy/CANOE_AIRWAY_16S/SparCC/bacterial_networks_Mar2026/canoe_sparcc_base.rds")

message("Done. SparCC result saved.")
