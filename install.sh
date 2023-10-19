#!/bin/bash

# Check for root rights
if [ "$EUID" -ne 0 ]
  then echo "Script must be executed with sudo rights"
  exit
fi


# Install dependencies
sudo apt install -y git sed hostapd python3-pip raspi-config iptables iptables-persistent

# Install python libs
pip3 install RPi.GPIO spidev pillow qrcode

# Clone eink lib
mkdir tmp
cd tmp
git clone https://github.com/waveshare/e-Paper.git

# Copy e-ink library into source
cp -r e-Paper/RaspberryPi_JetsonNano/python/lib ../src

# Clean up
cd ..
rm -rf tmp

# Set timezone
sudo timedatectl set-timezone Europe/Berlin

# Unmask hostapd
sudo systemctl unmask hostapd

# Install to opt
sudo mkdir /opt/gapi4
sudo cp -r src/* /opt/gapi4
sudo cp src/gapi4.service /etc/systemd/system/
# Place configuration file
sudo cp gapi4.conf /etc/
# Prepare webserver directory
sudo mkdir /opt/gapi4/www

# Enable IP forwarding
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl -p
# Configure masquerading
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
# Make this change persistent
sudo iptables-save > /etc/iptables/rules.v4

# Enable and start service
sudo systemctl enable gapi4.service
sudo systemctl start gapi4.service