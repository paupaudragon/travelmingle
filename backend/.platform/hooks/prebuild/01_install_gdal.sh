#!/bin/bash
set -xe

# Create installation directory
mkdir -p /tmp/gis-deps
cd /tmp/gis-deps

# Install PROJ
wget https://download.osgeo.org/proj/proj-9.5.1.tar.gz
tar -xzf proj-9.5.1.tar.gz
cd proj-9.5.1
mkdir build && cd build
cmake ..
cmake --build . -j$(nproc)
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
make install -j$(nproc)
cd /tmp/gis-deps

# Install GDAL
wget https://github.com/OSGeo/gdal/releases/download/v3.10.0/gdal-3.10.0.tar.gz
tar -xzf gdal-3.10.0.tar.gz
cd gdal-3.10.0
mkdir build && cd build
cmake ..
cmake --build . -j$(nproc)
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
make install -j$(nproc)

# Update library path
echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf
ldconfig

# Cleanup
cd /
rm -rf /tmp/gis-deps