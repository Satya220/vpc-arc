#!/bin/bash
sudo apt-get check-update
sudo apt-get update
sudo apt-get install apache2
sudo systemctl start apache2
sudo systemctl enable apache2
sudo systemctl status apache2
echo "Hello" > /var/www/html/index.html