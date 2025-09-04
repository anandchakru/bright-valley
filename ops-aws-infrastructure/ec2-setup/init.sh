#!/bin/bash

# S3-Based Initialization and Deployment
# Exit on any error
set -e

JAR_NAME=$1
SPRING_PROFILE=$2

if [ -z "$JAR_NAME" ]; then
    echo "Usage: $0 <jar-name>"
    echo "Example: $0 bright-valley-api-1.0.123.1-SNAPSHOT.jar"
    exit 1
fi

echo "=== Starting S3-Based Initialization and Deployment ==="
echo "=== JAR: $JAR_NAME ==="

# Configure AWS CLI region for this script
export AWS_DEFAULT_REGION=""
echo "=== AWS Region: $AWS_DEFAULT_REGION ==="

# 1. Set timezone
echo "=== Setting timezone ==="
sudo timedatectl set-timezone US/Central

# 2. Create directories if not exists
echo "=== Creating directory structure ==="
sudo mkdir -p /opt/bright-valley/ec2-setup
sudo mkdir -p /opt/bright-valley/lib
sudo mkdir -p /opt/bright-valley/env
sudo mkdir -p /opt/bright-valley/logs
sudo mkdir -p /opt/bright-valley/backups

# 3. Install system dependencies
echo "=== Installing system dependencies ==="
sudo yum update -y

# Install Java 21 (Amazon Corretto)
echo "Installing Java 21 (Amazon Corretto)..."
if command -v java &> /dev/null; then
    echo "✅ Java is already installed:"
    java -version
else
    echo "Installing Amazon Corretto 21..."
    # Check OS version and install accordingly
    if grep -q "Amazon Linux 2" /etc/os-release; then
        echo "Detected Amazon Linux 2, installing Corretto 21..."
        # Import Amazon Corretto public key and repository
        sudo rpm --import https://yum.corretto.aws/corretto.key
        sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
        sudo yum install -y java-21-amazon-corretto-devel
    elif grep -q "Amazon Linux" /etc/os-release; then
        echo "Detected Amazon Linux 2023+, installing Corretto 21..."
        sudo yum install -y java-21-amazon-corretto-devel
    else
        echo "Unknown Linux distribution, trying default Java installation..."
        sudo yum install -y java-21-amazon-corretto-devel || sudo yum install -y java-21-openjdk-devel || sudo yum install -y java-17-openjdk-devel
    fi
    
    # Verify installation
    if command -v java &> /dev/null; then
        echo "✅ Java installed successfully:"
        java -version
    else
        echo "❌ Java installation failed!"
        exit 1
    fi
fi

# Install PostgreSQL client (try multiple package names for compatibility)
echo "Installing PostgreSQL client..."
sudo yum install -y postgresql postgresql-client || sudo yum install -y postgresql15 || echo "PostgreSQL client installation skipped"

# Install Redis (optional, disable by default)
echo "Installing Redis (disabled by default)..."
sudo amazon-linux-extras install redis6 -y || sudo yum install -y redis || echo "Redis installation skipped"
sudo systemctl disable redis || sudo systemctl disable redis6 || echo "Redis service disable skipped"

# Install other dependencies
sudo yum install -y awscli jq wget curl unzip

echo "=== Verifying installed packages ==="
java -version
aws --version
jq --version
psql --version || echo "PostgreSQL verification failed"
redis-server --version || echo "Redis verification failed"

# 4. Create bright-valley user if not exists
echo "=== Creating bright-valley user ==="
if ! id "bright-valley" &>/dev/null; then
    sudo useradd -r -s /bin/bash -d /opt/bright-valley -c "bright-valley API Service" bright-valley
    echo "User 'bright-valley' created successfully"
else
    echo "✅ User 'bright-valley' already exists"
fi



# 5. Sync all EC2 setup files from S3
echo "=== Syncing all EC2 setup scripts from S3 ==="

# Determine environment for S3 bucket (fallback to spring profile or prod)
if [ -n "$SPRING_PROFILE" ]; then
    ENV_FOR_S3="$SPRING_PROFILE"
