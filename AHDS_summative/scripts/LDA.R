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
lda_model <- LDA(dtm, k = 4, control = list(seed = 42))
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

# Plotting with 'COVID'
log_message("Plotting top terms with 'COVID'")
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

ggsave("plots/Top_Terms_with_COVID.png", width = 8, height = 6)

# Repeat analysis excluding 'COVID'
log_message("Repeating analysis excluding 'COVID'")
custom_stop_words <- stop_words %>%
  bind_rows(tibble(word = "covid", lexicon = "custom"))

data_filtered <- data %>%
  mutate(document = row_number()) %>%
  unnest_tokens(word, title) %>%
  filter(!word %in% custom_stop_words$word) %>%
  count(document, word) %>%
  filter(n > 0)  # Ensuring documents with words exist
dtm <- data_filtered %>%
  cast_dtm(document, word, n)

# Running LDA model
lda_model <- LDA(dtm, k = 4, control = list(seed = 42))

# Extracting keywords for each topic
log_message("Extracting keywords for each topic excluding 'COVID'")
topics <- posterior(lda_model)$topics
terms <- terms(lda_model, num_keywords)
topic_keywords <- apply(terms, 2, paste, collapse = ", ")

# Log and print top keywords in topics excluding 'COVID'
log_message("Top Keywords in Topics (Excluding 'COVID'):")
for (i in seq_along(topic_keywords)) {
  keyword_log <- sprintf("Topic %d: %s", i, topic_keywords[i])
  log_message(keyword_log)
  cat(keyword_log, "\n")
}

# Extracting topic-word weights and plotting
log_message("Extracting topic-word weights for plotting, excluding 'COVID'")
beta <- tidy(lda_model, matrix = "beta")
top_terms <- beta %>%
  group_by(topic) %>%
  top_n(num_keywords, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)

# Plotting excluding 'COVID'
log_message("Plotting top terms excluding 'COVID'")
gg <- ggplot(top_terms, aes(x = reorder(term, beta), y = beta, fill = as.factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~topic, scales = "free") +
  coord_flip() +
  labs(
    title = "Top Terms in Each Topic (Excluding 'COVID')",
    x = "Terms",
    y = "Beta (Importance)",
    fill = "Topic"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))

ggsave("plots/Top_Terms_Excluding_COVID.png", width = 8, height = 6)

# End logging
log_message("---- LDA Analysis Completed ----")
close(log_connection)
