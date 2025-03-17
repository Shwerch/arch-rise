EFI_SIZE="128M"
export ZRAM_SIZE="8G"
BACKUP_NAME="luks-header-backup"
export GRUB_GFXMODE="1920x1080"
export GRUB_TIMEOUT="1"

SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export SCRIPT_DIR=$(basename $SCRIPT_PATH)

lsblk -p
read -p "Enter the disk on which the system will be installed. Data on the disk will be wiped! (examples: /dev/sda /dev/nvme0n1 and etc) " DEV
if [[ $DEV == "/dev/nvme"* ]]; then
  _D1="p1"
  _D2="p2"
else
  _D1="1"
  _D2="2"
fi

export DEV1="$DEV$_D1"
export DEV2="$DEV$_D2"

export CRYPTROOT="cryptroot"
export ROOT="/dev/mapper/$CRYPTROOT"

read -p "Do you agree to destroy all the data on the $DEV and create patritions $DEV1 $DEV2 ? [Y/n] " ACCEPT
if [[ "${ACCEPT,,}" != "y" ]]; then
  echo "Installation aborted"
  exit 1
fi

read -p "Enter hostname: " _HOSTNAME
export HOSTNAME=${_HOSTNAME:-"archlinux"}

read -p "Enter username: " _USERNAME
export USERNAME=${_USERNAME:-"ultra"}

read -p "Enter timezone: " _ZONEINFO
export ZONEINFO=${_ZONEINFO:-"Asia/Krasnoyarsk"}

read -p "Enter bootloader ID. Use only English letters, not spaces or other special symbols! " _BOOTLOADER_ID
export BOOTLOADER_ID=${_BOOTLOADER_ID:-"ArchLinux"}

read -p "Do you want to disable mitigations? [y/N] " _MITIGATIONS_OFF
if [[ "${_MITIGATIONS_OFF,,}" == "y" ]]; then
  export MITIGATIONS_OFF="y"
else
  export MITIGATIONS_OFF="n"
fi

read -p "Do you want to disable selinux? [y/N] " _SELINUX_OFF
if [[ "${_SELINUX_OFF,,}" == "y" ]]; then
  export SELINUX_OFF="y"
else
  export SELINUX_OFF="n"
fi

read -p "Choose main language of the system: Russian or English? [ru/EN] " _LANGUAGE
if [[ "${_LANGUAGE,,}" == "ru" ]]; then
  export LANGUAGE="ru_RU.UTF-8"
else
  export LANGUAGE="en_US.UTF-8"
fi

echo "Enter patrition password. Password will be hidden"
_PASSWORD1="1"
_PASSWORD2="2"
while [ $_PASSWORD1 != $_PASSWORD2 ]
do
  if [[ $_PASSWORD1 != "1" && $_PASSWORD2 != "2" ]]; then
    echo "Password does not match!"
  fi
  read -s -p "Password: " _PASSWORD1
  echo ""
  read -s -p "Re-enter: " _PASSWORD2
  echo ""
done
export PASSWORD=$_PASSWORD1

(
  echo g;

  echo n;
  echo ;
  echo ;
  echo +$EFI_SIZE;
  echo t;
  echo uefi;

  echo n;
  echo ;
  echo ;
  echo ;

  echo p;
  echo w;
) | fdisk $DEV

mkfs.fat -F 32 $DEV1

echo $PASSWORD | cryptsetup luksFormat --pbkdf pbkdf2 --sector-size=4096 $DEV2
cryptsetup luksHeaderBackup $DEV2 --header-backup-file $BACKUP_NAME
echo $PASSWORD | cryptsetup open $DEV2 $CRYPTROOT
mkfs.ext4 $ROOT

export DEV1_UUID=$(blkid $DEV1 -o value -s UUID)
export DEV2_UUID=$(blkid $DEV2 -o value -s UUID)
export ROOT_UUID=$(blkid $ROOT -o value -s UUID)

mount $ROOT /mnt
mount --mkdir $DEV1 /mnt/efi

echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf
echo "Connect to Wi-Fi if needed"
iwctl station list
iwctl
reflector --verbose --country 'United States','Germany','Netherlands','Russia' --age 48 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
systemctl stop reflector

sed -i 's/#ParallelDownloads/ParallelDownloads/g' /etc/pacman.conf
sed -i 's/#Color/DisableDownloadTimeout/g' /etc/pacman.conf
echo "[multilib]" >> /etc/pacman.conf
echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
echo y | pacman -Sy archlinux-keyring

BASE="linux-zen linux-firmware linux-headers base base-devel intel-ucode amd-ucode flatpak vim nano htop"
BOOTLOADER="efibootmgr grub"
NETWORK="networkmanager ufw bluez bluez-utils bluez-obex"
PIPEWIRE="pipewire lib32-pipewire pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack lib32-pipewire-jack wireplumber realtime-privileges rtkit"
VIDEODRIVER="mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-mesa-layers opencl-rusticl-mesa lib32-opencl-rusticl-mesa"
KDE_PLASMA="sddm plasma konsole dolphin kio-admin spectacle ark"
SHELL="fish fastfetch"
UTILS="git clang android-tools exfatprogs reflector xdg-desktop-portal-gtk"
ARCHIVES="lrzip unrar unzip unace 7zip squashfs-tools"
PERFORMANCE="ananicy-cpp irqbalance"
FONTS="noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra \
ttf-liberation ttf-dejavu ttf-roboto \
ttf-jetbrains-mono ttf-fira-code ttf-hack adobe-source-code-pro-fonts \
ttf-caladea ttf-carlito ttf-opensans otf-overpass tex-gyre-fonts ttf-ubuntu-font-family"

pacstrap -K /mnt $BASE $BOOTLOADER $NETWORK $PIPEWIRE $VIDEODRIVER $KDE_PLASMA $SHELL $UTILS $ARCHIVES $PERFORMANCE $FONTS

genfstab -U /mnt >> /mnt/etc/fstab

cp -r $SCRIPT_PATH /mnt
arch-chroot /mnt ./$SCRIPT_DIR/chroot.sh
cp $BACKUP_NAME /mnt/home/$USERNAME
cp -r $SCRIPT_PATH /mnt/home/$USERNAME
rm -rf /mnt/$SCRIPT_DIR

echo "The installation is complete. You are on an installed system as root using arch-chroot. \
Enter additional commands to configure the system, if necessary, and reboot by entering the \"exit\" and \"reboot\" commands."
arch-chroot /mnt