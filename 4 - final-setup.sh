echo -e "\nFINAL SETUP AND CONFIGURATION"

# ------------------------------------------------------------------------

echo -e "\nGenaerating .xinitrc file"

# Generate the .xinitrc file so we can launch Awesome from the
# terminal using the "startx" command
cat <<EOF > ${HOME}/.xinitrc
#!/bin/bash
# Disable bell
xset -b
# Disable all Power Saving Stuff
xset -dpms
xset s off
# X Root window color
xsetroot -solid darkgrey
# Merge resources (optional)
#xrdb -merge $HOME/.Xresources
# Caps to Ctrl, no caps
setxkbmap -layout us -option ctrl:nocaps
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
        [ -x "\$f" ] && . "\$f"
    done
    unset f
fi
exit 0
EOF

# ------------------------------------------------------------------------

echo -e "\nUpdating /bin/startx to use the correct path"

# By default, startx incorrectly looks for the .serverauth file in our HOME folder.
sudo sed -i 's|xserverauthfile=\$HOME/.serverauth.\$\$|xserverauthfile=\$XAUTHORITY|g' /bin/startx

# ------------------------------------------------------------------------

echo -e "\nConfiguring LTS Kernel as a secondary boot option"

sudo cp /boot/loader/entries/arch.conf /boot/loader/entries/arch-lts.conf
sudo sed -i 's|Arch Linux|Arch Linux LTS Kernel|g' /boot/loader/entries/arch-lts.conf
sudo sed -i 's|vmlinuz-linux|vmlinuz-linux-lts|g' /boot/loader/entries/arch-lts.conf
sudo sed -i 's|initramfs-linux.img|initramfs-linux-lts.img|g' /boot/loader/entries/arch-lts.conf

# ------------------------------------------------------------------------

echo -e "\nConfiguring vconsole.conf to set a larger font for login shell"

sudo cat <<EOF > /etc/vconsole.conf
KEYMAP=us
FONT=ter-v32b
EOF

# ------------------------------------------------------------------------

echo -e "\nDisabling buggy cursor inheritance"

# When you boot with multiple monitors the cursor can look huge. This fixes it.
sudo cat <<EOF > /usr/share/icons/default/index.theme
[Icon Theme]
#Inherits=Theme
EOF

# ------------------------------------------------------------------------

echo -e "\nIncreasing file watcher count"

# This prevents a "too many files" error in Visual Studio Code
echo fs.inotify.max_user_watches=524288 | sudo tee /etc/sysctl.d/40-max-user-watches.conf && sudo sysctl --system

# ------------------------------------------------------------------------

echo -e "\nEnabling Login Display Manager"

sudo systemctl enable --now lightdm.service

# ------------------------------------------------------------------------

echo -e "\nEnabling the NetworkManager instead of dhcpd"

sudo systemctl disable dhcpcd.service
sudo systemctl stop dhcpcd.service
sudo systemctl enable --now NetworkManager.service
echo "
###############################################################################
# Cleaning
###############################################################################
"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Clean orphans pkg
if [[ ! -n $(pacman -Qdt) ]]; then
	echo "No orphans to remove."
else
	pacman -Rns $(pacman -Qdtq)
fi

# Replace in the same state
cd $pwd
echo "
###############################################################################
# Done
###############################################################################
"