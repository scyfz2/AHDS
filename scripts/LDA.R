library(tidyverse)
library(tidytext)
library(topicmodels)
library(reshape2)
library(ggplot2)

# Log file setup
log_file <- "logs/LDA_analysis.log"
dir.create(dirname(log_file), showWarnings = FALSE)  # Ensure the logs directory exists
log_connection <- file(log_file, open = "a")

# Helper function for logging
log_message <- function(message) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  writeLines(sprintf("[%s] %s", timestamp, message), log_connection)
}

# Start logging
log_message("---- LDA Analysis Started ----")

# Load data
log_message("Loading data from cleaned_articles.tsv")
data <- read_tsv("data/clean/cleaned_articles.tsv")

# Ensure directory for plots exists
dir.create("plots", showWarnings = FALSE)

# Data preprocessing
log_message("Starting data preprocessing")
data <- data %>%
  select(Year, Cleaned_Title) %>%
  drop_na() %>%
  rename(year = Year, title = Cleaned_Title)

# Creating Document-Word Matrix
log_message("Creating Document-Word Matrix")
dtm <- data %>%
  mutate(document = row_number()) %>%
  unnest_tokens(word, title) %>%
  filter(!word %in% stop_words) %>%
  count(document, word) %>%
  cast_dtm(document, word, n)

# Running LDA model
log_message("Running LDA model")
lda_model <- LDA(dtm, k = 4, control = list(seed = 18))
topics <- posterior(lda_model)$topics
data_with_topics <- data %>%
  mutate(topic = apply(topics, 1, which.max))  # Assigning dominant topic to each document

# Extracting keywords for each topic
log_message("Extracting keywords for each topic")
num_keywords <- 10
terms <- terms(lda_model, num_keywords)
topic_keywords <- apply(terms, 2, paste, collapse = ", ")

# Log and print top keywords in topics
log_message("Top Keywords in Topics:")
for (i in seq_along(topic_keywords)) {
  keyword_log <- sprintf("Topic %d: %s", i, topic_keywords[i])
  log_message(keyword_log)
  cat(keyword_log, "\n")
}

# Extracting topic-word weights and plotting
log_message("Extracting topic-word weights for plotting")
beta <- tidy(lda_model, matrix = "beta")
top_terms <- beta %>%
  group_by(topic) %>%
  top_n(num_keywords, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)

# Plotting Topic Trends from 2019 to 2026
log_message("Plotting Topic Trends from 2019 to 2026")
gg <- ggplot(top_terms, aes(x = reorder(term, beta), y = beta, fill = as.factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~topic, scales = "free") +
  coord_flip() +
  labs(
    title = "Top Terms in Each Topic",
    x = "Terms",
    y = "Beta (Importance)",
    fill = "Topic"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))

ggsave("plots/Top_Terms_in_Each_Topic.png", width = 8, height = 6)

# Topic Trends from 2019 to 2026
topic_distribution_by_year <- data_with_topics %>%
  group_by(year, topic) %>%
  summarise(count = n(), .groups = 'drop')

# Pivot data for easier plotting
annual_topic_distribution <- topic_distribution_by_year %>%
  pivot_wider(names_from = topic, values_from = count, values_fill = list(count = 0))

annual_topic_distribution <- na.omit(annual_topic_distribution)

annual_topic_distribution <- annual_topic_distribution %>%
  filter(year >= 2019 & year <= 2026)

# Plotting topic trends over time with updated y-axis for article counts
gg <- ggplot(annual_topic_distribution, aes(x = year)) +
  geom_line(aes(y = `1`, colour = "Topic 1"), linewidth = 1.2) +
  geom_line(aes(y = `2`, colour = "Topic 2"), linewidth = 1.2) +
  geom_line(aes(y = `3`, colour = "Topic 3"), linewidth = 1.2) +
  geom_line(aes(y = `4`, colour = "Topic 4"), linewidth = 1.2) +
  scale_y_continuous(limits = c(0, max(annual_topic_distribution[, -1], na.rm = TRUE) * 1.1)) +
  scale_x_continuous(breaks = 2019:2026, limits = c(2019, 2026)) +
  scale_color_manual(values = c("Topic 1" = "#f8766d", "Topic 2" = "#7cae00", "Topic 3" = "#03bfc4", "Topic 4" = "#c77cff")) +
  labs(title = "Topic Trends from 2019 to 2026",
       x = "Year",
       y = "Number of Articles",
       colour = "Topics") +
  theme_minimal() +
  theme(legend.position = "bottom", 
        legend.title = element_blank(),
        plot.title = element_text(hjust = 0.5))  # 设置标题居中

# Save the plot
ggsave("plots/Topic_Trends_2019_2026.png", width = 10, height = 6)

# End logging
log_message("---- LDA Analysis Completed ----")
close(log_connection)
