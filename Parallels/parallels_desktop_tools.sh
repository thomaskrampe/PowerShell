#!/usr/bin/env bash
# Patch Parallels Desktop Tool installation on CentOS or Alma Linux

if [[ ! -d "/run/media/$(whoami)/Parallels Tools" ]]; then
    echo "Please mount parallels tools disk before install"
    exit
fi
echo "Copy install files to /tmp/parallels_fixed"
cp -rf "/run/media/$(whoami)/Parallels Tools" /tmp/parallels_fixed
chmod -R 755 /tmp/parallels_fixed
cd /tmp/parallels_fixed/kmods
echo "Unpack prl_mod.tar.gz"
tar -xzf prl_mod.tar.gz
rm prl_mod.tar.gz
echo "Patch prl_fs/SharedFolders/Guest/Linux/prl_fs/super.c"
sed '1i\#include <uapi/linux/mount.h>' -i prl_fs/SharedFolders/Guest/Linux/prl_fs/super.c
echo "Repack prl_mod.tar.gz"
tar -zcvf prl_mod.tar.gz . dkms.conf Makefile.kmods > /dev/null
cd /tmp/parallels_fixed
echo "Start install"
sudo ./install
echo "Remove /tmp/parallels_fixed"
rm -rf /tmp/parallels_fixed
