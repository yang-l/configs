#!/usr/bin/env bash
set -ex

# network
echo 'nameserver 1.1.1.1' | tee /etc/resolv.conf.head

# partition
sgdisk -og ${DISK}
sgdisk -n 1:0:+1M  -c 1:"Linux GRUB partition" -t 1:ef02 -A 1:set:2 ${DISK}
sgdisk -n 2:0:+64M -c 2:"Linux boot partition" -t 2:8300            ${DISK}
sgdisk -n 3:0:0    -c 3:"Linux root partition" -t 3:8300            ${DISK}
sync
mkfs.ext2 ${DISK}2
mkfs.ext4 ${DISK}3

# mount
mount ${DISK}3 ${BASE_DIR}
mkdir ${BASE_DIR}/boot
mount ${DISK}2 ${BASE_DIR}/boot

# stage 3
curl -# -N ${STAGE3_URL} | tar xJp -C ${BASE_DIR}

# bindings
mount -t proc /proc ${BASE_DIR}/proc
mount --rbind /sys ${BASE_DIR}/sys
mount --make-rslave ${BASE_DIR}/sys
mount --rbind /dev ${BASE_DIR}/dev
mount --make-rslave ${BASE_DIR}/dev

# make_conf
MAKE_CONF=${BASE_DIR}/etc/portage/make.conf
MAKE_OPS="-j$(( ${CPU} + 1 ))"
sed -i "s/COMMON_FLAGS=.*/COMMON_FLAGS=\"-march=native -O2 -pipe\"/g" $MAKE_CONF
echo "MAKEOPS=\"${MAKE_OPS}\"" >> $MAKE_CONF

# portage
cp --dereference /etc/resolv.conf ${BASE_DIR}/etc/
chroot ${BASE_DIR} /bin/bash << 'EOF'
set -ex
mkdir -p /usr/portage
time emerge-webrsync
time emerge -vuDNq --with-bdeps y @world
emerge --depclean
etc-update --automode -3
EOF

# timezone
echo "UTC" > ${BASE_DIR}/etc/timezone
chroot ${BASE_DIR} /bin/bash << 'EOF'
set -ex
emerge -vq --config sys-libs/timezone-data
EOF

# locale
chroot ${BASE_DIR} /bin/bash << 'EOF'
set -ex
eselect locale set "C.utf8"
EOF

# /etc/fstab
echo "# <fs>    <mount> <type> <opts>         <dump/pass>" >> $BASE_DIR/etc/fstab
echo "/dev/sda2 /boot   ext2   noauto,noatime 1 2"         >> $BASE_DIR/etc/fstab
echo "/dev/sda3 /       ext4   noatime        0 1"         >> $BASE_DIR/etc/fstab

# kernel
cp /etc/kernels/kernel.config ${BASE_DIR}/tmp/kernel.config
chroot ${BASE_DIR} /bin/bash << 'EOF'
set -ex
echo "sys-kernel/genkernel -firmware" >> /etc/portage/package.use/genkernel
time emerge -vq --autounmask-continue=y sys-kernel/gentoo-sources sys-kernel/genkernel
time genkernel --kernel-config=/tmp/kernel.config --no-splash --no-lvm --no-mdadm --no-dmraid --no-luks --no-iscsi --no-multipath --no-hyperv --no-ssh --no-unionfs --no-zfs --no-btrfs --no-nfs --makeopts=-j$(( ${CPU} + 1 )) --install --symlink all
EOF

# vb guest
chroot ${BASE_DIR} /bin/bash << 'EOF'
set -ex
time emerge -vq app-emulation/virtualbox-guest-additions
rc-update add virtualbox-guest-additions default
EOF

# grub
chroot ${BASE_DIR} /bin/bash << 'EOF'
set -ex
time emerge -vq sys-boot/grub:2
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# user
chroot ${BASE_DIR} /bin/bash << 'EOF'
set -ex
echo "app-admin/sudo -sendmail" >> /etc/portage/package.use/sudo
time emerge -vq app-admin/sudo
useradd --password $( openssl passwd -1 vagrant ) --comment 'Vagrant User' --create-home --groups vboxguest,wheel --user-group vagrant -s /bin/bash
echo 'vagrant ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_vagrant
EOF

# network
chroot ${BASE_DIR} /bin/bash << 'EOF'
set -ex
echo 'nameserver 1.1.1.1' | tee /etc/resolv.conf.head
ln -s /etc/init.d/net.lo /etc/init.d/net.enp0s3
echo 'config_enp0s3=( "dhcp" )' | tee /etc/conf.d/net
rc-update add net.enp0s3 default
EOF

# clean up
chroot ${BASE_DIR} /bin/bash << 'EOF'
set -ex
cd /usr/src/linux
make clean
emerge -C sys-kernel/gentoo-sources
EOF

chroot ${BASE_DIR} /bin/bash << 'EOF'
set -ex
emerge -vq --autounmask-continue=y sys-fs/zerofree
EOF

chroot ${BASE_DIR} /bin/bash << 'EOF'
set -ex
eselect news read --quiet
etc-update --automode -3
EOF

rm -rf ${BASE_DIR}/usr/portage
rm -rf ${BASE_DIR}/tmp/*
rm -rf ${BASE_DIR}/var/log/*
rm -rf ${BASE_DIR}/var/tmp/*

mount -o remount,ro ${BASE_DIR}
mount -o remount,ro ${BASE_DIR}/boot
chroot ${BASE_DIR} /bin/bash << 'EOF'
set -ex
zerofree -v ${DISK}2
zerofree -v ${DISK}3
EOF

# umount
umount -l /mnt/gentoo{/dev,/proc,/sys}
umount -R /mnt/gentoo
