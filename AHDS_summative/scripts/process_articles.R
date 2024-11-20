# Load necessary libraries
library(xml2)
library(dplyr)
library(readr)
library(stringr)

args <- commandArgs(trailingOnly = TRUE)
input_dir <- args[1]
output_file <- args[2]

results <- data.frame(PMID = character(), Year = character(), Title = character(), stringsAsFactors = FALSE)

# Loop through all XML files
files <- list.files(input_dir, pattern = "\\.xml$", full.names = TRUE)

for (file in files) {
    # Skip empty files
    if (file.size(file) == 0) {
        message("Skipping empty file: ", file)
        next
    }

    # Try parsing XML
    doc <- tryCatch({
        read_xml(file)
    }, error = function(e) {
        message("Error parsing file: ", file, " - ", e$message)
        return(NULL)
    })

    # Skip files that failed to parse
    if (is.null(doc)) next

    # Extract relevant fields
    pmid <- str_extract(basename(file), "\\d+")
    year <- xml_text(xml_find_first(doc, "//PubDate/Year"))
    title <- xml_text(xml_find_first(doc, "//ArticleTitle"))

    # Skip if title is missing
    if (is.na(title) || title == "") {
        message("Skipping file with no title: ", file)
        next
    }

    # Add to results
    results <- rbind(results, data.frame(PMID = pmid, Year = year, Title = title))
}

# Save results
write_tsv(results, file = output_file)
message("Processing completed. Data saved to ", output_file)
