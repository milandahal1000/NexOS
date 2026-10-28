#!/usr/bin/env bash
set -euo pipefail

module="nexos-kiwi-fix"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
te_file="${script_dir}/../selinux/${module}.te"

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: run as root: sudo $0" >&2
    exit 1
fi

if [[ ! -f "${te_file}" ]]; then
    echo "ERROR: policy source not found: ${te_file}" >&2
    exit 1
fi

if semodule -l | awk '{print $1}' | grep -qx "${module}"; then
    echo "OK: SELinux module ${module} already installed"
    exit 0
fi

for cmd in checkmodule semodule_package semodule; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        echo "MISSING: ${cmd} (install the checkpolicy package)" >&2
        exit 1
    fi
done

work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

checkmodule -M -m -o "${work_dir}/${module}.mod" "${te_file}"
semodule_package -o "${work_dir}/${module}.pp" -m "${work_dir}/${module}.mod"
semodule -i "${work_dir}/${module}.pp"

echo "OK: installed SELinux module ${module}"
