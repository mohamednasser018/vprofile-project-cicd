#!/bin/bash

# Install Java and wget
apt update
apt install openjdk-8-jdk wget -y

# Set up JAVA_HOME environment variable
JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")
echo "JAVA_HOME=$JAVA_HOME" >> /etc/environment
source /etc/environment

# Create directories
mkdir -p /opt/nexus/
mkdir -p /tmp/nexus/

cd /tmp/nexus/

# Download Nexus
NEXUSURL="https://download.sonatype.com/nexus/3/latest-unix.tar.gz"
wget $NEXUSURL -O nexus.tar.gz

# Extract Nexus
tar xzvf nexus.tar.gz
NEXUSDIR=$(tar tzf nexus.tar.gz | head -1 | cut -f1 -d'/')
sleep 5

# Clean up
rm -rf /tmp/nexus/nexus.tar.gz
cp -r /tmp/nexus/* /opt/nexus/
sleep 5

# Create nexus user
useradd nexus
chown -R nexus:nexus /opt/nexus

# Create systemd service file
cat <<EOT >> /etc/systemd/system/nexus.service
[Unit]
Description=Nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/$NEXUSDIR/bin/nexus start
ExecStop=/opt/nexus/$NEXUSDIR/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOT

# Configure Nexus to run as the nexus user
echo 'run_as_user="nexus"' > /opt/nexus/$NEXUSDIR/bin/nexus.rc

# Reload systemd and start Nexus
systemctl daemon-reload
systemctl start nexus
systemctl enable nexus
