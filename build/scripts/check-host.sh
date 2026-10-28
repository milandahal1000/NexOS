#!/usr/bin/env bash
set -euo pipefail

echo "================================"
echo "       NexOS Host Check"
echo "================================"

if [[ -f /etc/fedora-release ]]; then
    cat /etc/fedora-release
else
    echo "ERROR: This build workflow expects a Fedora host."
    exit 1
fi

printf 'Architecture: '
uname -m

if [[ "$(uname -m)" != "x86_64" ]]; then
    echo "ERROR: The initial NexOS build targets x86_64."
    exit 1
fi

missing=0

for cmd in git dnf; do
    if command -v "$cmd" >/dev/null 2>&1; then
        printf 'OK: %s\n' "$cmd"
    else
        printf 'MISSING: %s\n' "$cmd"
        missing=1
    fi
done

# Kickstart tooling is optional (not used by the KIWI build path)
if command -v ksvalidator >/dev/null 2>&1; then
    echo "OK: ksvalidator (optional)"
else
    echo "INFO: ksvalidator not found (optional for KIWI builds)."
fi

if command -v livemedia-creator >/dev/null 2>&1; then
    echo "OK: livemedia-creator (optional)"
else
    echo "INFO: livemedia-creator not found (optional for KIWI builds)."
fi

if command -v kiwi-ng >/dev/null 2>&1; then
    echo "OK: kiwi-ng"
    kiwi-ng --version 2>/dev/null | awk 'NR==1{print}' || true
else
    echo "MISSING: kiwi-ng (required for KIWI ISO builds)"
    missing=1
fi

if rpm -q dracut-kiwi-live >/dev/null 2>&1; then
    echo "OK: dracut-kiwi-live"
else
    echo "INFO: dracut-kiwi-live not found (check install)"
    missing=1
fi

for cmd in checkmodule semodule_package semodule; do
    if command -v "$cmd" >/dev/null 2>&1; then
        printf 'OK: %s\n' "$cmd"
    else
        printf 'MISSING: %s (install checkpolicy; needed for the KIWI SELinux fix)\n' "$cmd"
        missing=1
    fi
done

if [[ "${EUID}" -eq 0 ]]; then
    semodule -l >/dev/null 2>&1 && check_semodule=0 || check_semodule=1
else
    sudo -n semodule -l >/dev/null 2>&1 && check_semodule=0 || check_semodule=2
fi

if [[ "${check_semodule}" -eq 0 ]]; then
    if semodule -l 2>/dev/null | awk '{print $1}' | grep -qx nexos-kiwi-fix; then
        echo "OK: SELinux kiwi scriptlet policy fix"
    else
        echo "MISSING: SELinux kiwi scriptlet policy fix (run: sudo ./build/scripts/setup-selinux.sh)"
        missing=1
    fi
elif [[ "${check_semodule}" -eq 2 ]]; then
    echo "INFO: cannot verify SELinux policy module without sudo"
fi

if [[ "$missing" -ne 0 ]]; then
    echo "ERROR: Install the missing required tools."
    exit 1
fi

echo
echo "Basic host checks passed."
echo "This does not yet verify all ISO build dependencies."
