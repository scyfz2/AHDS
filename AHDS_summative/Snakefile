import os
from glob import glob
# Load configuration file
configfile: "config/config.yaml"

# Directories
RAW_DIR = config["raw_dir"]
ARTICLES_DIR = config["articles_dir"]
PROCESSED_DIR = config["processed_dir"]
CLEAN_DIR = config["clean_dir"]

# Keywords and parameters
KEYWORD = config["keyword"].replace(" ", "%20")  # Replace spaces with URL encoding
RETMAX = config["retmax"]


# Rule: All
rule all:
    input:
        os.path.join(RAW_DIR, "pmids.xml"),
        os.path.join(PROCESSED_DIR, "articles.tsv"),
        os.path.join(CLEAN_DIR, "cleaned_articles.tsv"),
        "plots/Top_Terms_Excluding_COVID.png",
        "plots/Top_Terms_with_COVID.png",
        "plots/Word_Frequency_Trends_2019-2026.png",
        "plots/Thematic_Word_Frequency_Trends_2019-2026.png"




# Rule: fetch data
rule fetch_data:
    output:
        os.path.join(RAW_DIR, "pmids.xml"),
        "logs/fetch_data.log"
    shell:
        """
        bash scripts/fetch_data.sh '{KEYWORD}' {RETMAX} {RAW_DIR} {ARTICLES_DIR}
        """

# Helper function: Extract PMIDs from XML
def get_pmids(pmids_file):
    import xml.etree.ElementTree as ET
    try:
        tree = ET.parse(pmids_file)
        root = tree.getroot()
        pmid_list = [id_elem.text for id_elem in root.findall(".//Id")]
        if not pmid_list:
            raise ValueError("No PMIDs found in pmids.xml")
        return pmid_list
    except Exception as e:
        print(f"Error parsing PMIDs from {pmids_file}: {e}")
        return []


# Rule: Process XML files into TSV
rule process_articles:
    input:
        f"logs/fetch_data.log",
        pmids_xml = os.path.join(RAW_DIR, "pmids.xml")  # Ensure pmids.xml is ready
    output:
        os.path.join(PROCESSED_DIR, "articles.tsv"),
        "logs/process_articles.log"
    run:
        pmid_list = get_pmids(input.pmids_xml)  # Call get_pmids here
        shell("""
            Rscript scripts/process_articles.R {ARTICLES_DIR} {output[0]}
        """)


# Rule: Clean Titles using tidytext
rule clean_titles:
    input:
        f"logs/process_articles.log",
        os.path.join(PROCESSED_DIR, "articles.tsv")
    output:
        os.path.join(CLEAN_DIR, "cleaned_articles.tsv"),
        "logs/clean_titles.log"
    script:
        "scripts/clean_titles.R" 


# Rule: Word Frequency Analysis
rule word_frequency:
    input:
        os.path.join(CLEAN_DIR, "cleaned_articles.tsv")
    output:
        "plots/Word_Frequency_Trends_2019-2026.png",
        "plots/Thematic_Word_Frequency_Trends_2019-2026.png"
    script:
        "scripts/word_frequency.R"

# Rule: LDA Topic Modeling
rule LDA:
    input:
        os.path.join(CLEAN_DIR, "cleaned_articles.tsv")
    output:
        "plots/Top_Terms_Excluding_COVID.png",
        "plots/Top_Terms_with_COVID.png"
    script:
        "scripts/LDA.R"


# Rule: remove data and logs directory
rule clean:
    "Clean up"
    shell: """
    if [ -d data ]; then
      rm -r data
    else
      echo directory data does not exist
    fi
    if [ -d logs ]; then
      rm -r logs
    else
      echo directory logs does not exist
    fi
    if [ -d plots ]; then
      rm -r plots
    else
      echo directory plots does not exist
    fi
    """

# Rule: remove plots directory
rule cleanplot:
    "Clean plot"
    shell: """
    if [ -d plots ]; then
      rm -r plots
    else
      echo directory plots does not exist
    fi
    """
