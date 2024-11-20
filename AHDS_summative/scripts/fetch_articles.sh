#!/bin/bash
# Arguments
PMID=$1
OUTPUT_FILE=$2

# Create directories if not exists
mkdir -p $(dirname "$OUTPUT_FILE")

# Fetch article metadata
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=$PMID" > "$OUTPUT_FILE"

if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch metadata for PMID $PMID."
    exit 1
fi
echo "Metadata for PMID $PMID saved to $OUTPUT_FILE."

# Pause to avoid overwhelming PubMed servers
sleep 1  # Pauses for 1 second before the next request