else
    ENV_FOR_S3="prod"
fi

echo "Source: s3://bright-valley-${ENV_FOR_S3}-ops/ec2-setup/"
echo "Target: /opt/bright-valley/ec2-setup/"

# Create target directory if it doesn't exist
sudo mkdir -p /opt/bright-valley/ec2-setup

# Sync all files from S3 ec2-setup directory
if sudo aws s3 sync s3://bright-valley-${ENV_FOR_S3}-ops/ec2-setup/ /opt/bright-valley/ec2-setup/; then
    echo "✅ Successfully synced EC2 setup scripts from S3"
    
    # Make all shell scripts executable
    sudo chmod +x /opt/bright-valley/ec2-setup/*.sh
    
    # Set ownership for all files
    sudo chown -R bright-valley:bright-valley /opt/bright-valley/ec2-setup/
    
    echo "📋 Downloaded EC2 setup files:"
    ls -la /opt/bright-valley/ec2-setup/
else
    echo "❌ Failed to sync EC2 setup scripts from S3"
    echo "⚠️ Continuing with manual setup..."
fi

# 6. Setup systemd service
echo "=== Setting up systemd service ==="
if [ -f "/opt/bright-valley/ec2-setup/bright-valley-api.service" ]; then
    sudo cp /opt/bright-valley/ec2-setup/bright-valley-api.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable bright-valley-api.service
    echo "✅ Systemd service configured successfully"
else
    echo "❌ Service file not found: /opt/bright-valley/ec2-setup/bright-valley-api.service"
    echo "⚠️ Manual service setup may be required"
fi

# 7. Set ownership
echo "=== Setting ownership ==="
sudo chown -R bright-valley:bright-valley /opt/bright-valley



# 8. Configure Spring profile and secrets
echo "=== Configuring Spring profile and secrets ==="

# Determine environment for secret name (fallback to spring profile or prod)
if [ -n "$SPRING_PROFILE" ]; then
    ENV_FOR_SECRET="$SPRING_PROFILE"
    echo "Using Spring profile for environment: $SPRING_PROFILE"
else
    ENV_FOR_SECRET="prod"
    echo "No Spring profile specified, defaulting to prod"
fi

# Single secret name for all application and database secrets
APP_SECRET_NAME="bright-valley-${ENV_FOR_SECRET}-app-secrets"
echo "Looking for application secrets: $APP_SECRET_NAME"

# Start building the spring.env file
echo "Creating Spring environment configuration..."
TEMP_SPRING_ENV="/tmp/spring.env.$$"

# Add Spring profile
if [ -n "$SPRING_PROFILE" ]; then
    echo "SPRING_PROFILES_ACTIVE=$SPRING_PROFILE" > "$TEMP_SPRING_ENV"
else
    echo "SPRING_PROFILES_ACTIVE=prod" > "$TEMP_SPRING_ENV"
fi

# Fetch secrets from AWS Secrets Manager
echo "=== Fetching secrets from AWS Secrets Manager ==="
echo "Looking for secrets: $APP_SECRET_NAME"

if aws secretsmanager get-secret-value --secret-id "$APP_SECRET_NAME" --query 'SecretString' --output text >/dev/null 2>&1; then
    echo "✅ Found secrets: $APP_SECRET_NAME"
    
    # Get the secret value and parse JSON
    SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$APP_SECRET_NAME" --query 'SecretString' --output text)
    
    if [ $? -eq 0 ] && [ -n "$SECRET_JSON" ]; then
        echo "✅ Successfully retrieved secrets JSON"
        
        # Dump all key-value pairs with SPRING_ENV_ prefix
        echo "📋 Adding secrets to Spring environment:"
        echo "$SECRET_JSON" | jq -r 'to_entries[] | "SPRING_ENV_\(.key)=\(.value)"' >> "$TEMP_SPRING_ENV"
        
        if [ $? -eq 0 ]; then
            echo "✅ Successfully parsed and added secrets to environment"
            # Show what we added (mask sensitive values)
            echo "📋 Environment variables added:"
            echo "$SECRET_JSON" | jq -r 'to_entries[] | "SPRING_ENV_\(.key)=***MASKED***"'
        else
            echo "❌ Failed to parse secret JSON"
            echo "⚠️ Secret JSON format may be invalid"
        fi
    else
        echo "❌ Failed to retrieve secret value"
    fi
else
    echo "⚠️ Secret not found: $APP_SECRET_NAME"
    echo "ℹ️ Continuing without secrets"
fi

# Check if we have the minimum required configuration
if ! grep -q "SPRING_DATASOURCE_URL" "$TEMP_SPRING_ENV"; then
    echo "⚠️ Warning: No database configuration found in secrets"
    echo "⚠️ Application may fail to start without database connection"
fi

# Final summary
echo "📋 Secrets configuration completed"

# Move temp file to final location
sudo mv "$TEMP_SPRING_ENV" /opt/bright-valley/env/spring.env
sudo chown bright-valley:bright-valley /opt/bright-valley/env/spring.env
sudo chmod 644 /opt/bright-valley/env/spring.env

echo "📋 Final Spring environment configuration:"
echo "SPRING_PROFILES_ACTIVE=$(grep SPRING_PROFILES_ACTIVE /opt/bright-valley/env/spring.env | cut -d'=' -f2)"
echo "Additional environment variables: $(grep -v SPRING_PROFILES_ACTIVE /opt/bright-valley/env/spring.env | wc -l)"

# 9. Backup existing jar file
echo "=== Backing up existing JAR file ==="
if [ -f "/opt/bright-valley/lib/app.jar" ]; then
    BACKUP_NAME="app.jar.backup.$(date +%Y%m%d_%H%M%S)"
    sudo cp /opt/bright-valley/lib/app.jar /opt/bright-valley/lib/$BACKUP_NAME
    echo "Existing JAR backed up as: $BACKUP_NAME"
else
    echo "No existing JAR found, skipping backup"
fi

# 10. Download new JAR from S3
echo "=== Downloading new JAR file ==="
if sudo aws s3 cp "s3://bright-valley-${ENV_FOR_S3}-ops/jars/$JAR_NAME" /opt/bright-valley/lib/app.jar; then
    echo "✅ Successfully downloaded $JAR_NAME from S3"
    sudo chown bright-valley:bright-valley /opt/bright-valley/lib/app.jar
    sudo chmod 644 /opt/bright-valley/lib/app.jar
else
    echo "❌ Failed to download $JAR_NAME from S3"
    exit 1
fi

# 11. Restart service
echo "=== Restarting bright-valley-api service with profile: $SPRING_PROFILE ==="
sudo systemctl restart bright-valley-api.service

# Verify service is running
echo "=== Verifying service startup ==="
sleep 5

RETRY_COUNT=0
MAX_RETRIES=12
SLEEP_TIME=5

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if systemctl is-active --quiet bright-valley-api.service; then
        echo "✅ Service is running successfully!"
        echo
        echo "=== Service Status ==="
        sudo systemctl status bright-valley-api.service --no-pager -l
        echo
        echo "=== Recent Logs ==="
        sudo journalctl -u bright-valley-api.service -n 10 --no-pager
        echo
        echo "=== Current JAR ==="
        ls -la /opt/bright-valley/lib/app.jar
        echo
        echo "=== Initialization and Deployment completed successfully ==="
        exit 0
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Service not ready yet, waiting... (attempt $RETRY_COUNT/$MAX_RETRIES)"
    sleep $SLEEP_TIME
done

# If we get here, the service failed to start
echo "❌ Service failed to start after $((MAX_RETRIES * SLEEP_TIME)) seconds."
echo
echo "=== Service Status ==="
sudo systemctl status bright-valley-api.service --no-pager -l
echo
echo "=== Recent Error Logs ==="
sudo journalctl -u bright-valley-api.service -n 20 --no-pager
exit 1