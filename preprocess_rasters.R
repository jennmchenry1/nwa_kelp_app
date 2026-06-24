####
# preprocess_rasters.R
#
# Run this ONCE locally (and again any time the source rasters change),
# BEFORE deploying the app. It DOES NOT change resolution -- it just
# rewrites each raster with a compact datatype and compression, and (for
# the Community Compositional Change tab) does the Bray-Curtis +
# complete-kelp-loss classification ONCE here, so the app only ever has
# to load a single, already-finished raster per scenario instead of
# loading two full-resolution rasters and combining them live.
#
# Why no downsampling: this used to aggregate rasters down to a target
# cell count to keep things fast and light. But kelp habitat sits in a
# very narrow coastal strip, and any aggressive downsampling -- whether
# via point-sampling or block aggregation -- either misses that strip
# entirely or blurs it into chunky, inaccurate-looking blocks. Now that
# the expensive resampling work happens here, offline, rather than live
# in the app on every dropdown click, and now that the app only loads one
# raster into memory at a time (see the tab-gated observers in app.R),
# there's much less need to shrink resolution at all. Compact datatypes +
# compression do most of the practical work of keeping file size down,
# without sacrificing the actual coastal detail.
#
# After running this, app.R should load straight from Processed_for_app/
# with no resampling calls left at runtime.
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

# Generic helper: load one raster at full resolution and write it back out
# under the same filename, just with a compact datatype and DEFLATE
# compression -- no change in resolution or cell values.
rewrite_compact <- function(in_path, out_path, datatype = "INT1S") {
  print(glue("Processing: {in_path}"))
  r <- rast(in_path)
  ensure_dir(dirname(out_path))
  writeRaster(r, out_path, overwrite = TRUE, datatype = datatype,
              gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2"))
  print(glue("  -> saved {out_path}"))
}

####
## 1. Current distributions (binary presence/absence: 0/1)
####
for (sp in names(kelp_layers)) {
  in_path  <- glue("{toplevel_dir}/{current_dist_dir}/{kelp_layers[[sp]]}")
  out_path <- glue("{toplevel_dir}/{processed_dir}/{current_dist_dir}/{kelp_layers[[sp]]}")
  rewrite_compact(in_path, out_path, datatype = "INT1S")
}

####
## 2. Projected redistribution change layers (-2 / -1 / 0 / 1)
####
for (scenario in names(change_layers)) {
  for (sp in names(change_layers[[scenario]])) {
    in_path  <- glue("{toplevel_dir}/{change_dist_dir}/{change_layers[[scenario]][[sp]]}")
    out_path <- glue("{toplevel_dir}/{processed_dir}/{change_dist_dir}/{change_layers[[scenario]][[sp]]}")
    rewrite_compact(in_path, out_path, datatype = "INT1S")
  }
}

####
## 3. Community compositional change -- classify once, at full resolution
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
  
  out_path <- glue("{toplevel_dir}/{processed_dir}/{community_dist_dir}/composition_{scenario_code(scenario)}.tif")
  ensure_dir(dirname(out_path))
  writeRaster(composition, out_path, overwrite = TRUE, datatype = "INT1S",
              gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2"))
  print(glue("  -> saved {out_path}"))
}

####
## 4. Environmental layers (continuous values -- keep as float)
####
for (layer_name in names(env_layers)) {
  in_path  <- glue("{toplevel_dir}/{env_dist_dir}/{env_layers[[layer_name]]}")
  out_path <- glue("{toplevel_dir}/{processed_dir}/{env_dist_dir}/{env_layers[[layer_name]]}")
  rewrite_compact(in_path, out_path, datatype = "FLT4S")
}

print("Done. All rasters rewritten at full resolution (compact datatype + compression) under:")
print(glue("{toplevel_dir}/{processed_dir}/"))
