library(tidyverse)
library(tidytext)
library(topicmodels)
library(reshape2)
library(ggplot2)

# Log file setup
log_file <- "logs/word_frequency.log"
dir.create(dirname(log_file), showWarnings = FALSE)  # Ensure the logs directory exists
log_connection <- file(log_file, open = "a")

# Helper function for logging
log_message <- function(message) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  writeLines(sprintf("[%s] %s", timestamp, message), log_connection)
}

# Start logging
log_message("---- Word frequency analysis started ----")


# Load data
log_message("Reading input file: data/clean/cleaned_articles.tsv")
data <- read_tsv("data/clean/cleaned_articles.tsv")
log_message(sprintf("Successfully loaded %d rows from input file.", nrow(data)))

dir.create("plots", showWarnings = FALSE)  # Ensure directory for plots exists

# Data preprocessing
log_message("Starting data cleaning and missing values handling")
data <- data %>% 
  select(Year, Cleaned_Title) %>% 
  drop_na() %>% 
  rename(year = Year, title = Cleaned_Title)

### 2. Word Frequency Analysis

# Group and merge text by year
log_message("Starting grouping and merging text by year")
all_words_by_year <- data %>%
  group_by(year) %>%
  summarise(text = paste(title, collapse = " "))

# Calculate word frequencies by year
log_message("Calculating word frequencies by year")
word_frequencies_by_year <- all_words_by_year %>%
  unnest_tokens(word, text) %>%
  filter(!word %in% stop_words) %>%
  count(year, word) %>%
  spread(key = word, value = n, fill = 0)

# Calculate the top 10 words over time
word_totals <- colSums(word_frequencies_by_year[-1])
top_words <- names(sort(word_totals, decreasing = TRUE))[1:10]
word_trends_top <- word_frequencies_by_year %>%
  select(year, all_of(top_words)) %>%
  gather(key = "word", value = "frequency", -year)

# Data cleaning: ensure valid years and frequencies
word_trends_top <- word_trends_top %>%
  drop_na() %>%  
  filter(frequency >= 0 & year >= 2019 & year <= 2026)  

### 3. Plotting Word Frequency Trends

# Order words by total frequency, adjust legend order
word_order <- word_trends_top %>%
  group_by(word) %>%
  summarise(total_frequency = sum(frequency)) %>%
  arrange(desc(total_frequency)) %>%
  pull(word)

# Set word order as a factor (sorted by frequency)
word_trends_top <- word_trends_top %>%
  mutate(word = factor(word, levels = word_order))

# Plotting the word frequency trends
log_message("Starting to plot word frequency trends")
gg <- ggplot(word_trends_top, aes(x = year, y = frequency, color = word, group = word)) +
  geom_line(linewidth = 1.2, alpha = 0.8) +  # Adjust line thickness and transparency
  scale_color_viridis_d(option = "plasma", begin = 0, end = 0.9) +  # Optimize color
  scale_x_continuous(
    breaks = seq(2019, 2026, by = 1),  # Focus years from 2019 to 2026
    limits = c(2019, 2026)  # Compress the timeline range
  ) +
  labs(
    title = "Word Frequency Trends from 2019 to 2026",
    x = "Year",
    y = "Frequency",
    color = "Words"
  ) +
  theme_minimal() +
  theme(
    legend.position = "right",
    legend.title = element_text(size = 12),
    legend.text = element_text(size = 10),
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(hjust = 0.5, size = 16)
  ) +
  guides(color = guide_legend(reverse = FALSE))

ggsave("plots/Word_Frequency_Trends_2019-2026.png", width = 8, height = 6)


# Separate 'covid' data from other words and prepare combined data
log_message("Separating 'covid' data from other words and preparing combined data")
covid_data <- word_trends_top %>% filter(word == "covid")
other_words_data <- word_trends_top %>% filter(word != "covid")

# Label groups
covid_data <- covid_data %>% mutate(group = "COVID Only")
other_words_data <- other_words_data %>% mutate(group = "Other Words")

# Combine data
combined_data <- bind_rows(covid_data, other_words_data)

# Plotting the faceted line chart for 'COVID' and other words
gg <- ggplot(combined_data, aes(x = year, y = frequency, color = word, group = word)) +
  geom_line(linewidth = 1.2, alpha = 0.8) +  # Adjust line thickness and transparency
  scale_color_viridis_d(option = "plasma", begin = 0, end = 0.9) +  # Optimize color
  scale_x_continuous(
    breaks = seq(2019, 2026, by = 1),  # X-axis from 2019 to 2026
    limits = c(2019, 2026)
  ) +
  labs(
    title = "Thematic Word Frequency Trends (2019-2026)",
    x = "Year",
    y = "Frequency",
    color = "Words"
  ) +
  theme_minimal() +
  theme(
    legend.position = "right",
    legend.title = element_text(size = 12),
    legend.text = element_text(size = 10),
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(hjust = 0.5, size = 16)
  ) +
  facet_wrap(~group, scales = "free_y") +
  guides(color = guide_legend(reverse = FALSE))

ggsave("plots/Thematic_Word_Frequency_Trends_2019-2026.png", width = 8, height = 6)
log_message("Word frequency trend plots saved and analysis is concluding")

  # End logging
  log_message("---- Word frequency analysis ended ----")
  close(log_connection)