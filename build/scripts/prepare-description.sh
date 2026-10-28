#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
vendor="${repo_root}/build/vendor/fedora-kiwi-descriptions"
overlay="${repo_root}/build/overlay"
target="${repo_root}/build/nexos-descr"

if [[ ! -f "${vendor}/Fedora.kiwi" ]]; then
    echo "ERROR: vendor description missing; run: make clone-vendor" >&2
    exit 1
fi

if [[ ! -f "${overlay}/Fedora.kiwi" ]]; then
    echo "ERROR: overlay description missing: ${overlay}/Fedora.kiwi" >&2
    exit 1
fi

if [[ ! -f "${overlay}/images.sh" ]]; then
    echo "ERROR: overlay images.sh missing: ${overlay}/images.sh" >&2
    exit 1
fi

rm -rf "${target}"
mkdir -p "${target}"
tar -C "${vendor}" --exclude='./.git' -cf - . | tar -C "${target}" -xf -
cp -a "${overlay}/." "${target}/"

echo "OK: prepared ${target}"
