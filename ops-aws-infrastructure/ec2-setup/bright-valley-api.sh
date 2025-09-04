#!/bin/bash

# bright-valley API Service Startup Script

# Set up logging
LOG_DIR="/opt/bright-valley/logs"
LOG_FILE="$LOG_DIR/bright-valley-$(date +%Y%m%d).log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Function to log with timestamp
log_with_timestamp() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_with_timestamp "Starting bright-valley API Service"

# Change to service directory
cd /opt/bright-valley

# Add gcloud to PATH
#if [ -f '/opt/google-cloud-sdk/path.bash.inc' ]; then
#    . '/opt/google-cloud-sdk/path.bash.inc'
#fi
#export PATH="/opt/google-cloud-sdk/bin:$PATH"

# Check if JAR file exists
if [ ! -f "/opt/bright-valley/lib/app.jar" ]; then
    log_with_timestamp "ERROR: JAR file not found at /opt/bright-valley/lib/app.jar"
    exit 1
fi

# Log Java version and environment
log_with_timestamp "Java version: $(java -version 2>&1 | head -n 1)"
log_with_timestamp "Working directory: $(pwd)"
log_with_timestamp "JAR file: $(ls -la /opt/bright-valley/lib/app.jar)"

# Determine Spring profile arguments
SPRING_ARGS=""
if [ -n "$SPRING_PROFILES_ACTIVE" ]; then
    SPRING_ARGS="--spring.profiles.active=$SPRING_PROFILES_ACTIVE"
    log_with_timestamp "Using Spring profile: $SPRING_PROFILES_ACTIVE"
else
    log_with_timestamp "No Spring profile specified, using prod (default)"
fi

# Start the application with logging
log_with_timestamp "Starting Java application: /opt/bright-valley/lib/app.jar $SPRING_ARGS"

# Run the application and pipe all output to our logging function
java -jar /opt/bright-valley/lib/app.jar $SPRING_ARGS 2>&1 | while IFS= read -r line; do
    log_with_timestamp "$line"
done

# If we reach here, the application has stopped
EXIT_CODE=${PIPESTATUS[0]}
log_with_timestamp "Application stopped with exit code: $EXIT_CODE"
exit $EXIT_CODE