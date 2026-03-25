# Load packages
library(httr)
library(jsonlite)
library(terra)

# --- CONFIG ---
user <- "zj37"
pwd  <- "December_9th"
day  <- "2024-07-01"   # <-- pick your day
sat  <- "G16"          # GOES-16 or G17, G18
outdir <- "GLM_L3_downloads"

dir.create(outdir, showWarnings = FALSE)
for (i in 1:1) {
  
  # Format start/end datetimes in UTC
  start_time <- paste0(day, "T00:00:00Z")
  end_time   <- paste0(as.Date(day), "T00:05:00Z")
  
  # GHRC DAAC GLM L3 collection concept ID
  concept_id <- "C2278812167-GHRC_DAAC"
  
  # Build CMR query URL
  base_url <- "https://cmr.earthdata.nasa.gov/search/granules.json"
  query <- list(
    concept_id = concept_id,
    temporal   = paste0(start_time, ",", end_time),
    provider   = "GHRC_DAAC",
    page_size  = 2000    # enough for all 1440 files in a day
  )
  
  # Request granule metadata
  res <- GET(base_url, query = query)
  stop_for_status(res)
  
  granules <- fromJSON(content(res, as = "text"))
  
  # Extract .nc download URLs
  # Extract .nc URLs robustly
  entries <- granules$feed$entry$links
  
  urls <- unlist(lapply(entries, function(links) {
    if (!is.null(links) && is.data.frame(links)) {
      nc_links <- subset(
        links,
        rel == "http://esipfed.org/ns/fedsearch/1.1/data#" & grepl("\\.nc$", href)
      )
      return(nc_links$href)
    } else {
      return(character(0))
    }
  }))
  
  
  # Filter only for chosen satellite (e.g. G16)
  # urls <- urls[grepl(sat, urls)]
  urls <- urls[grepl(sat, urls) & grepl("GLMF-M6", urls)]
  
  cat("Found", length(urls), "files for", day, "(", sat, ")\n")
  r <- NA
  first = TRUE
  # Download loop
  t <- proc.time()
  for (u in urls) {
    fname <- file.path(outdir, basename(u))
    if (!file.exists(fname)) {
      cat("Downloading:", fname, "\n")
      GET(u, authenticate(user, pwd),
          write_disk(fname, overwrite = TRUE))
    }
    if (first) {
      r <- rast(fname)
      r <- r$Flash_extent_density
      r <- ifel(is.na(r), 0, r)
      first = FALSE
    } else {
      r1 = rast(fname)$Flash_extent_density
      r1 <- ifel(is.na(r1), 0, r1)
      r = r + r1
    }
    file.remove(fname)
    
  }
  tt <- proc.time()
  print(tt - t)
  writeCDF(r, paste(day,"-gridded.nc",sep = ""), overwrite=TRUE)
}
files <- list.files("GLM_L3_downloads", full.names = TRUE)
file.remove(files)
