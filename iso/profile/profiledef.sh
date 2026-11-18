#!/usr/bin/env bash
# Tessera live image profile.
#
# Derived from archiso configs/releng/profiledef.sh (v92). Keep the diff against
# upstream as small as possible: every line here is a line we maintain.
#
# Build:  mkarchiso -v -w work -o out .
# Test:   run_archiso -i out/tessera-*.iso

iso_name="tessera"
iso_label="TESSERA_$(date +%Y%m)"
iso_publisher="Tessera Project"
iso_application="Tessera Live Desktop"
iso_version="$(date +%Y.%m.%d)"
install_dir="tessera"
buildmodes=('iso')
arch="x86_64"
pacman_conf="pacman.conf"

# Windows refugees arrive with UEFI machines almost universally, but BIOS
# bootmodes cost nothing and rescue old hardware during testing.
bootmodes=('bios.syslinux' 'uefi.systemd-boot')

airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')

# mkarchiso flattens airootfs permissions to 644/755 owned by root, so anything
# needing a different mode has to be listed here.
file_permissions=(
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/usr/local/bin/tessera-layout"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
)
