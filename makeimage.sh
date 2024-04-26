#!/bin/bash

docker run --privileged --platform linux/amd64 --rm -v $(pwd):/build -i $@ archlinux:latest /build/build.sh
echo "Done!"