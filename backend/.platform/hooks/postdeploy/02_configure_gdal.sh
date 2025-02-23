#!/bin/bash

# Enable debugging and exit on error
set -xe

# Create symbolic links if needed
if [ ! -e /usr/lib/libgdal.so ]; then
    ln -s /usr/lib64/libgdal.so /usr/lib/libgdal.so
fi

if [ ! -e /usr/lib/libgeos_c.so ]; then
    ln -s /usr/lib64/libgeos_c.so /usr/lib/libgeos_c.so
fi

# Set environment variables
echo "export GDAL_LIBRARY_PATH=/usr/lib64/libgdal.so" >> /opt/elasticbeanstalk/deployment/env
echo "export GEOS_LIBRARY_PATH=/usr/lib64/libgeos_c.so" >> /opt/elasticbeanstalk/deployment/env