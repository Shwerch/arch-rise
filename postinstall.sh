SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_DIR=$(basename $SCRIPT_PATH)

sudo ufw allow 53317/tcp
sudo ufw allow 53317/udp
sudo ufw reload

balooctl6 suspend
balooctl6 disable
balooctl6 purge

mkdir ~/.config/fish
cp $SCRIPT_PATH/configs/config.fish ~/.config/fish
cp $SCRIPT_PATH/configs/Fish.profile ~/.local/share/konsole
echo "--ozone-platform-hint=auto" > ~/.config/chromium-flags.conf
cp $SCRIPT_PATH/configs/.vimrc ~
mkdir ~/.config/fastfetch
cp $SCRIPT_PATH/configs/config.jsonc ~/.config/fastfetch
echo "fastfetch" >> ~/.bashrc

git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..
rm -rf paru

BROWSER="io.github.ungoogled_software.ungoogled_chromium io.gitlab.librewolf-community"
OFFICE="org.onlyoffice.desktopeditors"
CODE_EDITOR="com.vscodium.codium"
MESSENGER="org.telegram.desktop"
TORRENT="org.qbittorrent.qBittorrent"
FILE_SHARER="org.localsend.localsend_app"
YOUTUBE="io.freetubeapp.FreeTube com.github.unrud.VideoDownloader"
TRANSLATOR="app.drey.Dialect"
CALCULATOR="org.gnome.Calculator"
VIDEO="org.kde.haruna org.kde.kdenlive"
IMAGE="org.kde.gwenview org.gimp.GIMP"
AUDIO="org.tenacityaudio.Tenacity"
ISO_WRITER="org.kde.isoimagewriter"

GAMES="portproton"
VENTOY="ventoy-bin"
PERFORMANCE="cachyos-ananicy-rules-git"
FIRMWARE="ast-firmware wd719x-firmware"
FONTS="ttf-symbola ttf-impallari-cantora ttf-courier-prime ttf-gelasio-ib ttf-merriweather ttf-signika consolas-font apple-fonts"
# ttf-source-sans-pro-ibx

flatpak install flathub $BROWSER $OFFICE $CODE_EDITOR $MESSENGER $TORRENT $FILE_SHARER $YOUTUBE $TRANSLATOR $CALCULATOR $VIDEO $IMAGE $AUDIO $ISO_WRITER

paru -S $GAMES $VENTOY $PERFORMANCE $FIRMWARE $FONTS
sudo systemctl restart ananicy-cpp
