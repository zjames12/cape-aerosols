breaks <- seq(-1600, 1600, by = 320)
cols <- hcl.colors(length(breaks)-1, palette = "Blue-Red 3")
diff = deepcopy(r[[1]])
values(diff) = values(mean_no_fire - mean_fire)
plot(diff, breaks = breaks, col = cols)

breaks <- seq(-400, 400, by = 100)
cols <- hcl.colors(length(breaks)-1, palette = "Purple-Green")
removed_values3 = deepcopy(bc)
values(removed_values3) = values(acc) / 549 # 109
values(removed_values3) = values(diff)


plot(sqrt(ai_mse), range = c(0,4000))
plot(sqrt(gefs_mse), range = c(0,4000))
