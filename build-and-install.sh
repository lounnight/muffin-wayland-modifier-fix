#!/usr/bin/env bash
# Build a Fedora muffin package with the upstream Wayland modifier-key fix
# and install it. See README.md for details.
set -euo pipefail

# Fedora source package to start from (must exist on kojipkgs).
VERSION=6.6.3
FEDORA_REL=1.fc44
# Local build release (must sort higher than FEDORA_REL so dnf upgrades/-2 > -1).
BUILD_REL=2.fc44

SRPM_URL="https://kojipkgs.fedoraproject.org/packages/muffin/${VERSION}/${FEDORA_REL}/src/muffin-${VERSION}-${FEDORA_REL}.src.rpm"

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

if [[ ! -f "$HERE/fix-modifiers.patch" ]]; then
  echo "error: fix-modifiers.patch not found next to this script" >&2
  exit 1
fi

TOP=${HOME}/rpmbuild
mkdir -p "$TOP"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

echo "==> Downloading muffin ${VERSION}-${FEDORA_REL} source"
curl -fsSL -o "$WORK/muffin.src.rpm" "$SRPM_URL"
(
  cd "$WORK"
  rpm2cpio muffin.src.rpm | cpio -idm --quiet
)

install -m 0644 "$WORK/muffin-${VERSION}.tar.gz" "$TOP/SOURCES/"
install -m 0644 "$HERE/fix-modifiers.patch" "$TOP/SOURCES/"

# Bump the release and register the patch. %autosetup -p1 in the spec applies it.
sed -e "s/^Release:.*/Release:       ${BUILD_REL}/" \
    -e '/^Source0:/a Patch0:         fix-modifiers.patch' \
    "$WORK/muffin.spec" > "$TOP/SPECS/muffin.spec"

echo "==> Installing build dependencies (sudo)"
sudo dnf builddep -y "$TOP/SPECS/muffin.spec"

echo "==> Building patched muffin"
rpmbuild -ba "$TOP/SPECS/muffin.spec"

ARCH=$(rpm --eval '%{_arch}')
RPM="$TOP/RPMS/${ARCH}/muffin-${VERSION}-${BUILD_REL}.${ARCH}.rpm"
if [[ ! -f "$RPM" ]]; then
  echo "error: expected RPM not found: $RPM" >&2
  exit 1
fi

echo "==> Installing $RPM (sudo)"
sudo dnf install -y "$RPM"

echo
echo "Done. muffin $(rpm -q --qf '%{VERSION}-%{RELEASE}' muffin) is installed."
echo "Log out and back in to the 'Cinnamon on Wayland' session for the fix to apply."
