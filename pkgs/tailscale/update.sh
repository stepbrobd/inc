# shellcheck shell=bash

owner="tailscale"
repo="tailscale"
branch="main"

root="$(git rev-parse --show-toplevel)"
file="${root}/pkgs/tailscale/default.nix"
system="$(nix eval --raw --impure --expr 'builtins.currentSystem')"

fake="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

latest="$(git ls-remote "https://github.com/${owner}/${repo}.git" "refs/heads/${branch}" | cut -f1)"
if [ -z "${latest}" ]; then
  echo "tailscale: could not resolve ${owner}/${repo}@${branch}" >&2
  exit 1
fi

current="$(sed -n 's/^[[:space:]]*rev = "\([0-9a-f]\{40\}\)";.*/\1/p' "${file}" | head -n1)"
if [ "${latest}" = "${current}" ]; then
  echo "tailscale: already at ${latest}"
  exit 0
fi

hash="$(nix-prefetch-github "${owner}" "${repo}" --rev "${latest}" | jq -r '.hash')"
if [ -z "${hash}" ] || [ "${hash}" = "null" ]; then
  echo "tailscale: nix-prefetch-github returned no hash" >&2
  exit 1
fi

work="$(mktemp -d)"
trap 'chmod -R +w "${work}" 2>/dev/null || true; rm -rf "${work}" 2>/dev/null || true' EXIT
git clone --quiet --filter=blob:none --no-checkout "https://github.com/${owner}/${repo}.git" "${work}/src"
base="$(git -C "${work}/src" rev-list --max-count=1 "${latest}" -- VERSION.txt)"
if [ -z "${base}" ]; then
  echo "tailscale: could not find a commit touching VERSION.txt under ${latest}" >&2
  exit 1
fi
IFS=. read -r major minor patch _ <<< "$(git -C "${work}/src" show "${base}:VERSION.txt")"
if [ -z "${major}" ] || [ -z "${minor}" ]; then
  echo "tailscale: could not parse VERSION.txt at ${base}" >&2
  exit 1
fi
if (( minor % 2 == 1 )); then
  patch="$(git -C "${work}/src" rev-list --count "${latest}" "^${base}")"
fi
version="${major}.${minor}.${patch:-0}"

sed -i \
  -e "s|^\([[:space:]]*\)version = \"[^\"]*\";|\1version = \"${version}\";|" \
  -e "s|^\([[:space:]]*\)rev = \"[^\"]*\";|\1rev = \"${latest}\";|" \
  -e "s|^\([[:space:]]*\)hash = \"[^\"]*\";|\1hash = \"${hash}\";|" \
  -e "s|^\([[:space:]]*\)vendorHash = \"[^\"]*\";|\1vendorHash = \"${fake}\";|" \
  "${file}"

if build_log="$(nix build --no-link "${root}#legacyPackages.${system}.tailscale.goModules" 2>&1)"; then
  echo "tailscale: goModules unexpectedly built with the sentinel vendorHash" >&2
  exit 1
fi
vendor="$(printf '%s\n' "${build_log}" | sed -n 's#.*got:[[:space:]]*\(sha256-[A-Za-z0-9+/=]*\).*#\1#p' | tail -n1)"
if [ -z "${vendor}" ]; then
  echo "tailscale: could not parse vendorHash from build output" >&2
  printf '%s\n' "${build_log}" >&2
  exit 1
fi
sed -i -e "s|^\([[:space:]]*\)vendorHash = \"[^\"]*\";|\1vendorHash = \"${vendor}\";|" "${file}"

echo "tailscale: ${current:-<none>} -> ${latest} (version ${version})"
