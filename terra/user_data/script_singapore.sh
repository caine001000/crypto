#!/bin/bash
# Log everything
exec > /var/log/user-data.log 2>&1
set -x

echo "=========================================="
echo "Singapore User Data Started: $(date)"
echo "=========================================="

FARGATE_PROXY_IP="${fargate_proxy_ip}"
PROXY_PORT="8888"

echo "Fargate Proxy IP: $FARGATE_PROXY_IP"
echo "Proxy Port: $PROXY_PORT"

# Wait for system to be ready
sleep 10

# NOW configure proxy after packages are installed
echo "Configuring system-wide proxy..."

# Set proxy in /etc/environment (system-wide)
cat >> /etc/environment <<EOF
http_proxy=http://$FARGATE_PROXY_IP:$PROXY_PORT
https_proxy=http://$FARGATE_PROXY_IP:$PROXY_PORT
HTTP_PROXY=http://$FARGATE_PROXY_IP:$PROXY_PORT
HTTPS_PROXY=http://$FARGATE_PROXY_IP:$PROXY_PORT
no_proxy=localhost,127.0.0.1,169.254.169.254,10.1.0.0/16
NO_PROXY=localhost,127.0.0.1,169.254.169.254,10.1.0.0/16
EOF

# Create profile script for all users
cat > /etc/profile.d/proxy.sh <<EOF
export http_proxy=http://$FARGATE_PROXY_IP:$PROXY_PORT
export https_proxy=http://$FARGATE_PROXY_IP:$PROXY_PORT
export HTTP_PROXY=http://$FARGATE_PROXY_IP:$PROXY_PORT
export HTTPS_PROXY=http://$FARGATE_PROXY_IP:$PROXY_PORT
export no_proxy=localhost,127.0.0.1,169.254.169.254,10.1.0.0/16
export NO_PROXY=localhost,127.0.0.1,169.254.169.254,10.1.0.0/16
EOF
chmod +x /etc/profile.d/proxy.sh

# Add to ec2-user's .bashrc
cat >> /home/ec2-user/.bashrc <<EOF

# Proxy configuration for Tokyo egress via Fargate
export http_proxy=http://$FARGATE_PROXY_IP:$PROXY_PORT
export https_proxy=http://$FARGATE_PROXY_IP:$PROXY_PORT
export HTTP_PROXY=http://$FARGATE_PROXY_IP:$PROXY_PORT
export HTTPS_PROXY=http://$FARGATE_PROXY_IP:$PROXY_PORT
export no_proxy=localhost,127.0.0.1,169.254.169.254,10.1.0.0/16
export NO_PROXY=localhost,127.0.0.1,169.254.169.254,10.1.0.0/16
EOF
chown ec2-user:ec2-user /home/ec2-user/.bashrc

# Configure curl to use proxy by default
cat > /home/ec2-user/.curlrc <<EOF
proxy = http://$FARGATE_PROXY_IP:$PROXY_PORT
noproxy = localhost,127.0.0.1,169.254.169.254,10.1.0.0/16
EOF
chown ec2-user:ec2-user /home/ec2-user/.curlrc

echo "Proxy configured successfully"
echo "Testing proxy connection..."
export http_proxy=http://$FARGATE_PROXY_IP:$PROXY_PORT
export https_proxy=http://$FARGATE_PROXY_IP:$PROXY_PORT
curl -s --max-time 10 https://ipinfo.io/ip && echo "Proxy test successful!" || echo "Proxy test failed"

echo "=========================================="
echo "Singapore User Data Completed: $(date)"
echo "=========================================="
echo "SUCCESS" > /tmp/user-data-complete