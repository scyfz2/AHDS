library(xml2)
library(dplyr)
library(tidyr)
library(stringr)

# Read arguments from command line
args <- commandArgs(trailingOnly = TRUE)
input_dir <- args[1]      # Directory containing input XML files
output_file <- args[2]    # Output file path

# Create output directory if not exists
dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)

# Initialize an empty data frame
results <- data.frame(PMID = character(), Year = character(), Title = character(), stringsAsFactors = FALSE)

# Loop through all XML files in the input directory
files <- list.files(input_dir, pattern = "\\.xml$", full.names = TRUE)

for (file in files) {
    # Parse XML file
    doc <- read_xml(file)
    
    # Extract PMID, Year, and Title
    pmid <- str_extract(basename(file), "\\d+")
    year <- xml_text(xml_find_first(doc, "//PubDate/Year"))
    title <- xml_text(xml_find_first(doc, "//ArticleTitle")) %>% str_remove_all("<[^>]+>")
    
    # Skip if title is empty
    if (is.na(title) || title == "") {
        message("Skipping ", pmid, ": No title found.")
        next
    }
    
    # Append to results
    results <- rbind(results, data.frame(PMID = pmid, Year = year, Title = title))
}

# Write results to TSV file
write.table(results, file = output_file, sep = "\t", row.names = FALSE, quote = FALSE)
message("Processing completed. Data saved to ", output_file)
