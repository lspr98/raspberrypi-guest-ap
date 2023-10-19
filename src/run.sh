#!/bin/bash

# Check if configuration file is missing
if [ ! -f /etc/gapi4.conf ]; then
    echo "Could not find Gapi4 configuration file at /etc/gapi4.conf"
    exit 1
fi

# Get configuration
source /etc/gapi4.conf

# Reconfigure netplan
# Remove old configurations
sudo rm /etc/netplan/*
# Copy template
sudo cp netplan.template.yaml /etc/netplan/netplan.yaml
# Insert IP in template
sudo sed -i -e "s/{ip}/$ip/g" /etc/netplan/netplan.yaml
# Apply settings
sudo netplan apply

# Start webserver in background if configured.
if [ "$enableWebServer" = true ]; then
    echo "Starting webserver..."
    # Requires sudo if port is < 1024.
    sudo python3 -m http.server -d /opt/gapi4/www -b $ip 80 &
else
    echo "Skipping webserver..."
fi

# Start hotspot update loop
while true
do

    # Generate new password
    newpass=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;`
    # Generate ssid
    newssid=`date +%s | sha256sum | base64 | head -c 10 ; echo`

    # Generate valid-until date
    currdate=$date
    validdate=`date '+%d.%m.%Y %T' --date="$currdate + $refreshCredentialsSeconds seconds"`

    echo "Changing SSID to $newssid - valid until $validdate"

    # Generate new config and update display
    python3 update.py $newssid $newpass `pwd` "$validdate"

    # Copy new config to destination
    sudo mv hostapd.conf /etc/hostapd/hostapd.conf

    # Copy new image and html file
    sudo mv index.html www
    sudo mv qrcode.png www

    # Restart hostapd service
    sudo systemctl restart hostapd.service

    sleep $refreshCredentialsSeconds
done



