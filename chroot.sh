sed -i 's/#ParallelDownloads/ParallelDownloads/g' /etc/pacman.conf
sed -i 's/#Color/DisableDownloadTimeout/g' /etc/pacman.conf
sed -i 's/#CacheDir/CacheDir /g' /etc/pacman.conf
sed -i 's/\/var\/cache\/pacman\/pkg\//\/tmp/g' /etc/pacman.conf
echo "[multilib]" >> /etc/pacman.conf
echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
pacman -Syu

ln -sf /usr/share/zoneinfo/$ZONEINFO /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LANGUAGE" > /etc/locale.conf

echo "$HOSTNAME" > /etc/hostname
echo "127.0.0.1	localhost" > /etc/hosts
echo "::1	localhost" >> /etc/hosts
echo "127.0.1.1	$HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

useradd -m $USERNAME
usermod -aG wheel,audio,video,storage,lp,realtime $USERNAME
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers

systemctl enable NetworkManager bluetooth ufw
systemctl enable sddm
systemctl enable systemd-oomd ananicy-cpp irqbalance fstrim.timer
systemctl --user enable pipewire pipewire.socket pipewire-pulse wireplumber
systemctl mask NetworkManager-wait-online.service
systemctl --user mask kde-baloo.service
systemctl --user mask plasma-baloorunner.service

echo "vm.swappiness = 100" > /etc/sysctl.d/90-sysctl.conf
echo "vm.dirty_background_bytes=67108864" > /etc/sysctl.d/30-dirty-pages.conf
echo "vm.dirty_bytes=268435456" >> /etc/sysctl.d/30-dirty-pages.conf
echo "vm.dirty_expire_centisecs=1500" > /etc/sysctl.d/30-dirty-pages-expire.conf
echo "vm.dirty_writeback_centisecs=100" > /etc/sysctl.d/30-dirty-pages-writeback.conf
echo "vm.vfs_cache_pressure = 50" > /etc/sysctl.d/90-vfs-cache.conf
cp /$SCRIPT_DIR/configs/90-io-schedulers.rules /etc/udev/rules.d
echo "vm.page-cluster = 0" > /etc/sysctl.d/99-sysctl.conf
echo "vm.max_map_count = 1048576" >> /etc/sysctl.d/99-sysctl.conf
echo "options libahci ignore_sss=1" > /etc/modprobe.d/30-ahci-disable-sss.conf
echo "kernel.watchdog = 0" > /etc/sysctl.d/30-no-watchdog-timers.conf
echo "blacklist sp5100-tco" > /etc/modprobe.d/30-blacklist-watchdog-timers.conf
echo "blacklist blacklist iTCO_wdt" >> /etc/modprobe.d/30-blacklist-watchdog-timers.conf

echo "zram" >> /etc/modules-load.d/zram.conf
echo "ACTION==\"add\", KERNEL==\"zram0\", ATTR{initstate}==\"0\", ATTR{comp_algorithm}=\"zstd\", ATTR{disksize}=\"$ZRAM_SIZE\", RUN=\"/usr/bin/mkswap -U clear %N\", TAG+=\"systemd\"" > /etc/udev/rules.d/99-zram.rules
echo "/dev/zram0 none swap defaults,discard,pri=100 0 0" >> /etc/fstab

KEY="/etc/cryptsetup-keys.d/$CRYPTROOT.key"
dd bs=512 count=4 if=/dev/random iflag=fullblock | install -m 0600 /dev/stdin $KEY
echo $PASSWORD | cryptsetup -v luksAddKey $DEV2 $KEY

sed -i 's/FILES/#FILES/g' /etc/mkinitcpio.conf
sed -i 's/HOOKS/#HOOKS/g' /etc/mkinitcpio.conf
echo "FILES=($KEY)" >> /etc/mkinitcpio.conf
echo "HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)" >> /etc/mkinitcpio.conf
mkinitcpio -P

GRUB_CMDLINE_LINUX="GRUB_CMDLINE_LINUX=\"loglevel=3 quiet"

read -p "Do you want to disable mitigations? [y/N] " MITIGATIONS_OFF
if [[ "${MITIGATIONS_OFF,,}" != "n" ]]; then
  GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX mitigations=off"
fi

read -p "Do you want to disable selinux? [y/N] " SELINUX_OFF
if [[ "${SELINUX_OFF,,}" != "n" ]]; then
  GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX selinux=0"
fi

GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX cryptdevice=UUID=$DEV2_UUID:$CRYPTROOT cryptkey=rootfs:$KEY root=UUID=$ROOT_UUID\""

read -p "Enter bootloader ID. Use only english letters, not spaces or other special symbols! " _BOOTLOADER_ID
BOOTLOADER_ID=${_BOOTLOADER_ID:-ARCHLINUX}

sed -i 's/GRUB_TIMEOUT/#GRUB_TIMEOUT/g' /etc/default/grub
sed -i 's/GRUB_CMDLINE_LINUX/#GRUB_CMDLINE_LINUX/g' /etc/default/grub
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
echo "GRUB_GFXMODE=$GRUB_GFXMODE" >> /etc/default/grub
echo "GRUB_TIMEOUT=$GRUB_TIMEOUT" >> /etc/default/grub
echo $GRUB_CMDLINE_LINUX >> /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=$BOOTLOADER_ID --recheck
grub-mkconfig -o /boot/grub/grub.cfg

echo "Enter root password. If failed, enter \"passwd\" command again after the end of script execution"
passwd
echo "Enter $USERNAME password. If failed, enter \"passwd $USERNAME\" command again after the end of script execution"
passwd $USERNAME
exit