library(ggplot2)

setwd("C:/Users/Zach/Documents/lightning")

# df25 <- readRDS("2025-07-noon.rds")
# df24 <- readRDS("2024-07-noon.rds")
# df23 <- readRDS("2023-07-noon.rds")
# df238 <- readRDS("2023-08-noon.rds")
# df248 <- readRDS("2024-08-noon.rds")

df <- readRDS("20022020.rds")
# df <- df[df$x > -96 & df$x < -87 & df$y > 36 & df$y < 40,]
# df <- df[df$x > -80 & df$x < -73 & df$y > 40 & df$y < 45,]


# df <- rbind(df23, df24, df25, df238, df248)
# df_2023 <- readRDS("2023-1500.rds")
# df_2024 <- readRDS("2024-1500.rds")
# df_2025 <- readRDS("2025-1500.rds")
# df <- rbind(df_2023[,c(1:9,12,13)], df_2024, df_2025)
# df$total = rowSums(df[,4:8])
# df <- df[df$x > -105 & df$x < -90 & df$y > 34 & df$y < 50,]
# plot(rowSums(df[,4:8]), df$lightning, xlim = c(0,1))

cols <- colorRampPalette(c("blue", "green", "red"))(100)  # define gradient

# Total
max_val = quantile(df$total, .99)
dx = max_val / 100
bins <- cut(df$total, breaks = seq(0, max_val, by = dx), include.lowest = TRUE)
avg_lat <- tapply(df$y, bins, mean)
avg_lon <- tapply(df$x, bins, mean)
avg_y <- tapply(df$lightning, bins, mean)
plot(bin_mids <- seq(dx/2, max_val-dx/2, by = dx), avg_y, 
     pch = 19, #col=cols[cut(avg_lat, breaks=100, labels=FALSE)],#ylim = c(0,60), 
     xlab = "Total AOD",
     ylab = "Average Number of Lightning Strikes")


# Black carbon
max_val = quantile(df$bc, .99)
dx = max_val / 100
bins <- cut(df$bc, breaks = seq(0, max_val, by = dx), include.lowest = TRUE)
avg_lat <- tapply(df$y, bins, mean)
avg_y <- tapply(df$lightning, bins, mean)
plot(bin_mids <- seq(dx/2, max_val-dx/2, by = dx), avg_y, #ylim = c(0,50),
     pch = 19, #col=cols[cut(avg_lat, breaks=100, labels=FALSE)],
     xlab = "Black carbon AOD",
     ylab = "Average Number of Lightning Strikes")

# Dust
max_val = quantile(df$du, .90)
dx = max_val / 100
bins <- cut(df$du, breaks = seq(0, max_val, by = dx), include.lowest = TRUE)
avg_y <- tapply(df$lightning, bins, mean)
plot(bin_mids <- seq(dx/2, max_val-dx/2, by = dx), avg_y,
     pch = 19, #ylim = c(0,30),
     xlab = "Dust AOD",
     ylab = "Average Number of Lightning Strikes")

# Organic carbon
max_val = quantile(df$oc, .90)
dx = max_val / 100
bins <- cut(df$oc, breaks = seq(0, max_val, by = dx), include.lowest = TRUE)
avg_y <- tapply(df$lightning, bins, mean)
plot(bin_mids <- seq(dx/2, max_val-dx/2, by = dx), avg_y,
     pch = 19,
     xlab = "Organic carbon AOD",
     ylab = "Average Number of Lightning Strikes")

# Sea salt
max_val = quantile(df$ss, .95)
dx = max_val / 100
bins <- cut(df$ss, breaks = seq(0, max_val, by = dx), include.lowest = TRUE)
avg_y <- tapply(df$lightning, bins, mean)
plot(bin_mids <- seq(dx/2, max_val-dx/2, by = dx), avg_y,
     pch = 19,
     xlab = "Sea salt AOD",
     ylab = "Average Number of Lightning Strikes")

# Sulfates
max_val = quantile(df$su, .95)
dx = max_val / 100
bins <- cut(df$su, breaks = seq(0, max_val, by = dx), include.lowest = TRUE)
avg_y <- tapply(df$lightning, bins, mean)
plot(bin_mids <- seq(dx/2, max_val-dx/2, by = dx), avg_y,
     pch = 19,
     xlab = "Sulfates AOD",
     ylab = "Average Number of Lightning Strikes")

# Cape
max_val = quantile(df$cape, .95)
dx = max_val / 100
bins <- cut(df$cape, breaks = seq(0, max_val, by = dx), include.lowest = TRUE)
avg_y <- tapply(df$lightning, bins, mean)
plot(bin_mids <- seq(dx/2, max_val-dx/2, by = dx), avg_y,
     pch = 19,
     xlab = "CAPE",
     ylab = "Average Number of Lightning Strikes")

