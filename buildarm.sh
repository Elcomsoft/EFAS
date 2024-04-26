#!/bin/bash
SCRIPTROOT=$(readlink -f $0 | rev | cut -d '/' -f2- | rev)
IMAGE_NAME=${SCRIPTROOT}/wrk_EFASpi5.img
IMAGE_NAME_DONE=EFASpi5.img

function assert () {
    err=$1
    echo "FATAL: $err"
    exit 1
}

sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 20/g" /etc/pacman.conf

pacman-key --init
pacman-key --populate archlinuxarm

echo "*** Install dependencies ***"
pacman --noconfirm -Sy  pacman-contrib \
                            || assert

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist

pacman --noconfirm -Sy arch-install-scripts \
                        dosfstools \
                        nano \
                        wget \
                            || assert

echo "*** Create imagefile ***"
dd if=/dev/zero of=${IMAGE_NAME} bs=1M count=9500 || assert
(
    echo "o"
    echo "n"
    echo "p"
    echo "1"
    echo ""
    echo "+160M"
    echo "t"
    echo "c"
    echo "n"
    echo "p"
    echo "2"
    echo ""
    echo ""
    echo "w"
) | fdisk ${IMAGE_NAME} || assert

export PART1_BLOCK_START=$(fdisk -lu ${IMAGE_NAME} | grep img1 | tr -s ' ' | cut -d ' ' -f2)
export PART1_BLOCK_NUM=$(fdisk -lu ${IMAGE_NAME} | grep img1 | tr -s ' ' | cut -d ' ' -f4)
export PART2_BLOCK_START=$(fdisk -lu ${IMAGE_NAME} | grep img2 | tr -s ' ' | cut -d ' ' -f2)
export PART2_BLOCK_NUM=$(fdisk -lu ${IMAGE_NAME} | grep img2 | tr -s ' ' | cut -d ' ' -f4)
echo "PART1_BLOCK_START=${PART1_BLOCK_START}"
echo "PART1_BLOCK_NUM=${PART1_BLOCK_NUM}"
echo "PART2_BLOCK_START=${PART2_BLOCK_START}"
echo "PART2_BLOCK_NUM=${PART2_BLOCK_NUM}"
mkfs.vfat -F32 -n PIBOOT -s 1 -S 512 --offset ${PART1_BLOCK_START} ${IMAGE_NAME} $((${PART1_BLOCK_NUM}/2)) || assert
mkfs.ext4 -L piroot -E offset=$((${PART2_BLOCK_START}*512)) ${IMAGE_NAME} $((${PART2_BLOCK_NUM}/2)) || assert

function mount_image (){
    dstpath=$1
    mkdir -p /mnt1 || assert
    mount -o offset=$((512*${PART1_BLOCK_START})) ${IMAGE_NAME} /mnt1 || assert
    LODEV=$(losetup -a | grep "${IMAGE_NAME}" | cut -d ':' -f1)
    LOOFFSET=$(losetup -a | grep "${IMAGE_NAME}" | rev | cut -d ' ' -f1 | rev)
    echo "LODEV=${LODEV}"
    echo "LOOFFSET=${LOOFFSET}"
    mount -o offset=$((512*${PART2_BLOCK_START} - ${LOOFFSET})) ${LODEV} ${dstpath} || assert
    umount /mnt1 || assert
    rmdir /mnt1 || assert
    mkdir -p "${dstpath}/boot" || assert
    mount ${LODEV} "${dstpath}/boot" || assert
    echo "mount_image OK"
}

mount_image "/mnt" || assert

echo "*** Run pacstrap ***"
mkdir -p /mnt/usr/share/pacman/keyrings
cp /usr/share/pacman/keyrings/archlinuxarm.gpg /mnt/usr/share/pacman/keyrings/archlinuxarm.gpg
pacstrap /mnt/ base
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

arch-chroot /mnt/ /usr/bin/bash -c 'sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 20/g" /etc/pacman.conf' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'pacman-key --init' || assert
arch-chroot /mnt/ /usr/bin/bash -c 'pacman-key --populate archlinuxarm' || assert

echo "*** Copy config files ***"
#Copy pre-made files
cp -a ${SCRIPTROOT}/rootfs locrootfs
chown -R 0:0 locrootfs
cp -a locrootfs/* /mnt/ || assert

echo "*** Run configure script ***"
#run configuration script
cp ${SCRIPTROOT}/configureimage.sh /mnt || assert
arch-chroot /mnt/ /usr/bin/bash -c '/configureimage.sh' || assert
rm /mnt/configureimage.sh

echo "*** Run configureGUI script ***"
#run configuration script
cp ${SCRIPTROOT}/configureimageGUI.sh /mnt  || assert
arch-chroot /mnt/ /usr/bin/bash -c '/configureimageGUI.sh'  || assert
rm /mnt/configureimageGUI.sh


### Finialize ###
df -h
sync
umount /mnt/boot/ || assert
umount /mnt/ || assert

cp ${IMAGE_NAME} ${SCRIPTROOT}/${IMAGE_NAME_DONE}
rm ${IMAGE_NAME}
echo "*** DONE ***"