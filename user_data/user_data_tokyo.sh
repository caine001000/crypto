#!/bin/bash

# Log everything to file
exec > /var/log/user-data.log 2>&1

echo "=========================================="
echo "User Data Script Started: $(date)"
echo "=========================================="

# Enable debug mode
set -x

# Wait for system to be ready
echo "Waiting for system to be ready..."
sleep 30

# Update package lists
echo "Updating package lists..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y

# Install Squid
echo "Installing Squid proxy..."
apt-get install -y squid

# Backup original config
cp /etc/squid/squid.conf /etc/squid/squid.conf.original

# Create new Squid configuration
echo "Configuring Squid..."
cat > /etc/squid/squid.conf <<'SQUIDCONFIG'
# Allow traffic from Singapore VPC
acl singapore_vpc src 10.1.0.0/16
http_access allow singapore_vpc

# Deny all other traffic
http_access deny all

# Listen on port 3128
http_port 3128

# Don't cache anything
cache deny all

# Don't forward client info
forwarded_for delete
via off

# Logging
access_log /var/log/squid/access.log squid
cache_log /var/log/squid/cache.log
SQUIDCONFIG

# Enable and start Squid
echo "Starting Squid service..."
systemctl enable squid
systemctl restart squid

# Wait for service to start
sleep 5

# Check status
echo "Checking Squid status..."
systemctl status squid --no-pager

# Check if listening on port 3128
echo "Checking if Squid is listening on port 3128..."
ss -tlnp | grep 3128

# Verify Squid is actually working
echo "Testing Squid locally..."
curl -x http://localhost:3128 http://www.google.com -I || echo "Local test failed"

echo "=========================================="
echo "User Data Script Completed: $(date)"
echo "=========================================="

# Mark as complete
echo "SUCCESS" > /tmp/user-data-complete