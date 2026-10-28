#!/bin/bash
set -euxo pipefail

if [ -f /boot/grub2/grubenv ]; then
    grub2-editenv /boot/grub2/grubenv unset blsdir || true
fi
