#!/bin/bash
# Update and install Apache
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Define different HTML contents based on AZ
HTML_CONTENT_1="<h1>Welcome to Website - Region 1</h1><p>This is the version for us-east-1a region.</p>"
HTML_CONTENT_2="<h1>Hello from Website - Region 2</h1><p>This is the version for us-east-1b region.</p>"

# Get the availability zone from instance metadata
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

# Choose content based on AZ
if [[ "$AZ" == "us-east-1a" ]]; then
  echo "$HTML_CONTENT_1" > /var/www/html/index.html
elif [[ "$AZ" == "us-east-1b" ]]; then
  echo "$HTML_CONTENT_2" > /var/www/html/index.html
else
  echo "<h1>Default Website</h1><p>Region not specifically handled: $AZ</p>" > /var/www/html/index.html
fi

# Append AZ for verification
echo "<h2>This instance is running in Availability Zone: $AZ</h2>" >> /var/www/html/index.html
