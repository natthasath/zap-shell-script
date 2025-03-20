#!/bin/bash

# Set the timezone
timezone="Asia/Bangkok"

# Check if list.txt exists
if [[ ! -f list.txt ]]; then
  echo "Error: list.txt not found!"
  exit 1
fi

# Create a results directory if it doesn't exist
mkdir -p results

# Read URLs from list.txt and run ZAP scan via Docker
while IFS= read -r url; do
  # Ensure the URL is not empty
  if [[ -n "$url" ]]; then
    # Extract domain name for report filename
    domain=$(echo "$url" | awk -F[/:] '{print $4}')
    report_file="results/${domain}.html"
    
    echo "Scanning: $url"
    # Execute the Docker command with the specified timezone and mount the current directory
    docker run -e TZ=$timezone --rm -u root -v "$(pwd):/zap/wrk" -t zaproxy/zap-stable zap-baseline.py -t "$url" -r "$report_file"
    echo "Report saved: $report_file"
  fi
done < list.txt