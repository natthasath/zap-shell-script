#!/bin/bash

# Improved ZAP Scan Script
# This script runs ZAP scans for URLs listed in a file
# using best practices from the DNS checker pattern

# Set the timezone
TIMEZONE="Asia/Bangkok"

# Define input and output files/directories
INPUT_FILE="list.txt"
RESULTS_DIR="results"
LOG_FILE="zap-scan-log.txt"

# Clear or create log file
> "$LOG_FILE"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    exit 1
fi

# Check if Docker is installed and ZAP image is available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH."
    exit 1
fi

# Create results directory if it doesn't exist
mkdir -p "$RESULTS_DIR"

# Display start message
echo "Starting ZAP scan for URLs in $INPUT_FILE..."
echo "Results will be saved in $RESULTS_DIR directory."
echo "Start time: $(date)" | tee -a "$LOG_FILE"

# Counter for progress tracking
TOTAL_URLS=$(wc -l < "$INPUT_FILE")
CURRENT=0
SUCCESSFUL=0
FAILED=0

# Process each URL in the input file
while IFS= read -r url || [ -n "$url" ]; do
    # Skip empty lines
    if [ -z "$url" ]; then
        continue
    fi
    
    # Increment counter
    ((CURRENT++))
    
    # Remove any whitespace and ensure URL is in proper format
    url=$(echo "$url" | tr -d '[:space:]')
    
    # Extract domain name for report filename
    domain=$(echo "$url" | awk -F[/:] '{print $4}')
    report_file="${RESULTS_DIR}/${domain}.html"
    
    echo -e "\nProcessing URL $CURRENT of $TOTAL_URLS: $url"
    echo "$(date) - Starting scan of: $url" >> "$LOG_FILE"
    
    # Execute the Docker command with timeout for safety
    echo "Running ZAP scan (this may take several minutes)..."
    if timeout 1800 docker run -e TZ="$TIMEZONE" --rm -u root -v "$(pwd):/zap/wrk" -t zaproxy/zap-stable zap-baseline.py -t "$url" -r "$report_file" 2>&1 | tee -a "$LOG_FILE"; then
        echo "Scan completed successfully for: $url"
        echo "Report saved: $report_file"
        echo "$(date) - Scan completed successfully: $url" >> "$LOG_FILE"
        ((SUCCESSFUL++))
    else
        # Check if it was a timeout or other error
        if [ $? -eq 124 ]; then
            echo "Scan TIMED OUT after 30 minutes for: $url"
            echo "$(date) - Scan TIMED OUT: $url" >> "$LOG_FILE"
        else
            echo "Scan FAILED for: $url"
            echo "$(date) - Scan FAILED: $url" >> "$LOG_FILE"
        fi
        ((FAILED++))
    fi
    
    # Add a separator in the log
    echo "----------------------------------------" >> "$LOG_FILE"
    
done < "$INPUT_FILE"

# Display summary
echo -e "\n===== ZAP Scan Summary ====="
echo "Total URLs processed: $TOTAL_URLS"
echo "Successful scans: $SUCCESSFUL"
echo "Failed scans: $FAILED"
echo "Results saved in: $RESULTS_DIR"
echo "Log file: $LOG_FILE"
echo "End time: $(date)"

# Write summary to log
echo -e "\n===== ZAP Scan Summary =====" >> "$LOG_FILE"
echo "Total URLs processed: $TOTAL_URLS" >> "$LOG_FILE"
echo "Successful scans: $SUCCESSFUL" >> "$LOG_FILE"
echo "Failed scans: $FAILED" >> "$LOG_FILE"
echo "End time: $(date)" >> "$LOG_FILE"