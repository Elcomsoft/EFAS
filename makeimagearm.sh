#!/bin/bash

#wget -c http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz
#cat ArchLinuxARM-rpi-aarch64-latest.tar.gz | docker import --platform linux/arm64  - archlinuxarm
docker run --privileged --platform linux/arm64/v8 --rm -v $(pwd):/build -it archlinuxarm /build/buildarm.sh
echo "Done!"