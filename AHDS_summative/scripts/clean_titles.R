# Load required libraries
library(tidyverse)  # Includes dplyr, tidyr, ggplot2, etc., for data manipulation and visualization
library(tidytext)   # For text processing and natural language processing (NLP)

# Read the input file
data <- read_tsv("data/processed/articles.tsv")  # Load the articles data from a TSV file

# Process titles: tokenize, clean, and group words
cleaned_data <- data %>%
  # Tokenize: Break each title into individual words
  unnest_tokens(word, Title) %>%
  # Remove stop words: Common words like "the", "and" which are not meaningful for analysis
  anti_join(stop_words, by = "word") %>%
  # Remove digits: Exclude numbers from the word list
  filter(!str_detect(word, "^[0-9]+$")) %>%
  # Apply stemming: Reduce words to their root form (e.g., "running" -> "run")
  mutate(word = SnowballC::wordStem(word)) %>%
  # Regroup words by article: Reconstruct the cleaned title for each article
  group_by(PMID, Year) %>%
  summarise(Cleaned_Title = paste(word, collapse = " "), .groups = "drop")  # Collapse words into a single cleaned title

# Save the cleaned data to a TSV file
write_tsv(cleaned_data, "data/processed/cleaned_articles.tsv")

# Print a success message
message("Processing completed. Cleaned data saved to data/processed/cleaned_articles.tsv.")
