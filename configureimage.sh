#!/bin/bash

function assert () {
    err=$1
    echo "FATAL: $err"
    exit 1
}

echo "*** Stage2: Image package installation ***"

# Clean caches
rm -f /var/cache/pacman/pkg/* || assert
rm -f /var/lib/pacman/sync/* || assert

sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 20/g" /etc/pacman.conf  || assert
pacman --noconfirm -Suy  || assert
pacman --disable-download-timeout --noconfirm -S \
                                            firmware-raspberrypi \
                                            fuse \
                                            git \
                                            gptfdisk \
                                            htop \
                                            less \
                                            linux-rpi \
                                            nano \
                                            networkmanager \
                                            ntp \
                                            openssh \
                                            raspberrypi-bootloader \
                                            sudo \
                                            usbmuxd \
                                            wget \
    || assert


echo "*** Stage2: Image package configuration ***"
systemctl enable NetworkManager || assert
systemctl enable sshd || assert
systemctl enable ntpd || assert
systemctl enable firstboot || assert

## Allow sudo to be used
sed -i "s/# %sudo/%sudo/g" /etc/sudoers || assert
groupadd sudo || assert

## Add eift user
useradd -G sudo -ms /bin/bash eift || assert
(echo "Elcomsoft";echo "Elcomsoft") | passwd eift || assert

## Don't lockout after 3 invalid login attempts
echo "deny=0" >> /etc/security/faillock.conf || assert

chown -R eift:eift /home/eift

## Setup system
# Configure mounts based on labels
echo -e "LABEL=piroot\t/\text4\trw,relatime\t0\t1" >> /etc/fstab || assert
echo -e "LABEL=PIBOOT\t/boot\tvfat\trw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro\t0\t2" >> /etc/fstab || assert

# Set hostname
echo "EFASpi5" > /etc/hostname || assert

# Configure locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen || assert
echo "LANG=en_US.UTF-8" > /etc/locale.conf || assert
locale-gen || assert

# Add ld search path
echo "/usr/local/lib" >> /etc/ld.so.conf || assert

#enable PCIe port
sed -i "s/#dtparam/dtparam=pciex1 #/g" /boot/config.txt || assert

## Cleanup
echo "*** Stage2: Cleanup image ***"
# Clean caches
rm -f /var/cache/pacman/pkg/* || assert
rm -f /var/lib/pacman/sync/* || assert

echo "*** Stage2: Done ***"
