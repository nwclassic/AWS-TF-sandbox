#!/bin/bash
sudo yum update -y && sudo yum install -y docker
sudo systemctl start docker
# adds ec2-user to docker group
sudo usermod -aG docker ec2-user

# Use this to run from you local machine with "user-data" inline
# docker run -p 8080:80 nginx

# Use this to run remotely with provisioner file first, then inline
docker run -dp 8080:80 nginx

