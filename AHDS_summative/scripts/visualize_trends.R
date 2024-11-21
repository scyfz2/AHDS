# Set CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Check and install necessary packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, tidytext)


# Logging setup
log_file <- "logs/visualization.log"
dir.create(dirname(log_file), showWarnings = FALSE)  # Ensure logs directory exists
log_connection <- file(log_file, open = "a")

log_message <- function(message) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  writeLines(sprintf("[%s] %s", timestamp, message), log_connection)
}

# Start logging
log_message("---- Visualization process started ----")

# File path for cleaned articles
file_path <- "data/processed/cleaned_articles.tsv"

# Check if the file exists
if (!file.exists(file_path)) {
  log_message(sprintf("Error: File '%s' does not exist.", file_path))
  stop(sprintf("File '%s' does not exist. Please check the file path.", file_path))
}

# Load the cleaned articles data
log_message("Reading cleaned articles data.")
articles <- read_tsv(file_path, col_names = TRUE)  # Ensure header row is read correctly

if (nrow(articles) == 0) {
  log_message("Error: The file contains no data.")
  stop("The file contains no data. Cannot proceed.")
}

log_message(sprintf("Successfully loaded %d rows of data.", nrow(articles)))

# Prepare the data for visualization
log_message("Preparing data for visualization.")
word_trends <- articles %>%
  unnest_tokens(word, Cleaned_Title) %>%  # Tokenize titles into individual words
  count(Year, word, sort = TRUE) %>%      # Count word occurrences by year
  group_by(word) %>%
  mutate(total_count = sum(n)) %>%        # Calculate total count for each word
  ungroup() %>%
  filter(total_count > 1)  # Filter words that appear at least 10 times overall

if (nrow(word_trends) == 0) {
  log_message("Error: No words meet the frequency threshold for visualization.")
  stop("No words meet the frequency threshold for visualization.")
}

# Select top 10 most frequent words
log_message("Selecting top 10 most frequent words.")
top_words <- word_trends %>%
  group_by(word) %>%
  summarize(total_count = sum(n)) %>%
  arrange(desc(total_count)) %>%
  slice_head(n = 10) %>%
  pull(word)

# Visualize the trends of the most frequent words
log_message("Creating visualization.")
plot <- word_trends %>%
  filter(word %in% top_words) %>%  # Filter top words
  ggplot(aes(x = Year, y = n, color = word, group = word)) +
  geom_line(size = 1) +
  labs(
    title = "Trends in Word Frequency Over Time",
    x = "Year",
    y = "Frequency",
    color = "Word"
  ) +
  theme_minimal()

# Save the plot
output_plot <- "output/word_trends_over_time.png"
dir.create(dirname(output_plot), showWarnings = FALSE)  # Ensure output directory exists
ggsave(output_plot, plot, width = 10, height = 6)

log_message(sprintf("Visualization saved to '%s'.", output_plot))
log_message("---- Visualization process completed ----")
close(log_connection)
