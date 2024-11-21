#!/bin/bash
# Arguments
PMID=$1
OUTPUT_FILE=$2

# Create directories if not exists
mkdir -p $(dirname "$OUTPUT_FILE")

# Retry logic configuration
RETRY_LIMIT=5         # Maximum number of retry attempts
RETRY_INTERVAL=5      # Wait time (in seconds) between retries

# Function to fetch article metadata
fetch_article() {
    local pmid=$1
    local output_file=$2
    local retry_count=0

    while [ $retry_count -lt $RETRY_LIMIT ]; do
        # Fetch data from PubMed API
        curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=$pmid" > "$output_file"

        # Check if response indicates a rate limit error
        if ! grep -q '"error":"API rate limit exceeded"' "$output_file"; then
            # Successful fetch
            echo "Metadata for PMID $pmid saved to $output_file."
            return 0
        fi

        # If rate limit error, retry after interval
        echo "API rate limit exceeded for PMID $pmid. Retrying in $RETRY_INTERVAL seconds..."
        sleep $RETRY_INTERVAL
        retry_count=$((retry_count + 1))
    done

    # If retries exhausted, log an error and return failure
    echo "Error: Failed to fetch metadata for PMID $pmid after $RETRY_LIMIT attempts."
    return 1
}

# Fetch the article metadata with retries
fetch_article $PMID $OUTPUT_FILE

# Pause to avoid overwhelming PubMed servers
sleep 3  # Adjust sleep time as per your API rate limits
