#!/bin/bash

# Ask for the subdomain name
read -p "What is the (sub)domain name you want to use for Dynmap? (e.g., map.yoursite.com): " ccdomain

# Ask for the IP and port
read -p "What is the IP address of your Minecraft server and the port Dynmap is running on? (e.g., 192.168.1.101:8123): " ccip

# Define the Nginx configuration file path
nginx_conf="/etc/nginx/sites-available/$ccdomain.conf"

# Create Nginx configuration
echo "Creating Nginx configuration for $ccdomain..."
echo "server {
    server_name $ccdomain;
    listen 80;
    listen [::]:80;
    access_log /var/log/nginx/$ccdomain-access.log;
    error_log /var/log/nginx/$ccdomain-error.log;

    location / {
        proxy_pass http://$ccip;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}" > $nginx_conf

# Check for Nginx configuration syntax
echo "Checking Nginx configuration..."
nginx -t
if [ $? -ne 0 ]; then
    echo "Error in Nginx configuration. Please check the configuration."
    exit 1
fi

# Enable the site and reload Nginx
echo "Enabling site and reloading Nginx..."
ln -s /etc/nginx/sites-available/$ccdomain.conf /etc/nginx/sites-enabled/
systemctl reload nginx

# Set up SSL with Certbot
echo "Setting up SSL certificate for $ccdomain..."
certbot --nginx -d $ccdomain

# Check if Certbot succeeded
if [ $? -ne 0 ]; then
    echo "SSL setup failed. Please check Certbot output."
    exit 1
fi

echo "Your Dynmap reverse proxy is now set up and should be available at https://$ccdomain"
