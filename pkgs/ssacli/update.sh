# shellcheck shell=bash

root="$(git rev-parse --show-toplevel)"
file="${root}/pkgs/ssacli/default.nix"
pool="https://downloads.linux.hpe.com/SDR/repo/mcp/debian/pool/non-free"

read_attr() {
  sed -n "s|^[[:space:]]*$1 = \"\([^\"]*\)\";.*|\1|p" "${file}" | head -n1
}

current="$(read_attr version)"
if [ -z "${current}" ]; then
  echo "ssacli: could not read version from ${file}" >&2
  exit 1
fi

# the pool index lists every release as ssacli-<version>_amd64.deb
listing="$(curl -fsSL "${pool}/")"
latest="$(grep -oE 'ssacli-[0-9]+\.[0-9]+-[0-9]+\.[0-9]+_amd64\.deb' <<<"${listing}" | sed -E 's/^ssacli-(.*)_amd64\.deb$/\1/' | sort -uV | tail -n1 || true)"
if [ -z "${latest}" ]; then
  echo "ssacli: no release found in ${pool}" >&2
  exit 1
fi

if [ "${latest}" = "${current}" ]; then
  echo "ssacli: already at ${current}"
  exit 0
fi

if [ "$(printf '%s\n%s\n' "${current}" "${latest}" | sort -V | tail -n1)" != "${latest}" ]; then
  echo "ssacli: newest in the pool ${latest} is older than ${current}" >&2
  exit 1
fi

url="${pool}/ssacli-${latest}_amd64.deb"
hash="$(nix store prefetch-file --json "${url}" | jq -r '.hash')"
if [ -z "${hash}" ] || [ "${hash}" = "null" ]; then
  echo "ssacli: could not prefetch ${url}" >&2
  exit 1
fi

sed -i \
  -e "s|^\([[:space:]]*\)version = \"${current//./\\.}\";|\1version = \"${latest}\";|" \
  -e "s|^\([[:space:]]*\)hash = \"[^\"]*\";|\1hash = \"${hash}\";|" \
  "${file}"

if [ "$(read_attr version)" != "${latest}" ]; then
  echo "ssacli: failed to write version ${latest} to ${file}" >&2
  exit 1
fi

echo "ssacli: ${current} -> ${latest}"
