#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_REPO="https://github.com/ericnordelo/strk-merkle-tree.git"
VENDOR_DIR="${ROOT_DIR}/vendor/strk-merkle-tree"
TMP_DIR="$(mktemp -d)"
REF="${1:-}"

cleanup() {
  rm -rf "${TMP_DIR}"
}

trap cleanup EXIT

latest_tag() {
  git ls-remote --tags --refs "${UPSTREAM_REPO}" \
    | awk -F/ '{print $3}' \
    | sort -V \
    | tail -n 1
}

resolve_ref() {
  if [[ -n "${REF}" ]]; then
    printf '%s\n' "${REF}"
    return
  fi

  latest_tag
}

copy_vendor_files() {
  local source_dir="$1"

  rm -rf "${VENDOR_DIR}"
  mkdir -p "${VENDOR_DIR}"

  cp -R "${source_dir}/dist" "${VENDOR_DIR}/dist"
  cp -R "${source_dir}/src" "${VENDOR_DIR}/src"
  cp "${source_dir}/LICENSE" "${VENDOR_DIR}/LICENSE"
  cp "${source_dir}/README.md" "${VENDOR_DIR}/README.md"
  cp "${source_dir}/package.json" "${VENDOR_DIR}/package.json"
}

write_metadata() {
  local resolved_ref="$1"
  local commit_sha="$2"

  cat > "${VENDOR_DIR}/VENDORED_FROM.json" <<EOF
{
  "repo": "${UPSTREAM_REPO}",
  "ref": "${resolved_ref}",
  "commit": "${commit_sha}",
  "updatedAtUtc": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
}

main() {
  local resolved_ref
  local commit_sha
  resolved_ref="$(resolve_ref)"

  git clone --depth 1 --branch "${resolved_ref}" "${UPSTREAM_REPO}" "${TMP_DIR}/upstream"
  (
    cd "${TMP_DIR}/upstream"
    npm ci
    npm run compile
    packed_tarball="$(npm pack --quiet | tail -n 1)"
    mkdir -p "${TMP_DIR}/package"
    tar -xzf "${packed_tarball}" -C "${TMP_DIR}/package"
  )

  copy_vendor_files "${TMP_DIR}/package/package"
  commit_sha="$(git -C "${TMP_DIR}/upstream" rev-parse HEAD)"
  write_metadata "${resolved_ref}" "${commit_sha}"

  printf 'Vendored strk-merkle-tree from %s at %s\n' "${resolved_ref}" "${commit_sha}"
}

main "$@"
