#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
description="${repo_root}/build/nexos-descr"
output_dir="${repo_root}/build/output/build"
profile="Xfce-Live"
allow_existing_root=false

usage() {
    cat <<'EOF'
Usage: sudo ./build/scripts/build-iso.sh [options]

Build the NexOS live ISO from the pinned vendor description plus the NexOS
overlay. The generated description is refreshed before every build.

Options:
  --output-dir PATH       Write ISO artifacts to PATH
                          (default: build/output/build)
  --profile NAME          KIWI profile to build (default: Xfce-Live)
  --allow-existing-root   Resume into an existing KIWI build root
  -h, --help              Show this help

Examples:
  sudo ./build/scripts/build-iso.sh
  sudo ./build/scripts/build-iso.sh --output-dir build/output/phase3
  sudo ./build/scripts/build-iso.sh --allow-existing-root
EOF
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output-dir)
            [[ $# -ge 2 ]] || die "--output-dir requires a path"
            output_dir="$2"
            shift 2
            ;;
        --profile)
            [[ $# -ge 2 ]] || die "--profile requires a name"
            profile="$2"
            shift 2
            ;;
        --allow-existing-root)
            allow_existing_root=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown argument: $1 (use --help)"
            ;;
    esac
done

[[ "${EUID}" -eq 0 ]] || die "run this script with sudo"
command -v kiwi-ng >/dev/null 2>&1 || die "kiwi-ng is not installed"
[[ -f "${repo_root}/build/vendor/fedora-kiwi-descriptions/Fedora.kiwi" ]] \
    || die "vendor description missing; run: make clone-vendor"
[[ -f "${repo_root}/build/overlay/Fedora.kiwi" ]] \
    || die "NexOS overlay description missing: ${repo_root}/build/overlay/Fedora.kiwi"
[[ -d "${repo_root}/build/overlay/components" ]] \
    || die "NexOS overlay components directory missing"

if [[ "${output_dir}" != /* ]]; then
    output_dir="${repo_root}/${output_dir}"
fi

mkdir -p "${output_dir}"

if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    runuser -u "${SUDO_USER}" -- "${repo_root}/build/scripts/prepare-description.sh"
else
    "${repo_root}/build/scripts/prepare-description.sh"
fi

kiwi_args=(
    --type=iso
    --profile="${profile}"
    --kiwi-file=Fedora.kiwi
    --color-output
    system
    build
)

if [[ "${allow_existing_root}" == true ]]; then
    kiwi_args+=(--allow-existing-root)
fi

kiwi_args+=(
    --description "${description}"
    --target-dir "${output_dir}"
)

echo "==> Building NexOS ISO (profile: ${profile})"
echo "==> Description: ${description}"
echo "==> Output: ${output_dir}"
kiwi-ng "${kiwi_args[@]}"

latest_iso=""
latest_mtime=0
for candidate in "${output_dir}"/*.iso; do
    [[ -f "${candidate}" ]] || continue
    mtime="$(stat -c %Y "${candidate}")"
    if (( mtime > latest_mtime )); then
        latest_iso="${candidate}"
        latest_mtime="${mtime}"
    fi
done

[[ -n "${latest_iso}" ]] || die "build finished but no ISO was found in ${output_dir}"

relative_iso="${latest_iso#"${repo_root}/"}"
(cd "${repo_root}" && sha256sum "${relative_iso}") > "${latest_iso}.sha256"

echo
echo "ISO: ${latest_iso}"
echo "SHA256: $(cut -d' ' -f1 "${latest_iso}.sha256")"
echo "Checksum: ${latest_iso}.sha256"
