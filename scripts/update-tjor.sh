#!/usr/bin/env bash
# Bring Formula/tjor.rb to tjor's latest release (bjorges/tjor), or to the tag
# in $TJOR_TAG. Rewrites the formula's url and sha256 in the working tree and
# nothing else: committing, testing and pushing are the workflow's steps, so a
# failed verification never reaches the tap. Run by .github/workflows/
# update-tjor.yml hourly and on demand; runnable by hand from a checkout.
#
# Rules, all fail-closed:
#   - the tag must be vX.Y.Z and the release must exist in bjorges/tjor;
#   - never a downgrade (the formula already names a newer version: error);
#   - the tarball is the tagged tree (its VERSION file equals the tag);
#   - a version this tap committed before with a different checksum is an
#     error, never a silent rewrite (GitHub archives are not promised stable);
#   - an API or download failure is an error, never "nothing to do".
# Exit 0 and "up to date" when the formula already names the release.
# Writes changed=/tag=/version= to $GITHUB_OUTPUT when that is set. With
# CHECK_ONLY=1 it stops after the comparison (one API call, no download, no
# rewrite): the workflow's cheap first step, so a run with nothing to do
# never sets up Homebrew.
set -euo pipefail

REPO="bjorges/tjor"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORMULA="${ROOT}/Formula/tjor.rb"
URL_PREFIX="https://github.com/${REPO}/archive/refs/tags/"

say() { echo "update-tjor: $*" >&2; }
die() { say "$*"; echo "::error::update-tjor: $*"; exit 1; }
out() { [[ -n "${GITHUB_OUTPUT:-}" ]] && printf '%s\n' "$1" >> "${GITHUB_OUTPUT}"; return 0; }

command -v gh >/dev/null || die "gh (GitHub CLI) is required"
[[ -f "${FORMULA}" ]] || die "no formula at ${FORMULA}"

# 1. The release.
if [[ -n "${TJOR_TAG:-}" ]]; then
    tag="${TJOR_TAG}"
    gh api "repos/${REPO}/releases/tags/${tag}" --jq .tag_name >/dev/null || die "no release ${tag} in ${REPO}"
else
    tag="$(gh api "repos/${REPO}/releases/latest" --jq .tag_name)" || die "cannot read the latest release of ${REPO}"
fi
[[ "${tag}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "tag ${tag} is not vX.Y.Z"
version="${tag#v}"

# 2. What the formula names today.
current="$(sed -n "s#^  url \"${URL_PREFIX}v\([0-9][0-9.]*\)\.tar\.gz\"\$#\1#p" "${FORMULA}")"
[[ -n "${current}" ]] || die "cannot read the current version from ${FORMULA}'s url line"
if [[ "${current}" == "${version}" ]]; then
    say "up to date: ${current}"
    out "changed=false"; out "tag=${tag}"; out "version=${version}"
    exit 0
fi
newest="$(printf '%s\n%s\n' "${current}" "${version}" | sort -V | tail -1)"
[[ "${newest}" == "${version}" ]] || die "refusing to downgrade: the formula names ${current}, the release is ${version}"
if [[ -n "${CHECK_ONLY:-}" ]]; then
    say "behind: ${current} -> ${version} (check only, nothing rewritten)"
    out "changed=true"; out "tag=${tag}"; out "version=${version}"
    exit 0
fi

# 3. The tarball: downloaded here, hashed here, checked to be the tagged tree.
tmp="$(mktemp -d)"; trap 'rm -rf "${tmp}"' EXIT
url="${URL_PREFIX}${tag}.tar.gz"
curl -fsSL --retry 3 --retry-all-errors -o "${tmp}/tjor.tar.gz" "${url}" || die "cannot download ${url}"
sha="$(sha256sum "${tmp}/tjor.tar.gz" | cut -d' ' -f1)"
[[ "${sha}" =~ ^[0-9a-f]{64}$ ]] || die "no checksum for ${url}"
in_tarball="$(tar xzf "${tmp}/tjor.tar.gz" -O "tjor-${version}/VERSION" 2>/dev/null | tr -d ' \n')" \
    || die "the archive for ${tag} does not hold tjor-${version}/VERSION"
[[ "${in_tarball}" == "${version}" ]] || die "the archive for ${tag} says VERSION ${in_tarball}"

# 4. Never rewrite a version this tap already committed with another checksum.
while read -r commit; do
    # (a commit without this url is simply not a prior pin: grep's 1 is not an error here)
    prior="$(git -C "${ROOT}" show "${commit}:Formula/tjor.rb" 2>/dev/null | { grep -F -A1 "url \"${url}\"" || true; } | sed -n 's/^  sha256 "\([0-9a-f]*\)"$/\1/p')"
    if [[ -n "${prior}" && "${prior}" != "${sha}" ]]; then
        die "${tag} was committed before (${commit:0:7}) with sha256 ${prior}; now ${sha} — not rewriting, look at the release"
    fi
done < <(git -C "${ROOT}" log --format=%H -- Formula/tjor.rb)

# 5. Rewrite the two lines, and prove they were rewritten.
sed -i.bak -e "s#^  url \"${URL_PREFIX}v${current}\.tar\.gz\"\$#  url \"${url}\"#" \
           -e "s#^  sha256 \"[0-9a-f]*\"\$#  sha256 \"${sha}\"#" "${FORMULA}" && rm -f "${FORMULA}.bak"
grep -qF "  url \"${url}\"" "${FORMULA}" || die "the url line was not rewritten"
grep -qF "  sha256 \"${sha}\"" "${FORMULA}" || die "the sha256 line was not rewritten"
say "formula: ${current} -> ${version} (sha256 ${sha})"
out "changed=true"; out "tag=${tag}"; out "version=${version}"
