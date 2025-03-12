SCRIPT_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_DIR=$(basename $SCRIPT_PATH)

FIRMWARE="ast-firmware wd719x-firmware"

sudo ufw allow 53317/tcp
sudo ufw allow 53317/udp
sudo ufw reload

balooctl6 suspend
balooctl6 disable
balooctl6 purge

cp $SCRIPT_PATH/configs/config.fish ~/.config/fish
cp $SCRIPT_PATH/configs/Fish.profile ~/.local/share/konsole
echo "--ozone-platform-hint=auto" > ~/.config/chromium-flags.conf
cp $SCRIPT_PATH/configs/.vimrc ~
mkdir ~/.config/fastfetch
cp $SCRIPT_PATH/configs/config.jsonc ~/.config/fastfetch
echo "fastfetch" >> ~/.bashrc

flatpak install flathub io.github.ungoogled_software.ungoogled_chromium org.onlyoffice.desktopeditors com.vscodium.codium org.telegram.desktop org.localsend.localsend_app io.freetubeapp.FreeTube com.github.unrud.VideoDownloader app.drey.Dialect com.bitwarden.desktop org.gnome.Calculator

git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..
rm -rf paru

paru -S portproton cachyos-ananicy-rules-git \
ttf-symbola ttf-impallari-cantora ttf-courier-prime ttf-gelasio-ib ttf-merriweather ttf-signika consolas-font apple-fonts $FIRMWARE
# ttf-source-sans-pro-ibx
sudo systemctl restart ananicy-cpp
