# Load necessary libraries
library(xml2)
library(dplyr)
library(readr)
library(stringr)

# Log file setup
log_file <- "logs/process_articles.log"
dir.create(dirname(log_file), showWarnings = FALSE) # Create logs directory if it doesn't exist
log_connection <- file(log_file, open = "a")
writeLines(sprintf("---- Process started at: %s ----", Sys.time()), log_connection)

# Log helper function
log_message <- function(message) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  writeLines(sprintf("[%s] %s", timestamp, message), log_connection)
}

# Arguments
args <- commandArgs(trailingOnly = TRUE)
input_dir <- args[1]
output_file <- args[2]

log_message(paste("Input directory:", input_dir))
log_message(paste("Output file:", output_file))

# Results storage
results <- data.frame(PMID = character(), Year = character(), Title = character(), stringsAsFactors = FALSE)

# Process files
files <- list.files(input_dir, pattern = "\\.xml$", full.names = TRUE)
log_message(paste("Found", length(files), "XML files to process."))

for (file in files) {
  log_message(paste("Processing file:", file))
  
  # Skip empty files
  if (file.size(file) == 0) {
    log_message(paste("Skipping empty file:", file))
    next
  }

  # Try parsing XML
  doc <- tryCatch({
    read_xml(file)
  }, error = function(e) {
    log_message(paste("Error parsing file:", file, "-", e$message))
    return(NULL)
  })

  # Skip files that failed to parse
  if (is.null(doc)) next

  # Extract relevant fields
  pmid <- str_extract(basename(file), "\\d+")
  year <- xml_text(xml_find_first(doc, "//PubDate/Year"))
  title <- xml_text(xml_find_first(doc, "//ArticleTitle"))

  # Log extracted data
  log_message(paste("Extracted PMID:", pmid, "Year:", year, "Title:", ifelse(is.na(title), "N/A", title)))

  # Skip if title is missing
  if (is.na(title) || title == "") {
    log_message(paste("Skipping file with no title:", file))
    next
  }

  # Add to results
  results <- rbind(results, data.frame(PMID = pmid, Year = year, Title = title))
}

# Save results
write_tsv(results, file = output_file)
log_message(paste("Processing completed. Data saved to", output_file))

# End log
writeLines(sprintf("---- Process completed at: %s ----", Sys.time()), log_connection)
close(log_connection)
