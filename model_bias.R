library(terra)

removed_aods = c()
kept_aods = c()
removed_capes = c()
kept_capes = c()
total_capes = c()
t.values = c()
dates = c()
diffs = c()

days = seq.Date(from = as.Date("2023-04-01"), to = as.Date("2023-09-30"), by = "day")
days = c(days, seq.Date(from = as.Date("2024-04-01"), to = as.Date("2024-09-30"), by = "day"))
days = c(days, seq.Date(from = as.Date("2025-04-01"), to = as.Date("2025-09-30"), by = "day"))

for (i in seq_along(days)) {
  
  day = as.Date("2025-06-08")
  day <- days[i]
  
  tryCatch({
    print(day)
    
    fire <- rast(list.files(paste0("~/Documents/lightning/crs2/", format(day, "%Y%m%d"), "/ensemble8.2summer0.6"), full.names = TRUE, pattern = "\\.tif$"))
    no_fire <- rast(list.files(paste0("~/Documents/lightning/crs2/", format(day, "%Y%m%d"), "/gefs"), full.names = TRUE, pattern = "\\.tif$"))
    bc <- rast(paste0("/Users/zj/Documents/lightning/scoring-combined/",format(day, "%Y%m%d"),".tif"))[[2]]
    cape <- rast(paste0("/Users/zj/Documents/lightning/scoring-combined/",format(day, "%Y%m%d"),".tif"))
    mask <- rast(paste0("~/Documents/wildfires/masks/", format(day, "%Y%m%d"),".tif"))
    
    mean_fire = mean(fire)
    mean_no_fire = mean(no_fire)
    
    m1 <- sapply(fire, function(r) global(r, mean, na.rm = TRUE)[1]$mean)
    m2 <- sapply(no_fire, function(r) global(r, mean, na.rm = TRUE)[1]$mean)
    test <- t.test(m1, m2, paired = FALSE)
    t.values <- c(t.values, test$statistic)
    dates <- c(dates, format(day, "%Y-%m-%d"))
    diffs <- c(diffs, mean(values(mean_fire - mean_no_fire)))
    
    
    bc_values <- values(bc)
    mask_values <- values(mask)
    removed_aod <- mean(bc_values[mask_values == 1], na.rm = TRUE)
    kept_aod <- mean(bc_values[mask_values == 0], na.rm = TRUE)
    removed_aods <- c(removed_aods, removed_aod)
    kept_aods <- c(kept_aods, kept_aod)
    removed_cape <- mean(values(cape)[mask_values == 1], na.rm = TRUE)
    kept_cape <- mean(values(cape)[mask_values == 0], na.rm = TRUE)
    total_cape <- mean(values(cape), na.rm = TRUE)
    removed_capes <- c(removed_capes, mean(values(mean_no_fire)))
    kept_capes <- c(kept_capes, mean(values(mean_fire)))
    total_capes <- c(total_capes, total_cape)
  },
  error = function(e) {print(e)}
  )
  
}

df <- data.frame(dates = dates, t_values = t.values, diffs = diffs, removed_aods = removed_aods,
                 kept_aods = kept_aods, removed_capes = removed_capes, kept_capes = kept_capes,
                 total_capes = total_capes)
breaks <- seq(-3000, 3000, by = 500)
breaks <- seq(-1200, 1200, by = 200)
cols <- hcl.colors(length(breaks)-1, palette = "Red-Green")
diff = actual - gefs
diff = ai - noaerosol
plot(diff, breaks = breaks, col = cols)
