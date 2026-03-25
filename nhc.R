# Read the file as plain text
lines <- readLines("nhc.txt")

# Keep only lines that start with a date (YYYYMMDD)
data_lines <- lines[grepl("^\\d{8}", lines)]

# Optional: write cleaned lines to a new file
writeLines(data_lines, "nhc.csv")

nhc <- read.csv("nhc.csv", header= F)
