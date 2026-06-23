####
# preprocess_rasters.R
#
# Run this ONCE locally (and again any time the source rasters change),
# BEFORE deploying the app. It downscales every raster the app uses to
# `maxcell` cells -- the same downscaling app.R used to do live on every
# dropdown change -- and saves the results into a mirrored folder,
# `Processed_for_app/`, that sits alongside your existing data folders.
#
# For the Community Compositional Change tab, this also does the
# Bray-Curtis + complete-kelp-loss classification ONCE here, so the app
# only ever has to load a single, already-finished raster per scenario
# instead of loading two full-resolution rasters and combining them live.
#
# After running this, app.R should load straight from Processed_for_app/
# with no spatSample() calls left at runtime.
####

library(terra)
library(glue)

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

# Generic helper: load one raster at full resolution, downscale it the same
# way the app used to do live, and write it out under the same filename.
downscale_and_save <- function(in_path, out_path, datatype = "INT1S") {
  print(glue("Processing: {in_path}"))
  r <- rast(in_path)
  r <- r |> spatSample(size = maxcell, as.raster = TRUE, warn = TRUE, method = "regular")
  ensure_dir(dirname(out_path))
  writeRaster(r, out_path, overwrite = TRUE, datatype = datatype)
  print(glue("  -> saved {out_path}"))
}

####
## 1. Current distributions (binary presence/absence: 0/1)
####
for (sp in names(kelp_layers)) {
  in_path  <- glue("{toplevel_dir}/{current_dist_dir}/{kelp_layers[[sp]]}")
  out_path <- glue("{toplevel_dir}/{processed_dir}/{current_dist_dir}/{kelp_layers[[sp]]}")
  downscale_and_save(in_path, out_path, datatype = "INT1S")
}

####
## 2. Projected redistribution change layers (-2 / -1 / 0 / 1)
####
for (scenario in names(change_layers)) {
  for (sp in names(change_layers[[scenario]])) {
    in_path  <- glue("{toplevel_dir}/{change_dist_dir}/{change_layers[[scenario]][[sp]]}")
    out_path <- glue("{toplevel_dir}/{processed_dir}/{change_dist_dir}/{change_layers[[scenario]][[sp]]}")
    downscale_and_save(in_path, out_path, datatype = "INT1S")
  }
}

####
## 3. Community compositional change -- classify AND downscale in one pass
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
  composition <- composition |> spatSample(size = maxcell, as.raster = TRUE,
                                           warn = TRUE, method = "regular")

  out_path <- glue("{toplevel_dir}/{processed_dir}/{community_dist_dir}/composition_{scenario_code(scenario)}.tif")
  ensure_dir(dirname(out_path))
  writeRaster(composition, out_path, overwrite = TRUE, datatype = "INT1S")
  print(glue("  -> saved {out_path}"))
}

####
## 4. Environmental layers (continuous values -- keep as float)
####
for (layer_name in names(env_layers)) {
  in_path  <- glue("{toplevel_dir}/{env_dist_dir}/{env_layers[[layer_name]]}")
  out_path <- glue("{toplevel_dir}/{processed_dir}/{env_dist_dir}/{env_layers[[layer_name]]}")
  downscale_and_save(in_path, out_path, datatype = "FLT4S")
}

print("Done. All rasters downscaled (and composition layers pre-classified) under:")
print(glue("{toplevel_dir}/{processed_dir}/"))
