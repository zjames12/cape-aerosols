crps <- read.csv("crps_ensemble10nobasesummer0.6.csv")
crps$date <- as.Date(crps$date)
plot(crps$date, crps$ss, xlab="Date", ylab="CRPS Skill Score")
bs(crps$ss)

rmse <- read.csv("rmse_ensemble10nobasesummer0.6.csv")
bs(rmse$ss)


crps <- read.csv("crps_ensemble8.0summer0.6.csv")
crps$date <- as.Date(crps$date)
plot(crps$date, crps$ss, xlab="Date", ylab="CRPS Skill Score")
bs(crps$ss)

rmse <- read.csv("rmse_ensemble8.0summer0.6.csv")
bs(rmse$ss)
