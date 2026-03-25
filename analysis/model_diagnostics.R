# CRPS
crps_base <- read.csv("crps_base_crop_weighted.csv")
crps_base$ss = 1- (crps_base$ai_crps / crps_base$gefs_crps)
crps_base$date <- as.Date(crps_base$date)
plot(crps_base$date, crps_base$ss)
bs(crps_base$ss)
bs(crps_base$ss[91:304])
bs(crps_base$ss[c(1:90,305:364)])

crps <- read.csv("crps_crop_weighted.csv")
crps$ss = 1- (crps$ai_crps / crps$gefs_crps)
crps$date <- as.Date(crps$date)
plot(crps$date, crps$ss, xlab="Date", ylab="CRPS Skill Score")
bs(crps$ss)

crps_summer <- read.csv("crps_ensemble8summer0.6.csv")
crps_summer <- read.csv("crps_ensemble8.2summer0.6.csv")
crps_summer <- read.csv("crps_ensemble8.2summernoaerosol0.6.csv")
crps_summer$ss = 1- (crps_summer$ai_crps / crps_summer$gefs_crps)
crps_summer$date <- as.Date(crps_summer$date)
plot(crps_summer$date, crps_summer$ss, xlab="Date", ylab="CRPS Skill Score")
bs(crps_summer$ss)

crps_summer2 <- read.csv("crps_ensemble8.3summer0.6.csv")
crps_summer2$ss = 1- (crps_summer2$ai_crps / crps_summer2$gefs_crps)
crps_summer2$date <- as.Date(crps_summer2$date)
plot(crps_summer2$date, crps_summer2$ss, xlab="Date", ylab="CRPS Skill Score")
bs(crps_summer2$ss)

crps_gfs <- read.csv("crps_gfs_crop_weighted.csv")
crps_gfs$ss = 1- (crps_gfs$ai_crps / crps_gfs$gefs_crps)
crps_gfs$date <- as.Date(crps_gfs$date)
plot(crps_gfs$date, crps_gfs$ss, xlab="Date", ylab="CRPS Skill Score")
crps_gfs_summer <- crps_gfs[
  format(crps_gfs$date, "%Y") >= "2023" &
    format(crps_gfs$date, "%Y") <= "2025" &
    format(crps_gfs$date, "%m") >= "04" &
    format(crps_gfs$date, "%m") <= "09",
]



plot(crps_base_20$date, crps_base_20$ss, col = "blue", pch = 19, 
     xlab = "x", ylab = "y", main = "y1 and y2 vs x")
abline(h=0, lty=2)
points(crps$date, crps$ss, col = "red", pch = 19)
bs(crps_base_20$ss[91:304] - crps$ss[91:304])

# MSE
rmse_base <- read.csv("rmse_base_crop.csv")
rmse_base$date <- as.Date(rmse_base$date)
rmse_base$ss = 1- (rmse_base$ai_rmse / rmse_base$gefs_rmse)
bs(rmse_base$ss)
bs(rmse_base$ss[91:304])

rmse_summer <- read.csv("rmse_ensemble8summer0.6.csv")
rmse_summer <- read.csv("rmse_ensemble8.2noaerosolsummer0.6.csv")
rmse_summer$date <- as.Date(rmse_summer$date)
rmse_summer$ss = 1- (rmse_summer$ai_rmse / rmse_summer$gefs_rmse)
plot(rmse_summer$date, rmse_summer$ss, xlab="Date", ylab="RMSE Skill Score")
bs(rmse_summer$ss)

rmse <- read.csv("rmse_crop_corrected.csv")
rmse$date <- as.Date(rmse$date)
rmse$ss = 1- (rmse$ai_rmse / rmse$gefs_rmse)
plot(rmse$date, rmse$ss, xlab="Date", ylab="RMSE Skill Score")
bs(rmse$ss)
bs(rmse[c(455:636,819:1000,1182:1363),]$ss)


rmse_gfs <- read.csv("rmse_gfs_crop.csv")
rmse_gfs$date <- as.Date(rmse_gfs$date)
rmse_gfs$ss = 1- (rmse_gfs$ai_rmse / rmse_gfs$gefs_rmse)
rmse_gfs_summer <- rmse_gfs[
  format(rmse_gfs$date, "%Y") >= "2023" &
    format(rmse_gfs$date, "%Y") <= "2025" &
    format(rmse_gfs$date, "%m") >= "04" &
    format(rmse_gfs$date, "%m") <= "09",
]

brier <- read.csv("~/Documents/lightning/brier_crop_weighted.csv")
brier$ai_ss_99 = 1- (brier$ai_brier_99 / brier$clim_brier_99)
brier$gefs_ss_99 = 1- (brier$gefs_brier_99 / brier$clim_brier_99)
brier$ai_ss_999 = 1- (brier$ai_brier_999 / brier$clim_brier_999)
brier$gefs_ss_999 = 1- (brier$gefs_brier_999 / brier$clim_brier_999)
brier$ai_ss_9999 = 1- (brier$ai_brier_9999 / brier$clim_brier_9999)
brier$gefs_ss_9999 = 1- (brier$gefs_brier_9999 / brier$clim_brier_9999)

brier_base <- read.csv("~/Documents/lightning/brier_base_crop_weighted.csv")
brier_gfs <- read.csv("~/Documents/lightning/brier_gfs_crop_weighted.csv")


# Confidence Intervals
library(tseries)
library(np)

# l_opt <- b.star(crps_base$ai_crps)
diff = crps_base$ss
diff = crps$ss; diff = crps_gfs$ss
diff = crps_base$ai_crps - crps_base$gefs_crps
diff = crps$ai_crps - crps$gefs_crps
diff = rmse_base$ss
diff = rmse$ss; diff = rmse_gfs$ss[91:304]
diff = brier_gfs$ai_brier - brier_gfs$gefs_brier

diff = brier$ai_ss_99 - brier$gefs_ss_99
diff = brier$ai_ss_999 - brier$gefs_ss_999
diff = brier$ai_ss_9999 - brier$gefs_ss_9999

adf.test(diff)

