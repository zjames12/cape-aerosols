acc = NULL
noaerosol_mse = c()
ai_mse =c()
bc = c()
du = c()
oc = c()
ss = c()
su = c()
actual_mean_cape = c()
rm = c()
rm_day = c()

days = seq.Date(from = as.Date("2023-04-01"), to = as.Date("2023-09-30"), by = "day")
days = c(days, seq.Date(from = as.Date("2024-04-01"), to = as.Date("2024-09-30"), by = "day"))
days = c(days, seq.Date(from = as.Date("2025-04-01"), to = as.Date("2025-09-30"), by = "day"))

for (i in seq_along(days)) {
  day = as.Date("2025-05-24")
  day <- days[i]
  
  
  
  tryCatch({
    # print(day)
    ai <- rast(list.files(paste0("~/Documents/lightning/crs2/", format(day, "%Y%m%d"), "/ensemble8.1.500.0.6"), full.names = TRUE, pattern = "\\.tif$"))
    gfs <- rast(list.files(paste0("~/Documents/lightning/crs2/", format(day, "%Y%m%d"), "/gfs"), full.names = TRUE, pattern = "\\.tif$"))
    gefs <- rast(list.files(paste0("~/Documents/lightning/crs2/", format(day, "%Y%m%d"), "/gefs"), full.names = TRUE, pattern = "\\.tif$"))
    # ai <- rast(list.files(paste0("~/Documents/lightning/crs2/", format(day, "%Y%m%d"), "/ensemble8summer0.6"), full.names = TRUE, pattern = "\\.tif$"))
    # noaerosol <- rast(list.files(paste0("~/Documents/lightning/crs2-7/", format(day, "%Y%m%d"), "/ensemble8.1.500.0.6"), full.names = TRUE, pattern = "\\.tif$"))
    noaerosol <- rast(list.files(paste0("~/Documents/lightning/crs2/", format(day, "%Y%m%d"), "/ensemble8.2noaerosolsummer0.6"), full.names = TRUE, pattern = "\\.tif$"))
    # noaerosol <- rast(list.files(paste0("~/Documents/lightning/crs2/", format(day, "%Y%m%d"), "/ensemble8.1noaerosolsummer0.6"), full.names = TRUE, pattern = "\\.tif$"))
    
    actual <- rast(list.files(paste0("~/Documents/lightning/crs2/", format(day, "%Y%m%d"), "/c00"), full.names = TRUE, pattern = "\\.tif$"))
    
    # gefs = mean(gefs)
    ai = mean(ai)
    noaerosol = mean(noaerosol)
    
    
    # mean_fire = app(fire, sd, na.rm = TRUE)
    # mean_no_fire = app(no_fire, sd, na.rm = TRUE)
    noaerosol_mse = c(noaerosol_mse, mean(values((actual - noaerosol))))
    ai_mse = c(ai_mse, mean(values((actual - ai))))
  },
  error = function(e) {print(day)}
  )
  
}
print(mean(ai_mse))
print(mean(noaerosol_mse))

