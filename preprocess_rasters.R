
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

aggregation_factor <- function(r, maxcell) {
  n <- ncell(r)
  f <- ceiling(sqrt(n / maxcell))
  f <- max(f, 1)
  print(glue("  native cells: {n}, maxcell target: {maxcell}, aggregation factor: {f} (each output cell = {f}x{f} = {f*f} original cells)"))
  f
}

get_mode <- function(x, ...) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NA)
  shifted <- x - min(x) + 1L
  counts <- tabulate(shifted)
  min(x) + which.max(counts) - 1L
}

# Plain copy -- no modification of any kind. Used for continuous layers.
copy_unmodified <- function(in_path, out_path) {
  print(glue("Copying: {in_path}"))
  ensure_dir(dirname(out_path))
  file.copy(in_path, out_path, overwrite = TRUE)
  print(glue("  -> saved {out_path}"))
}

# For CATEGORICAL rasters: aggregate (modal) only. 
downscale_and_save <- function(in_path, out_path, datatype = "INT2S") {
  print(glue("Processing: {in_path}"))
  r <- rast(in_path)
  fact <- aggregation_factor(r, maxcell)
  r <- aggregate(r, fact = fact, fun = get_mode, na.rm = TRUE)
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
  downscale_and_save(in_path, out_path, datatype = "INT2S")
}

####
## 2. Projected redistribution change layers (-2 / -1 / 0 / 1) -- categorical
####
for (scenario in names(change_layers)) {
  for (sp in names(change_layers[[scenario]])) {
    in_path  <- glue("{toplevel_dir}/{change_dist_dir}/{change_layers[[scenario]][[sp]]}")
    out_path <- glue("{toplevel_dir}/{processed_dir}/{change_dist_dir}/{change_layers[[scenario]][[sp]]}")
    print(glue("--- {sp} / {scenario} ---"))
    r_check <- rast(in_path)
    print("  value counts BEFORE aggregation:")
    print(table(values(r_check), useNA = "ifany"))
    downscale_and_save(in_path, out_path, datatype = "INT2S")
    r_after <- rast(out_path)
    print("  value counts AFTER aggregation:")
    print(table(values(r_after), useNA = "ifany"))
  }
}

####
## 3. Community compositional change -- classify, then aggregate.
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
  
  fact <- aggregation_factor(composition, maxcell)
  composition <- aggregate(composition, fact = fact, fun = get_mode, na.rm = TRUE)
  
  out_path <- glue("{toplevel_dir}/{processed_dir}/{community_dist_dir}/composition_{scenario_code(scenario)}.tif")
  ensure_dir(dirname(out_path))
  writeRaster(composition, out_path, overwrite = TRUE, datatype = "INT2S")
  print(glue("  -> saved {out_path}"))
}

####
## 4. Environmental layers (continuous) -- mean aggregation
##    Previously just copied as-is on the assumption they were small
##    enough not to need it -- that was wrong. Same root cause as the
##    categorical layers: addRasterImage() rendering ~26 million cells
##    into a browser image is too much regardless of file size on disk.
####
downscale_continuous_and_save <- function(in_path, out_path) {
  print(glue("Processing: {in_path}"))
  r <- rast(in_path)
  fact <- aggregation_factor(r, maxcell)
  r <- aggregate(r, fact = fact, fun = "mean", na.rm = TRUE)
  ensure_dir(dirname(out_path))
  writeRaster(r, out_path, overwrite = TRUE, datatype = "FLT4S")
  print(glue("  -> saved {out_path}"))
}

for (layer_name in names(env_layers)) {
  in_path  <- glue("{toplevel_dir}/{env_dist_dir}/{env_layers[[layer_name]]}")
  out_path <- glue("{toplevel_dir}/{processed_dir}/{env_dist_dir}/{env_layers[[layer_name]]}")
  downscale_continuous_and_save(in_path, out_path)
}

print("Done. Categorical layers downscaled (native CRS, no reprojection); continuous layers copied as-is, under:")
print(glue("{toplevel_dir}/{processed_dir}/"))