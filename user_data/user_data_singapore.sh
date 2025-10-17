#!/bin/bash

# Log everything
exec > /var/log/user-data.log 2>&1
set -x

echo "=========================================="
echo "Singapore User Data Started: $(date)"
echo "=========================================="

TOKYO_PROXY_IP="${tokyo_proxy_ip}"

echo "Tokyo Proxy IP: $TOKYO_PROXY_IP"

# Wait for system to be ready
sleep 10

# Set proxy in /etc/environment
echo "Configuring /etc/environment..."
cat >> /etc/environment <<EOF
http_proxy=http://$TOKYO_PROXY_IP:3128
https_proxy=http://$TOKYO_PROXY_IP:3128
HTTP_PROXY=http://$TOKYO_PROXY_IP:3128
HTTPS_PROXY=http://$TOKYO_PROXY_IP:3128
EOF

# Set proxy for apt
echo "Configuring apt proxy..."
cat > /etc/apt/apt.conf.d/80proxy <<EOF
Acquire::http::Proxy "http://$TOKYO_PROXY_IP:3128";
Acquire::https::Proxy "http://$TOKYO_PROXY_IP:3128";
EOF

# Create profile script
echo "Creating /etc/profile.d/proxy.sh..."
cat > /etc/profile.d/proxy.sh <<EOF
export http_proxy=http://$TOKYO_PROXY_IP:3128
export https_proxy=http://$TOKYO_PROXY_IP:3128
export HTTP_PROXY=http://$TOKYO_PROXY_IP:3128
export HTTPS_PROXY=http://$TOKYO_PROXY_IP:3128
EOF
chmod +x /etc/profile.d/proxy.sh

# Add to ubuntu user's .bashrc
echo "Configuring ubuntu user .bashrc..."
cat >> /home/ubuntu/.bashrc <<'EOF'

# Proxy configuration for Tokyo egress
export http_proxy=http://$TOKYO_PROXY_IP:3128
export https_proxy=http://$TOKYO_PROXY_IP:3128
export HTTP_PROXY=http://$TOKYO_PROXY_IP:3128
export HTTPS_PROXY=http://$TOKYO_PROXY_IP:3128
EOF

# Replace placeholder in .bashrc
sed -i "s/\$TOKYO_PROXY_IP/$TOKYO_PROXY_IP/g" /home/ubuntu/.bashrc

chown ubuntu:ubuntu /home/ubuntu/.bashrc

echo "Proxy configured successfully"
echo "=========================================="
echo "Singapore User Data Completed: $(date)"
echo "=========================================="

echo "SUCCESS" > /tmp/user-data-complete