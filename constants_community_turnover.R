####
# Constants for the "Community Compositional Change" tab
####

# Folder holding the Bray-Curtis turnover + complete kelp loss rasters,
# relative to toplevel_dir (defined in constants.R)
community_dist_dir <- "Projected_Kelp_community_change"

# Bray-Curtis probability-of-turnover rasters (continuous, per scenario).
# Per McHenry et al. methods: >= 0.25 = turnover zone, < 0.25 = persistence zone
bray_curtis_layers <- list(
  "SSP 126" = "BrayCurtis_prob_turnover_ssp126_2090.tif",
  "SSP 245" = "BrayCurtis_prob_turnover_ssp245_2090.tif",
  "SSP 370" = "BrayCurtis_prob_turnover_ssp370_2090.tif"
)

# Complete kelp loss masks (binary, per scenario): cells where one or more
# kelp species is present today but ALL kelp species are projected absent
# under that scenario. This overrides the Bray-Curtis classification --
# those cells are "loss," not "turnover."
kelp_lost_layers <- list(
  "SSP 126" = "all_kelp_lost_SSP126.tif",
  "SSP 245" = "all_kelp_lost_SSP245.tif",
  "SSP 370" = "all_kelp_lost_SSP370.tif"
)
