library("tidyverse")

# The input file path needs to be the same with
# what is declared in the snakefile
df = read_csv("intermediates/plot_df.csv")

# Transform data into a long format, which
# uses a column value to record values of both cases and deaths
# and a column value_category to record keys (category)
plot_df = df %>%
  pivot_longer(cols=c("cases", "deaths"), names_to="value_category", values_to="value")


# Create a ggplot object, where
# date is the variable for horizontal axis
# value is the variable for vertical axis
# value_category is the variable for line colour
# and facet by both value_category and country
fig = plot_df %>%
  ggplot(aes(x=date, y=value)) +
  geom_line(aes(colour=value_category)) +
  facet_wrap(value_category ~ country, scales="free")

# The output file path needs to be the same with
# what is declared in the snakefile
fig %>% ggsave(filename="results/fig-simple.png", plot=.)
