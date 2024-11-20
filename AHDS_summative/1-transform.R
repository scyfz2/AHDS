library("tidyverse")

# The input file path needs to be the same with
# what is declared in the snakefile
df = read_csv("data/WHO-COVID-19-global-data.csv")

# The countries of interest
COUNTRY_CODES = c("GB", "US", "FR", "DE")

# Processing steps:
# - subset to a few countries
# - rename to simpler column names
# - bind this processed frame to a variable clean_df
df %>%
  filter(Country_code %in% COUNTRY_CODES) %>%
  select(date=Date_reported,
         country=Country,
         cases=New_cases, deaths=New_deaths) ->
  clean_df

# Check the structure of the dataframe
clean_df %>% glimpse()

# The output file path needs to be the same with
# what is declared in the snakefile
clean_df %>% write_csv("intermediates/plot_df.csv")
