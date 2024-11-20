library(topicmodels)
library(tidytext)
library(tidyverse)

# Load cleaned article data
cleaned_data <- read_tsv("data/processed/cleaned_articles.tsv", col_types = cols(PMID = col_character()))  # Ensure PMID is character

# Prepare data for LDA
lda_data <- cleaned_data %>%
  unnest_tokens(word, Cleaned_Title) %>%
  count(PMID, word) %>%
  cast_dtm(document = PMID, term = word, value = n)  # Create Document-Term Matrix (DTM)

# Fit an LDA model
lda_model <- LDA(lda_data, k = 5, control = list(seed = 123))  # 5 topics

# Extract topic probabilities
topic_terms <- tidy(lda_model, matrix = "beta")  # Term-topic probabilities
article_topics <- tidy(lda_model, matrix = "gamma")  # Document-topic probabilities

# Join article metadata with topics
topic_trends <- article_topics %>%
  mutate(document = as.character(document)) %>%  # Ensure document is character
  left_join(cleaned_data %>% mutate(PMID = as.character(PMID)), by = c("document" = "PMID")) %>%  # Match types
  group_by(Year, topic) %>%
  summarize(mean_gamma = mean(gamma), .groups = "drop")  # Average topic relevance per year

# Plot topic trends over time
ggplot(topic_trends, aes(x = Year, y = mean_gamma, color = as.factor(topic), group = topic)) +
  geom_line() +
  labs(
    title = "Topic Trends Over Time",
    x = "Year",
    y = "Average Topic Relevance",
    color = "Topic"
  ) +
  theme_minimal()
