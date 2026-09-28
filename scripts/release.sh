#!/usr/bin/env bash
# Bumps the version in package/metadata.json, commits, creates an annotated tag and pushes both.
# Pushing the tag triggers .github/workflows/release.yml, which builds and publishes the release.
# Usage: scripts/release.sh X.Y.Z[-suffix]   e.g. scripts/release.sh 0.2.0 or scripts/release.sh 1.0.0-rc.1
set -euo pipefail

cd "$(dirname "$0")/.."
metadata=package/metadata.json

fail() { echo "Error: $*" >&2; exit 1; }

version=${1:-}
version=${version#v}
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$ ]] || fail "usage: $0 X.Y.Z[-suffix]"
tag="v$version"

[[ "$(git branch --show-current)" == "main" ]] || fail "releases are made from main"
[[ -z "$(git status --porcelain)" ]] || fail "working tree has uncommitted changes"

git fetch --quiet --tags origin main
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] || fail "main is not in sync with origin/main"
! git rev-parse -q --verify "refs/tags/$tag" >/dev/null || fail "tag $tag already exists"

current=$(sed -n 's/.*"Version": *"\([^"]*\)".*/\1/p' "$metadata")
[[ "$current" != "$version" ]] || fail "version is already $version"

sed -i -E "s/(\"Version\": *\")[^\"]*(\")/\1$version\2/" "$metadata"
git commit -m "Release $tag" -- "$metadata"
git tag -a "$tag" -m "Release $tag"
git push origin main "$tag"

echo "Released $current -> $version; the GitHub workflow will publish $tag."
