# NOTE: this script is intended to be used interactively

library("tidyverse")

# Initialization ========

INPUT_FILE = "data/WHO-COVID-19-global-data.csv"

# check input file structure
data_dir_exists = fs::dir_exists("data")
data_file_exists = fs::file_exists(INPUT_FILE)
print(glue::glue("Current working directory: {getwd()}"))
print(glue::glue("{INPUT_FILE} exsits: {data_file_exists}"))

# load dataset

df = read_csv(INPUT_FILE)
glimpse(df)

# Basic exploration ========

# Examine countries
df %>% select(Country) %>% distinct()

# Examine regions
df %>% select(WHO_region) %>% distinct()

# Examine data
df %>% select(Date_reported) %>% distinct() %>% arrange() -> uniq_dates
uniq_dates %>% head()
uniq_dates %>% tail()

# Sanity check ========

COUNTRY_CODE = "GB"
df %>%
  filter(Country_code == COUNTRY_CODE) %>%
  select(date=Date_reported, cases=New_cases, deaths=New_deaths) %>%
  pivot_longer(cols=c("cases", "deaths"), names_to="category", values_to="value") ->
  plot_df
plot_df %>% glimpse()
# basic plots
plot_df %>%
  ggplot(aes(x=date, y=value)) + geom_line(aes(colour=category))
# facet plot
plot_df %>%
  ggplot(aes(x=date, y=value)) +
  geom_line(aes(colour=category)) +
  facet_wrap(vars(category), ncol=1, scales="free")
