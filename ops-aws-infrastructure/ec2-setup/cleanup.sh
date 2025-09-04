#!/bin/bash

# Clean up old files (logs and jar backups) older than 30 days
LOG_DIR="/opt/bright-valley/logs"
LIB_DIR="/opt/bright-valley/lib"

echo "=== Cleaning up old files ==="

# Clean up log files older than 30 days
echo "Cleaning log files older than 30 days..."
DELETED_LOGS=$(find "$LOG_DIR" -name "bright-valley-*.log" -mtime +30 -type f -print -delete 2>/dev/null | wc -l)
echo "Deleted $DELETED_LOGS old log files"

# Clean up jar backup files older than 30 days
echo "Cleaning JAR backup files older than 30 days..."
DELETED_JARS=$(find "$LIB_DIR" -name "*.jar.backup.*" -mtime +30 -type f -print -delete 2>/dev/null | wc -l)
echo "Deleted $DELETED_JARS old JAR backup files"

# Show current disk usage
echo "Current disk usage for /opt/bright-valley:"
du -sh /opt/bright-valley/* 2>/dev/null || echo "Could not calculate disk usage"

echo "Cleanup completed"