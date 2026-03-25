library(terra)
library(maps)
library(RColorBrewer)
setwd("~/Documents/lightning")

# real <- rast("images-2300-cape-aerosols-hrrr/20150701.tif")
real <- rast("~/Documents/hrrr/gfs-merra-1800-2400-forecast/20150701.tif")

# keep 128 columns × 64 rows
cols_to_keep <- (36):(164)
# rows_to_keep <- (nrow(real) - 128 + 1):nrow(real)
rows_to_keep <- (nrow(real) - 64):nrow(real)
# rows_to_keep <- 1:64
# Get coordinates for those cells
x_coords <- xFromCol(real, cols_to_keep)
y_coords <- yFromRow(real, rows_to_keep)

e <- ext(min(x_coords), max(x_coords), min(y_coords), max(y_coords))
real <- crop(real, e)
plot(real)

par(mfrow=c(3,3))
plot(real[[7]], range = c(0,5000), legend = FALSE)
map("world", add = TRUE, col = "white", lwd = 1)
files <- list.files("~/Documents/lightning/gfs-samples/20150701", full.names = TRUE, pattern = "\\.tiff$")
for (file in files[7:14]){
  pred <- rast(file)
  pred <- flip(pred, direction = "vertical")
  ext(pred) <- ext(real)
  plot(pred, range = c(0,5000), legend = FALSE)
  map("world", add = TRUE, col = "white", lwd = 1)
}
plot(real[[3]], col = colorRampPalette(brewer.pal(9, "YlOrRd"))(100))
map("world", add = TRUE, col = "black", lwd = 1)

plot(real[[6]], range = c(0,5000), legend = FALSE)


# July 15, 2023
real <- rast("~/Documents/hrrr/gfs-merra-1800-2400-forecast/20160101.tif")
# real <- rast("images-2300-cape-aerosols/20150701.tif")
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
files <- list.files("~/Documents/lightning/gfs-samples/20150701_zero_intervention", full.names = TRUE, pattern = "\\.tiff$")
files <- list.files("~/Documents/lightning/crs/20220101/ensemble2", full.names = TRUE)
layout(matrix(1:9, nrow=3, byrow=TRUE),
       heights = rep(1, 3),   # each row same height
       widths  = rep(1, 3))
plot(real[[8]], range = c(0,6000), axes=F, legend = T)#, mar=c(1,1,1,1), box=FALSE)
map("world", add = TRUE, col = rgb(1,1,1,0.5), lwd = 1)
map("state", add = TRUE, col = rgb(1,1,1,0.1), lwd = 0.5)
# map("state", add = TRUE, col = "white", lwd = 0.5)
print(max(values(real[[8]])))
for (file in files[c(1:9)]){
  pred <- rast(file)
  # pred <- crop_rast(pred)
  ext(pred) <- ext(real)
  # crs(pred) <- crs(real)
  print(max(values(pred)))
  
  plot(pred, range = c(0,2000), legend = FALSE, oma=c(.1,.1,.1,.1),mar=c(.1,.1,.1,.1), axes=F, box=FALSE)
  map("world", add = TRUE, col = rgb(1,1,1,0.5), lwd = 1)
  map("state", add = TRUE, col = rgb(1,1,1,0.1), lwd = 0.5)
  # writeRaster(pred, paste("crs/20230715/ensemble/", basename(file), sep=""))
}
par(mfrow=c(1,1))
