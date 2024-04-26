#!/bin/bash

function assert () {
    err=$1
    echo "FATAL: $err"
    exit 1
}


# Clean caches
rm -f /var/cache/pacman/pkg/* || assert
rm -f /var/lib/pacman/sync/* || assert


echo "*** Stage3: Extra utilities installation ***"
pacman --disable-download-timeout --noconfirm -Suy \
                                            automake \
                                            base-devel \
                                            fakeroot \
                                            go \
    || assert

sed -i 's/#MAKEFLAGS/MAKEFLAGS="-j4" #/g' /etc/makepkg.conf || assert

chown -R eift /home/eift

mkdir mytmp || assert
chmod 777 mytmp || assert
cd mytmp
su -c 'git clone https://aur.archlinux.org/yay.git' eift || assert
cd yay || assert
su -c makepkg eift || assert
pacman --noconfirm -U yay-*.tar.xz || assert
cd ..
rm -rf yay
cd ..
rm -rf mytmp

#Temporarily disable asking for password on pacman
echo '' >> /etc/sudoers || assert
echo 'eift ALL=(ALL) NOPASSWD: /usr/bin/pacman' >> /etc/sudoers || assert

# YAYPACKAGES="swapspace"

# for pkg in ${YAYPACKAGES}; do 
#     su -c "yay --disable-download-timeout --noconfirm -S \
#                                                 ${pkg} \
#         " eift && rm -rf /home/eift/.cache || assert
# done

rm -rf /home/eift/.cache

#Re-enable asking for password on pacman
head -n -1 /etc/sudoers > /etc/sudoers.new  || assert
mv /etc/sudoers.new /etc/sudoers || assert

# systemctl enable swapspace || assert

PACKAGES="  alacritty \
            ark \
            bash-completion \
            btrfs-progs \
            firefox \
            gdm \
            gwenview \
            ibus \
            kate \
            libreoffice \
            nemo \
            okular \
            plasma \
            qt5-tools \
            vlc \
            xorg-xwayland \
"

echo "*** Stage3: Image GUI installation ***"

for PKG in ${PACKAGES}; do
    pacman --noconfirm -Sc
    pacman --disable-download-timeout --noconfirm -Sy ${PKG} || assert
done

echo "*** Stage3: Image package configuration ***"
systemctl enable gdm || assert


#set login wallpaper
rm -f /usr/share/gnome-shell/gnome-shell-theme.gresource
cp /usr/share/gnome-shell/gnome-shell-theme.gresource.my /usr/share/gnome-shell/gnome-shell-theme.gresource


usermod -aG video eift || assert
usermod -aG storage eift || assert

## Cleanup
echo "*** Stage3: Cleanup image ***"
# Clean caches
rm -f /var/cache/pacman/pkg/* || assert
rm -f /var/lib/pacman/sync/* || assert

echo "*** Stage3: Done ***"
