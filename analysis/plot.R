library(fields)

par(mar = c(5, 4, 4, 6))  # extra space on the right

z <- crps_summer$other[1:183]#crps$other
cols <- viridis::viridis(100)
z_col <- cols[cut(z, 100, include.lowest = TRUE)]

plot(
  crps_summer$date[1:183],
  crps_summer$ss[1:183],
  col = z_col,
  pch = 19,
  xlab = "Date",
  ylab = "CRPS Skill Score"
)

image.plot(
  legend.only = TRUE,
  zlim = range(z, na.rm = TRUE),
  col = cols,
  legend.lab = "Mean CAPE",
  add = TRUE
)
abline(h=0, lty=2)

# par(mar = c(5, 4, 4, 6))  # extra space on the right
# 
# z <- rmse_summer$other[1:183] #crps$other
# cols <- viridis::viridis(100)
# z_col <- cols[cut(z, 100, include.lowest = TRUE)]
# 
# plot(
#   rmse_summer$date[1:183],
#   rmse_summer$ss[1:183],
#   col = z_col,
#   pch = 19,
#   xlab = "Date",
#   ylab ="RMSE Skill Score",
#   # ylim = c(0,400)
# )
# 
# image.plot(
#   legend.only = TRUE,
#   zlim = range(z, na.rm = TRUE),
#   col = cols,
#   legend.lab = "Mean CAPE",
#   add = TRUE
# )
# abline(h=0, lty=2)
