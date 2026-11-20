#!/usr/bin/env bash
# shellcheck disable=SC2034
#
# Halcora live image profile.
#
# Mirrors archiso v92's configs/releng/profiledef.sh with only the naming and
# the file permissions changed. Keep it that way: every line that diverges from
# upstream is a line we maintain against future archiso releases.

iso_name="halcora"
iso_label="HALCORA_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Halcora Project <https://github.com/Ron-warrior/halcora>"
iso_application="Halcora Live Desktop"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="halcora"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86,arm64' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
kernel_params_aarch64="clk_ignore_unused pd_ignore_unused arm64.nopauth"

# Windows refugees arrive with UEFI machines almost universally, but the BIOS
# path costs nothing and rescues older hardware during testing.
bootmodes=('bios.syslinux'
           'uefi.systemd-boot')

# mkarchiso flattens airootfs permissions to 644/755 owned by root, so anything
# needing a different owner or mode has to be listed here.
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
  ["/usr/local/bin/halcora-installer"]="0:0:755"
  ["/usr/local/bin/halcora-install"]="0:0:755"
  ["/home/live"]="1000:1000:750"
)
