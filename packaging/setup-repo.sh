#!/usr/bin/env bash
# ==============================================================================
# AMD BC-250 Titanium Studio Cockpit Pro - Pacman Repository Builder
# Designed for CachyOS Linux (x86_64)
# Target Repository: https://github.com/Snk-B/bc250-packages
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${SCRIPT_DIR}/repo"
ARCH="x86_64"
TARGET_DIR="${REPO_DIR}/${ARCH}"

echo "======================================================================"
echo "  [*] AMD BC-250 Cockpit Pro - Pacman Repository Builder"
echo "  [*] Target: bc250-packages (${ARCH})"
echo "======================================================================"

mkdir -p "${TARGET_DIR}"

cd "${SCRIPT_DIR}"
echo ":: Building package with makepkg..."
makepkg -sf --noconfirm

echo ":: Moving built package to ${TARGET_DIR}..."
mv bc250-cockpit-pro-*.pkg.tar.zst "${TARGET_DIR}/"

cd "${TARGET_DIR}"
PKG_FILE=$(ls -t bc250-cockpit-pro-*.pkg.tar.zst | head -n 1)

echo ":: Generating pacman repository database (bc250-cockpit.db.tar.gz)..."
repo-add -s -n -R "bc250-cockpit.db.tar.gz" "${PKG_FILE}" || repo-add "bc250-cockpit.db.tar.gz" "${PKG_FILE}"

# Symlinks for pacman standard discovery
ln -sf bc250-cockpit.db.tar.gz bc250-cockpit.db
ln -sf bc250-cockpit.files.tar.gz bc250-cockpit.files

echo ""
echo "======================================================================"
echo "  [OK] Pacman repository built successfully!"
echo "  [DIR] Repository path: ${TARGET_DIR}"
echo "  [PKG] Package file:    ${PKG_FILE}"
echo "======================================================================"
echo ""
echo "Next step: Push the 'repo' directory to Snk-B/bc250-packages!"
