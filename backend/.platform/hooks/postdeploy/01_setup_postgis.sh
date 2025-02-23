#!/bin/bash

# Enable debugging and exit on error
set -xe

# Install PostgreSQL and PostGIS
amazon-linux-extras enable postgresql12
yum clean metadata
yum install -y postgresql postgresql-devel
yum install -y gdal-devel
yum install -y proj-devel
yum install -y geos-devel
yum install -y postgis31_12 postgis31_12-client

# Set file permissions
chmod 755 /usr/lib64/libgeos_c.so*
chmod 755 /usr/lib64/libproj.so*
chmod 755 /usr/lib64/libgdal.so*