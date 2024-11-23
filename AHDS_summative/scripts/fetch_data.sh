#!/bin/bash

# Variables from arguments
KEYWORD=$1
RETMAX=$2
RAW_DIR=$3
ARTICLES_DIR=$4

# Log file path
LOG_FILE="logs/fetch_data.log"
mkdir -p "$(dirname "$LOG_FILE")"  # Ensure the logs directory exists

# Start logging
exec > >(tee -a "$LOG_FILE") 2>&1

echo "----- Starting Data Fetch: $(date) -----"
echo "Keyword: $KEYWORD"
echo "Max Results: $RETMAX"
echo "Raw Directory: $RAW_DIR"
echo "Articles Directory: $ARTICLES_DIR"

# Create directories for storing data
mkdir -p "$RAW_DIR"
mkdir -p "$ARTICLES_DIR"

# URL to retrieve PMIDs
echo "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=\"${KEYWORD}\"&retmax=${RETMAX}"
PMID_URL="https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=\"${KEYWORD}\"&retmax=${RETMAX}"


# Output file for PMIDs
PMID_FILE="${RAW_DIR}/pmids.xml"

# Download PMIDs
echo "Downloading PMIDs..."
if curl -s "$PMID_URL" -o "$PMID_FILE"; then
    echo "PMIDs downloaded successfully: $PMID_FILE"
else
    echo "Error downloading PMIDs!" >&2
    exit 1
fi

# Extract PMIDs from the XML file
echo "Extracting PMIDs..."
PMID_LIST=$(grep -oP '(?<=<Id>)[^<]+' "$PMID_FILE")
if [[ -z "$PMID_LIST" ]]; then
    echo "No PMIDs found!" >&2
    exit 1
fi

# Download metadata for each PMID
echo "Downloading metadata for articles..."
total_pmids=$(echo "$PMID_LIST" | wc -w) 
current_count=0 

for PMID in $PMID_LIST; do
    METADATA_FILE="${ARTICLES_DIR}/article-data-${PMID}.xml"
    current_count=$((current_count + 1))
    
    # Calculate and display progress
    progress=$((current_count * 100 / total_pmids))
    echo -ne "Progress: $progress% ($current_count/$total_pmids)\r"

    # Download file
    if curl -s --progress-bar "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=$PMID" -o "$METADATA_FILE"; then
        echo "Metadata saved: $METADATA_FILE"
    else
        echo "Error fetching metadata for PMID $PMID!" >&2
    fi
    
    sleep 0.4 # Pause to avoid overwhelming the server
done

echo "Download complete. Metadata saved in $ARTICLES_DIR."
echo "----- Data Fetch Completed: $(date) -----"
