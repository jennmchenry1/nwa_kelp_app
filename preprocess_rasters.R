####
# preprocess_rasters.R
#
# Run this ONCE locally (and again any time the source rasters change),
# BEFORE deploying the app. It does NOT downsample or aggregate any
# raster -- every cell value stays exactly as it is in the source data.
#
# It DOES reproject the categorical rasters (presence/absence, change
# classes, composition classes) from their native CRS (a polar Lambert
# Azimuthal projection, EPSG:3573) to Web Mercator (EPSG:3857), which is
# what Leaflet requires for display. Without this, addRasterImage() does
# that reprojection itself, on the fly, using smooth interpolation by
# default -- which blends adjacent category codes together at every
# boundary (e.g. averaging "Persistence" and "Turnover" produces a value
# that's neither, rendering as a smeared, overlapping-looking color).
# Reprojecting here, once, with explicit nearest-neighbor, avoids that
# rendering bug and means the app never has to do this work live.
#
# Continuous environmental layers are left untouched -- smooth
# interpolation during Leaflet's reprojection is actually correct for
# those, so they're just copied as-is.
#
# The only thing actually COMPUTED here (not just copied/reprojected) is
# the Community Compositional Change classification, since there's no
# raw file for that to start from -- it has to be built from the
# Bray-Curtis and complete-kelp-loss layers.
####

library(terra)
library(glue)

setwd("C:/Users/Jenn/Dropbox/GITHUB/RShiny_Repos/nwa_kelp_app/")

source("constants.R")
source("constants_future.R")
source("constants_community_turnover.R")


# This name must match the `processed_dir` constant used in app.R
processed_dir <- "Processed_for_app"

# Turns "SSP 126" into "ssp126" -- used to name the precomputed composition
# files. app.R uses this exact same helper to find them again.
scenario_code <- function(scenario) tolower(gsub(" ", "", scenario))

ensure_dir <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE)
}

# Plain copy -- no modification of any kind. Used for continuous layers,
# where Leaflet's default reprojection behavior is fine as-is.
copy_unmodified <- function(in_path, out_path) {
  print(glue("Copying: {in_path}"))
  ensure_dir(dirname(out_path))
  file.copy(in_path, out_path, overwrite = TRUE)
  print(glue("  -> saved {out_path}"))
}

# For CATEGORICAL rasters: load, reproject to Web Mercator with explicit
# nearest-neighbor (preserving exact category codes, no value blending at
# boundaries), and write out. No resolution change -- only the CRS changes.
reproject_categorical_and_save <- function(in_path, out_path, datatype = "INT1S") {
  print(glue("Reprojecting: {in_path}"))
  r <- rast(in_path)
  r <- project(r, "EPSG:3857", method = "near")
  ensure_dir(dirname(out_path))
  writeRaster(r, out_path, overwrite = TRUE, datatype = datatype)
  print(glue("  -> saved {out_path}"))
}

####
## 1. Current distributions (binary presence/absence: 0/1) -- categorical
####
for (sp in names(kelp_layers)) {
  in_path  <- glue("{toplevel_dir}/{current_dist_dir}/{kelp_layers[[sp]]}")
  out_path <- glue("{toplevel_dir}/{processed_dir}/{current_dist_dir}/{kelp_layers[[sp]]}")
  reproject_categorical_and_save(in_path, out_path, datatype = "INT1S")
}

####
## 2. Projected redistribution change layers (-2 / -1 / 0 / 1) -- categorical
####
for (scenario in names(change_layers)) {
  for (sp in names(change_layers[[scenario]])) {
    in_path  <- glue("{toplevel_dir}/{change_dist_dir}/{change_layers[[scenario]][[sp]]}")
    out_path <- glue("{toplevel_dir}/{processed_dir}/{change_dist_dir}/{change_layers[[scenario]][[sp]]}")
    reproject_categorical_and_save(in_path, out_path, datatype = "INT1S")
  }
}

####
## 3. Community compositional change -- classify first, then reproject.
##    0 = persistence, 1 = turnover, 2 = complete loss (loss overrides)
####
for (scenario in names(bray_curtis_layers)) {
  bc_path   <- glue("{toplevel_dir}/{community_dist_dir}/{bray_curtis_layers[[scenario]]}")
  loss_path <- glue("{toplevel_dir}/{community_dist_dir}/{kelp_lost_layers[[scenario]]}")
  
  print(glue("Processing composition: {scenario}"))
  bc   <- rast(bc_path)
  loss <- rast(loss_path)
  
  if (!compareGeom(bc, loss, stopOnError = FALSE)) {
    print("  Grids differ -- resampling loss layer to match Bray-Curtis grid")
    loss <- resample(loss, bc, method = "near")
  }
  
  composition <- (bc >= 0.25) * 1     # 0 = persistence, 1 = turnover
  composition[loss == 1] <- 2          # complete loss overrides
  composition <- project(composition, "EPSG:3857", method = "near")
  
  out_path <- glue("{toplevel_dir}/{processed_dir}/{community_dist_dir}/composition_{scenario_code(scenario)}.tif")
  ensure_dir(dirname(out_path))
  writeRaster(composition, out_path, overwrite = TRUE, datatype = "INT1S")
  print(glue("  -> saved {out_path}"))
}

####
## 4. Environmental layers (continuous) -- copied as-is, no reprojection
####
for (layer_name in names(env_layers)) {
  in_path  <- glue("{toplevel_dir}/{env_dist_dir}/{env_layers[[layer_name]]}")
  out_path <- glue("{toplevel_dir}/{processed_dir}/{env_dist_dir}/{env_layers[[layer_name]]}")
  copy_unmodified(in_path, out_path)
}

print("Done. Categorical layers reprojected to Web Mercator; continuous layers copied as-is, under:")
print(glue("{toplevel_dir}/{processed_dir}/"))

