#!/bin/bash
# Arguments
KEYWORD=$1
RETMAX=$2
OUTPUT_FILE=$3

# Create directories if not exists
mkdir -p $(dirname "$OUTPUT_FILE")

# Fetch PubMed IDs
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=%22$KEYWORD%22&retmax=$RETMAX" > "$OUTPUT_FILE"

if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch PubMed IDs."
    exit 1
fi
echo "PubMed IDs saved to $OUTPUT_FILE."
