library(terra)

setwd("/Users/zj/Documents/lightning/")

files <- list.files("crs", full.names = TRUE, pattern = "\\.tif$", recursive = T)
# files <- list.files("/Users/zj/Documents/lightning/scoring-combined-gefs", full.names = TRUE, pattern = "\\.tif$")
files <- files[grepl("ensemble8.0summer0.6/", files)]
# template <- rast("~/Documents/hrrr/gfs-merra-1800-2400-forecast/20160101.tif")
template <- rast("template.tif")  


crop_rast <- function(real) {
  cols_to_keep <- 37:164
  rows_to_keep <- 14:77
  
  # get resolutions
  xr <- xres(real)
  yr <- yres(real)
  
  # column boundaries
  xmin_new <- min(xFromCol(real, cols_to_keep)) - xr/2
  xmax_new <- max(xFromCol(real, cols_to_keep)) + xr/2
  
  # row boundaries
  ymax_new <- max(yFromRow(real, rows_to_keep)) + yr/2  # top edge
  ymin_new <- min(yFromRow(real, rows_to_keep)) - yr/2  # bottom edge
  
  e <- ext(xmin_new, xmax_new, ymin_new, ymax_new)
  crop(real, e)
}

template <- crop_rast(template)

for (file in files) {
  # print(file)
  r <- rast(file)
  if (ncell(r) == 13937) {
    r <- crop_rast(r)
  }
  v <- values(r)
  
  ext(r) <- ext(template)
  crs(r) <- crs(template)
  res(r) <- res(template)
  # v <- values(r1)
  # v = (v/2+0.5) * 10000
  values(r) <- v

  r <- crop(r, ext(-126.25, -66.75, 24.50, 55))
  # file = paste0(substring(file, 1, 3),"2", substring(file, 4, nchar(file)))
  # dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  # writeRaster(r, file, overwrite = TRUE)
  
  # file = paste0(substring(file, 1, 3),"_temp", substring(file, 4, nchar(file)))
  # dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  # writeRaster(r, file, overwrite = TRUE)
  
  file = paste0(substring(file, 1, 3),"2", substring(file, 4, nchar(file)))
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  writeRaster(r, file, overwrite = TRUE)
  
  print(file)
}
