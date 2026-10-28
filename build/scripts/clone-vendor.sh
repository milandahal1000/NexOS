#!/usr/bin/env bash
set -euo pipefail

# NexOS: clone/pin vendor Fedora upstream repos to known commits
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VENDOR="$ROOT/build/vendor"
mkdir -p "$VENDOR"

clone_or_checkout() {
    local url="$1"
    local dir="$2"
    local ref="$3"
    if [ -d "$dir/.git" ]; then
        echo "==> $dir already exists; verifying..."
        git -C "$dir" remote -v | head -1
        git -C "$dir" rev-parse --verify "$ref" >/dev/null 2>&1 || {
            echo "ERROR: pinned commit $ref not present in $dir; fetch and checkout it." >&2
            return 1
        }
        git -C "$dir" -c advice.detachedHead=false checkout "$ref" 2>&1 | tail -1
        echo "    $(git -C "$dir" rev-parse --short HEAD)"
    else
        echo "==> Cloning $url -> $dir at $ref"
        git clone --filter=blob:none "$url" "$dir"
        git -C "$dir" -c advice.detachedHead=false checkout "$ref"
        echo "    $(git -C "$dir" rev-parse --short HEAD)"
    fi
}

clone_or_checkout "https://forge.fedoraproject.org/releng/kiwi-descriptions.git" \
    "$VENDOR/fedora-kiwi-descriptions" "dfc49a5a10f69941179fdadd96aa6a5984f7c677"

clone_or_checkout "https://src.fedoraproject.org/rpms/fedora-kickstarts.git" \
    "$VENDOR/fedora-kickstarts" "f3ffde6a446f7ff89d8ca3fb2417d9e4115ddd1f"

echo "==> Vendor repos pinned."
