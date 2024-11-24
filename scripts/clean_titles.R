# Load required libraries
library(tidyverse)  # Includes dplyr, tidyr, ggplot2, etc., for data manipulation and visualization
library(tidytext)   # For text processing and natural language processing (NLP)

# Log file setup
log_file <- "logs/clean_titles.log"
dir.create(dirname(log_file), showWarnings = FALSE)  # Ensure the logs directory exists
log_connection <- file(log_file, open = "a")

# Helper function for logging
log_message <- function(message) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  writeLines(sprintf("[%s] %s", timestamp, message), log_connection)
}

# Start logging
log_message("---- Title processing started ----")

tryCatch({
  # Read the input file
  log_message("Reading input file: data/raw/processed/articles.tsv")
  data <- read_tsv("data/raw/processed/articles.tsv")
  log_message(sprintf("Successfully loaded %d rows from input file.", nrow(data)))

  # Process titles: tokenize, clean, and group words
  log_message("Processing titles: tokenizing, cleaning, and grouping words.")
  cleaned_data <- data %>%
    # Tokenize: Break each title into individual words
    unnest_tokens(word, Title) %>%
    # Remove stop words: Common words like "the", "and" which are not meaningful for analysis
    anti_join(stop_words, by = "word") %>%
    # Remove digits: Exclude numbers from the word list
    filter(!str_detect(word, "^[0-9]+$")) %>%
    # Remove words with embedded numbers (e.g. "COVID-19" -> "COVID")
    mutate(word = str_remove_all(word, "[0-9]")) %>%
    filter(word != "") %>%  
    # Remove "words" that consist only of punctuation marks (such as "." or "..") )
    filter(!str_detect(word, "^[[:punct:]]+$")) %>%
    # Apply stemming: Reduce words to their root form (e.g., "running" -> "run")
    mutate(word = SnowballC::wordStem(word)) %>%
    # Regroup words by article: Reconstruct the cleaned title for each article
    group_by(PMID, Year) %>%
    summarise(Cleaned_Title = paste(word, collapse = " "), .groups = "drop")  # Collapse words into a single cleaned title
  log_message("Title processing completed successfully.")

  # Save the cleaned data to a TSV file
  output_file <- "data/clean/cleaned_articles.tsv"
  dir.create(dirname(output_file), showWarnings = FALSE, recursive = TRUE)
  write_tsv(cleaned_data, output_file)
  log_message(sprintf("Cleaned data saved to %s", output_file))

}, error = function(e) {
  log_message(sprintf("Error encountered: %s", e$message))
  stop(e)  # Re-throw the error after logging
}, finally = {
  # End logging
  log_message("---- Title processing ended ----")
  close(log_connection)
})