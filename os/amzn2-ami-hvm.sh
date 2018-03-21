#!/bin/bash

set -e

# http://amzn.to/2EWiqLg

sudo amazon-linux-extras enable nginx1.12 php7.2
sudo yum install nginx php-cli php-fpm php-json -y
sudo yum update -y
