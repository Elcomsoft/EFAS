#!/bin/bash

function assert () {
    err=$1
    echo "FATAL: $err"
    exit 1
}

ROOTPART=$(mount | grep " on / " | cut -d ' ' -f1)
ROOTDISK=${ROOTPART:0:-2}

(
    echo "d"
    echo "2"
    echo "n"
    echo "p"
    echo "2"
    echo ""
    echo ""
    echo "n"
    echo "w"
) | fdisk ${ROOTDISK} || assert

resize2fs ${ROOTPART} || assert

systemctl disable firstboot.service
rm /etc/systemd/system/firstboot.service
rm $(readlink -f $0)
echo "DONE firstboot!"