# Angstrom
max_val = quantile(df$angstrom, .99)
dx = max_val / 100
bins <- cut(df$angstrom, breaks = seq(0, max_val, by = dx), include.lowest = TRUE)
avg_y <- tapply(df$lightning, bins, mean)
plot(bin_mids <- seq(dx/2, max_val-dx/2, by = dx), avg_y,
     pch = 19,
     xlab = "Angstrom Exponent",
     ylab = "Average Number of Lightning Strikes")


## CAPE Plots

# Black carbon
max_val = quantile(df$SUEXTTAU, .99)
dx = max_val / 200
bins <- cut(df$SUEXTTAU, breaks = seq(0, max_val, by = dx), include.lowest = TRUE)
# avg_lat <- tapply(df$y, bins, mean)
# sd_lat <- tapply(df$y, bins, sd)
# avg_lon <- tapply(df$x, bins, mean)
# sd_lon <- tapply(df$x, bins, sd)
avg_y <- tapply(df$CAPE, bins, mean)
# sd_y <- tapply(df$CAPE, bins, sd)
# n_y <- tapply(df$CAPE, bins, length)
# se_y = sd_y / sqrt(n_y)
bin_mids <- seq(dx/2, max_val-dx/2, by = dx)
A = na.omit(data.frame(bin_mids, avg_y))
ggplot(A, aes(x = bin_mids, y = avg_y)) +
  geom_point() +
  ylab("Average CAPE") +
  xlab("Sulfate AOD") + 
  # ylim(c(0,300)) +
  theme_bw()
A = na.omit(data.frame(bin_mids, avg_y, avg_lon, avg_lat, n_y, sd_lon, sd_lat))
ggplot(A, aes(x = bin_mids, y = avg_y)) +
  geom_point() +
  ylab("Average CAPE") +
  xlab("Dust AOD") + 
  # ylim(c(0,800)) +
  theme_bw()
ggplot(A, aes(x = bin_mids, y = avg_y, color = avg_lon > -100 & avg_lon < -95 &
              avg_lat > 42 & avg_lat < 45)) +
  geom_point() +
  ylab("Average CAPE") +
  xlab("Black carbon AOD") + 
  ylim(c(0,800)) +
  # scale_color_gradientn(colours = rainbow(5)) +
  # guides(colour = guide_colourbar(title = "Avg. Longitude")) +
  guides(colour = guide_legend(title = "Avg. Longitude")) +
  theme_bw()

ggplot(A, aes(x = bin_mids, y = avg_y, color = sd_lat)) +
  geom_point() +
  ylab("Average CAPE") +
  xlab("Black carbon AOD") + 
  ylim(c(0,800)) +
  scale_color_gradientn(colours = rainbow(5)) +
  guides(colour = guide_colourbar(title = "Std. Dev. Latitude")) +
  theme_bw()

ggplot(data=A, aes(x=bin_mids, y=avg_y, ymin=avg_y-1.96*se_y, ymax=avg_y+1.96*se_y)) + 
  geom_line() + 
  geom_ribbon(alpha=0.5) + 
  scale_y_log10() + 
  ylab("Scaled Temperature") +
  theme_bw()

# Dust
max_val = quantile(df$du, .90)
dx = max_val / 100
bins <- cut(df$du, breaks = seq(0, max_val, by = dx), include.lowest = TRUE)
avg_y <- tapply(df$cape, bins, mean)
plot(bin_mids <- seq(dx/2, max_val-dx/2, by = dx), avg_y,
     pch = 19, #ylim = c(0,30),
     xlab = "Dust AOD",
     ylab = "Average Number of Lightning Strikes")

# Organic carbon
max_val = quantile(df$oc, .90)
dx = max_val / 100
bins <- cut(df$oc, breaks = seq(0, max_val, by = dx), include.lowest = TRUE)
avg_y <- tapply(df$cape, bins, mean)
plot(bin_mids <- seq(dx/2, max_val-dx/2, by = dx), avg_y,
     pch = 19,
     xlab = "Organic carbon AOD",
     ylab = "Average Number of Lightning Strikes")

# Sea salt
max_val = quantile(df$SSEXTTAU, .99)
dx = max_val / 100
bins <- cut(df$SSEXTTAU, breaks = seq(0, max_val, by = dx), include.lowest = TRUE)
avg_y <- tapply(df$CAPE, bins, mean)
plot(bin_mids <- seq(dx/2, max_val-dx/2, by = dx), avg_y,
     pch = 19,
     xlab = "Sea salt AOD",
     ylab = "Average Number of Lightning Strikes")

# Sulfates
max_val = quantile(df$SUEXTTAU, .99)
dx = max_val / 100
bins <- cut(df$SUEXTTAU, breaks = seq(0, max_val, by = dx), include.lowest = TRUE)
avg_y <- tapply(df$CAPE, bins, mean)
plot(bin_mids <- seq(dx/2, max_val-dx/2, by = dx), avg_y,
     pch = 19,
     xlab = "Sulfates AOD",
     ylab = "Average Number of Lightning Strikes")
