library(terra)
library(maps)
library(mapdata)


# r <- rast("~/Documents/lightning/scoring-combined/20220103.tif")

map("world", add = TRUE, col = rgb(1,1,1,0.5), lwd = 1)
map("state", add = TRUE, col = rgb(1,1,1,0.1), lwd = 0.5)

map("world", add = TRUE, col = rgb(0,0,0,0.5), lwd = 1.5)
map("state", add = TRUE, col = rgb(0,0,0,0.1), lwd = 0.5)






