#!/bin/bash

# Update and install basic packages
sudo xbps-install -Syu

# Enable non-free repositories for additional software and drivers
echo "Enabling non-free repositories..."
echo "repository=https://alpha.de.repo.voidlinux.org/current/nonfree" | sudo tee -a /etc/xbps.d/00-repository-main.conf
sudo xbps-install -Syu

# Install essential tools
sudo xbps-install -y flatpak xbps-src pipewire pipewire-pulse kdeconnect vim keyd flatseal rstudio

# Install AMD graphics drivers and utilities
echo "Installing AMD graphics drivers and utilities..."
sudo xbps-install -y xf86-video-amdgpu mesa vulkan-loader mesa-vulkan-radeon radeontop vulkan-tools vulkan-validation-layers

# Manually install AMD GPU firmware from Linux Kernel Firmware repository
echo "Manually installing AMD GPU firmware..."
git clone https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
cd linux-firmware/amdgpu
sudo cp * /lib/firmware/amdgpu/
sudo dracut -f
cd ..
rm -rf linux-firmware
echo "AMD GPU firmware installed."

# Set up Zsh and Powerlevel10k
if [ "$SHELL" != "/bin/zsh" ]; then
    sudo xbps-install -y zsh
    chsh -s /bin/zsh
    sudo xbps-install -y git
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
    echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc
fi

# ZRAM setup
echo "Setting up ZRAM..."
sudo xbps-install -y zramctl
echo "zram" | sudo tee -a /etc/modules-load.d/zram.conf
echo "options zram num_devices=1" | sudo tee -a /etc/modprobe.d/zram.conf

sudo tee /etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = 8192MB
compression-algorithm = zstd
EOF

sudo systemctl enable --now /usr/lib/systemd/systemd-zram-setup@zram0.service

# Flatpak setup
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Snapper setup
echo "Setting up Snapper for Btrfs snapshots..."
sudo snapper -c root create-config /
sudo snapper -c home create-config /home

# Install and configure Neovim with LazyVim (if not done by Craft script)
if ! command -v nvim &> /dev/null; then
    echo "Installing Neovim and LazyVim..."
    sudo xbps-install -y neovim
    git clone https://github.com/LazyVim/starter ~/.config/nvim
fi

# Enable Pipewire and Pipewire-Pulse services
echo "Enabling Pipewire and Pipewire-Pulse services..."
sudo ln -s /etc/sv/pipewire /var/service/
sudo ln -s /etc/sv/pipewire-pulse /var/service/

# Install EasyEffects for advanced audio management
echo "Installing EasyEffects..."
sudo xbps-install -y easyeffects

# Install Obsidian via package (alternative to AppImage)
echo "Installing Obsidian..."
sudo xbps-install -y obsidian  # Replace with the correct package name if available

# Install full LaTeX suite (TeX Live)
echo "Installing full LaTeX suite (TeX Live)..."
sudo xbps-install -y texlive-full

# Install Pandoc and LaTeX template
echo "Installing Pandoc and LaTeX template..."
sudo xbps-install -y pandoc
git clone https://github.com/Wandmalfarbe/pandoc-latex-template.git ~/pandoc-latex-template

# Install Node.js, Gatsby CLI, and dependencies for Gatsby Theme Carbon
echo "Installing Node.js, Gatsby CLI, and dependencies for Gatsby Theme Carbon..."
sudo xbps-install -y nodejs npm
sudo npm install -g gatsby-cli

# Set up Gatsby with IBM Carbon Design starter
echo "Setting up Gatsby with IBM Carbon Design starter..."
mkdir -p ~/gatsby-sites
cd ~/gatsby-sites
gatsby new my-gatsby-site https://github.com/carbon-design-system/gatsby-theme-carbon

# Navigate to the site directory and install necessary packages
cd my-gatsby-site
npm install

# Build the Gatsby site to verify everything is working
gatsby build

# Install and set up Screen-Pipe
echo "Installing Screen-Pipe..."
git clone https://github.com/louis030195/screen-pipe.git ~/screen-pipe
cd ~/screen-pipe
./install.sh

# Install ChatBlade
echo "Installing ChatBlade..."
git clone https://github.com/npiv/chatblade.git ~/chatblade
cd ~/chatblade
pip install .

# Install ShellGPT
echo "Installing ShellGPT..."
git clone https://github.com/TheR1D/shell_gpt.git ~/shell_gpt
cd ~/shell_gpt
pip install .

# Set up aliases for ChatBlade and ShellGPT
echo 'alias cbl="python3 ~/chatblade/chatblade.py"' >> ~/.zshrc
echo 'alias sgpt="python3 ~/shell_gpt/shell_gpt.py"' >> ~/.zshrc

# Install XBPS helper (vbm)
echo "Installing vbm (XBPS helper)..."
git clone https://github.com/mutantmonkey/void-packages.git ~/void-packages
cd ~/void-packages
./xbps-src binary-bootstrap
./xbps-src pkg vbm
sudo xbps-install --repository=hostdir/binpkgs vbm

# Install ROCm for AMD GPU compute tasks
echo "Installing ROCm..."
sudo xbps-install -y rocm

# Keyd setup: Remap Caps Lock to Escape when pressed and Meta when held
echo "Setting up Keyd..."
sudo tee /etc/keyd/default.conf <<EOF
[ids]
*

[main]
capslock = overload(meta, esc)
EOF
sudo systemctl restart keyd

# Final message
echo "Installation complete! Reboot your system to apply all changes."
