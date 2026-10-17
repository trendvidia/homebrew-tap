#!/bin/bash
# update-go.sh <tag>: point Formula/go.rb at a go-plus release.
#
# The release's archives are named after the toolchain's VERSION file
# (go1.27.2-plus.<os>-<arch>.tar.gz), not after the tag (v1.27.2a), so
# both come from the release itself. The formula's version is the tag
# without its "v": the test asserts `go version` says "(plus v<version>)".
set -euo pipefail
tag=${1:?usage: update-go.sh <tag, e.g. v1.27.2a>}
f=Formula/go.rb
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
gh release download "$tag" -R trendvidia/go -D "$dir" \
	-p '*-plus.darwin-arm64.tar.gz' -p '*-plus.linux-arm64.tar.gz' -p '*-plus.linux-amd64.tar.gz'
sed -i.bak -E "s|^  version \".*\"|  version \"${tag#v}\"|" "$f"
for plat in darwin-arm64 linux-arm64 linux-amd64; do
	a=$(cd "$dir" && ls *-plus.$plat.tar.gz)
	sum=$(shasum -a 256 "$dir/$a" | cut -d' ' -f1)
	# Rewrite the url and the sha256 on the line after it for this platform.
	sed -i.bak -E "/-plus\.$plat\.tar\.gz/{
		s|download/[^/]+/[^\"]+|download/$tag/$a|
		n
		s|sha256 \"[0-9a-f]+\"|sha256 \"$sum\"|
	}" "$f"
	echo "$plat: $a $sum"
done
rm -f "$f.bak"
grep -nE 'version|url|sha256' "$f"
