library(terra)

template <- rast("images-2300-cape-aerosols/20150701.tif")

aod <- rast("merra19990710.nc")
aod <- aod[[c(1,3,5,7,9)]]

aod <- crop(aod, ext(template))
aod <- project(aod, template)

cape <- rast("cape199907.nc")
crs(cape) <- "EPSG:4326"
cape <- crop(cape, ext(template))
cape <- project(cape, template)

test_data <- c(aod,cape[[c(1,2)]])
writeRaster(test_data, paste("test-images/", "19990710", ".tif", sep=""), overwrite = TRUE)

r <- rast()


cols_to_keep <- 1:128
rows_to_keep <- (nrow(cape) - 64 + 1):nrow(cape)
rows_to_keep <- 1:64
x_coords <- xFromCol(cape, cols_to_keep)
y_coords <- yFromRow(cape, rows_to_keep)
e <- ext(min(x_coords), max(x_coords), min(y_coords), max(y_coords))
cape <- crop(cape, e)
