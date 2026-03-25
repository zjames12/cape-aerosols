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
