# shellcheck shell=bash

owner="ppy"
repo="osu"
channel="tachyon"
asset="osu.AppImage"

root="$(git rev-parse --show-toplevel)"
file="${root}/pkgs/osu-lazer-bin/default.nix"

read_attr() {
  sed -n "s|^[[:space:]]*$1 = \"\([^\"]*\)\";.*|\1|p" "${file}" | head -n1
}

write_attr() {
  sed -i "s|^\([[:space:]]*\)$1 = \"[^\"]*\";|\1$1 = \"$2\";|" "${file}"
}

newest() {
  sort -V | tail -n1
}

# tachyon tag can exist without a release
# pick the newest release that carries appimage
latest="$(
  gh api "repos/${owner}/${repo}/releases?per_page=100" \
    | jq -r --arg asset "${asset}" '
        .[]
        | select(.draft == false)
        | select([.assets[].name] | index($asset) != null)
        | .tag_name
      ' \
    | sed -n "s|^\(.*\)-${channel}\$|\1|p" \
    | newest
)"
if [ -z "${latest}" ]; then
  echo "osu-lazer-bin: could not resolve a ${channel} release of ${owner}/${repo}" >&2
  exit 1
fi

current="$(read_attr version)"
if [ "${current}" = "${latest}" ]; then
  echo "osu-lazer-bin: already at ${latest}-${channel}"
  exit 0
fi

if [ "$(printf '%s\n%s\n' "${current}" "${latest}" | newest)" != "${latest}" ]; then
  echo "osu-lazer-bin: ${latest}-${channel} is older than the pinned ${current}-${channel}" >&2
  exit 1
fi

hash="$(
  nix store prefetch-file --json --hash-type sha256 \
    "https://github.com/${owner}/${repo}/releases/download/${latest}-${channel}/${asset}" \
    | jq -r '.hash'
)"
if [ -z "${hash}" ] || [ "${hash}" = "null" ]; then
  echo "osu-lazer-bin: could not prefetch ${asset} at ${latest}-${channel}" >&2
  exit 1
fi

write_attr version "${latest}"
write_attr hash "${hash}"

echo "osu-lazer-bin: ${current}-${channel} -> ${latest}-${channel}"
