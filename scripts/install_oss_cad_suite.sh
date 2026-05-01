#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/install_oss_cad_suite.sh [--force]

Environment:
  OSS_CAD_SUITE_DIR  Install path. Default: $HOME/opt/oss-cad-suite

Installs the latest OSS CAD Suite release for the current Linux architecture.
This provides yosys, verilator, nextpnr, gowin_pack, openFPGALoader, and more.
EOF
}

force=0
if [ "${1:-}" = "--help" ]; then
  usage
  exit 0
elif [ "${1:-}" = "--force" ]; then
  force=1
elif [ "${1:-}" != "" ]; then
  usage
  exit 2
fi

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)
    asset_pattern="linux-x64"
    ;;
  Linux-aarch64|Linux-arm64)
    asset_pattern="linux-arm64"
    ;;
  *)
    echo "Unsupported platform: $(uname -s)-$(uname -m)"
    echo "Download manually from https://github.com/YosysHQ/oss-cad-suite-build/releases"
    exit 1
    ;;
esac

install_dir="${OSS_CAD_SUITE_DIR:-$HOME/opt/oss-cad-suite}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_dir="$repo_root/.env"
archive="${TMPDIR:-/tmp}/oss-cad-suite-${asset_pattern}.tgz"
extract_dir="${TMPDIR:-/tmp}/oss-cad-suite-extract-$$"

need_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing host tool: $1"
    echo "On Ubuntu, run: scripts/install_ubuntu_deps.sh"
    exit 1
  fi
}

need_tool curl
need_tool python3
need_tool tar

if [ -e "$install_dir" ] && [ "$force" -ne 1 ]; then
  echo "Install path already exists: $install_dir"
  echo "Re-run with --force to replace it."
  exit 1
fi

url="$(
  ASSET_PATTERN="$asset_pattern" python3 - <<'PY'
import json
import os
import sys
import urllib.request

api = "https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/latest"
pattern = os.environ["ASSET_PATTERN"]
with urllib.request.urlopen(api, timeout=30) as response:
    data = json.load(response)
for asset in data.get("assets", []):
    name = asset.get("name", "")
    if pattern in name and name.endswith((".tgz", ".tar.gz")):
        print(asset["browser_download_url"])
        break
else:
    print(f"No OSS CAD Suite asset matched {pattern}", file=sys.stderr)
    sys.exit(1)
PY
)"

echo "Downloading: $url"
curl -L --fail --show-error "$url" -o "$archive"

rm -rf "$extract_dir"
mkdir -p "$extract_dir" "$(dirname "$install_dir")"

if [ -e "$install_dir" ]; then
  rm -rf "$install_dir"
fi

tar -xzf "$archive" -C "$extract_dir"
mv "$extract_dir/oss-cad-suite" "$install_dir"
rm -rf "$extract_dir"

mkdir -p "$env_dir"
cat > "$env_dir/oss-cad-suite.env" <<EOF
export OSS_CAD_SUITE="$install_dir"
export PATH="$install_dir/bin:\$PATH"
EOF

echo
echo "Installed OSS CAD Suite to: $install_dir"
echo "For this shell, run:"
echo "  source .env/oss-cad-suite.env"
echo
echo "Then verify:"
echo "  scripts/check_tools.sh"

