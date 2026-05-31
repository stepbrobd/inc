{ lib
, writeShellApplication
, coreutils
, dockutil
, findutils
, jq
, rsync
}:

# reimplementation of github:hraban/mac-app-util as a shell script
writeShellApplication {
  name = "mac-app-util";
  meta.mainProgram = "mac-app-util";
  meta.platforms = lib.platforms.darwin;

  runtimeInputs = [
    jq
    rsync
    dockutil
    coreutils
    findutils
  ];

  text = ''
    if [ -n "''${DEBUGSH:-}" ]; then set -x; fi

    plutil=/usr/bin/plutil
    osacompile=/usr/bin/osacompile

    # Whitelist of Info.plist keys copied from the real app onto its
    # trampoline. "Based on a hunch, nothing scientific." -- upstream.
    copyable_app_props='[
      "CFBundleDevelopmentRegion",
      "CFBundleDocumentTypes",
      "CFBundleGetInfoString",
      "CFBundleIconFile",
      "CFBundleIdentifier",
      "CFBundleInfoDictionaryVersion",
      "CFBundleName",
      "CFBundleShortVersionString",
      "CFBundleURLTypes",
      "NSAppleEventsUsageDescription",
      "NSAppleScriptEnabled",
      "NSDesktopFolderUsageDescription",
      "NSDocumentsFolderUsageDescription",
      "NSDownloadsFolderUsageDescription",
      "NSPrincipalClass",
      "NSRemovableVolumesUsageDescription",
      "NSServices",
      "UTExportedTypeDeclarations"
    ]'

    usage() {
      cat <<'EOF'
    Usage:

        mac-app-util mktrampoline FROM.app TO.app
        mac-app-util sync-dock Foo.app Bar.app ...
        mac-app-util sync-trampolines /my/nix/Applications /Applications/MyTrampolines/

    mktrampoline creates a "trampoline" application launcher that immediately
    launches another application.

    sync-dock updates persistent items in your dock if any of the given apps
    has the same name.

    sync-trampolines syncs an entire directory of *.app files to another by
    creating a trampoline launcher for every app, deleting the rest, and
    updating the dock.
    EOF
    }

    # Is $1 a .app bundle?
    app_p() {
      [ -f "$1/Contents/Info.plist" ]
    }

    # Make $1 into an absolute directory path (no trailing slash, symlinks
    # left unresolved).
    to_abs_dir() {
      case "$1" in
        /*) printf '%s' "''${1%/}" ;;
        *)  printf '%s/%s' "$PWD" "''${1%/}" ;;
      esac
    }

    # Merge the whitelisted Info.plist keys of real app $1 onto trampoline $2.
    copy_paths() {
      local tmp rc=0
      tmp="$(mktemp -d)"
      # Subshell so a mid-way failure still hits the cleanup below, without a
      # RETURN trap (which would re-fire on every later function return).
      (
        cp "$1/Contents/Info.plist" "$tmp/orig"
        cp "$2/Contents/Info.plist" "$tmp/bare-wrapper"
        # Store-sourced plists are read-only; plutil rewrites them in place.
        chmod u+w "$tmp/orig" "$tmp/bare-wrapper"
        "$plutil" -convert json -- "$tmp/orig"
        "$plutil" -convert json -- "$tmp/bare-wrapper"
        jq --argjson keys "$copyable_app_props" \
          'to_entries | [.[] | select(.key as $item | $keys | index($item) >= 0)] | from_entries' \
          < "$tmp/orig" > "$tmp/filtered"
        cat "$tmp/bare-wrapper" "$tmp/filtered" | jq -s add > "$tmp/final"
        "$plutil" -convert xml1 -- "$tmp/final"
        cp "$tmp/final" "$2/Contents/Info.plist"
      ) || rc=$?
      rm -rf "$tmp"
      return "$rc"
    }

    # Drop every icon from trampoline $2, then copy real app $1's icons in.
    sync_icons() {
      local from_cnts="$1/Contents/Resources/"
      local to_cnts="$2/Contents/Resources/"
      if [ -d "$from_cnts" ]; then
        if [ -d "$to_cnts" ]; then
          find "$to_cnts" -name '*.icns' -delete
        fi
        # --links: some icon files are symlinks.
        rsync --include '*.icns' --exclude '*' --recursive --links "$from_cnts" "$to_cnts"
      fi
    }

    mktrampoline_app() {
      local app="$1" trampoline="$2"
      "$osacompile" -o "$trampoline" -e "do shell script \"open '$app'\""
      sync_icons "$app" "$trampoline"
      copy_paths "$app" "$trampoline"
      # The OS sometimes shows blank/stock icons for freshly generated apps;
      # touching the bundle seems to nudge it into refreshing.
      touch "$trampoline"
    }

    mktrampoline_bin() {
      local bin="$1" trampoline="$2"
      # Redirect both pipes to null so AppleScript does not wait on the binary.
      "$osacompile" -o "$trampoline" -e "do shell script \"'$bin' &> /dev/null &\""
    }

    mktrampoline() {
      local from="$1" to="$2"
      if [ ! -e "$from" ]; then
        echo "No such file: $from" >&2
        return 1
      fi
      if [ -d "$from" ]; then
        if app_p "$from"; then
          mktrampoline_app "$from" "$to"
        else
          echo "Path $from does not appear to be a Mac app (missing Info.plist)" >&2
          return 1
        fi
      else
        mktrampoline_bin "$from" "$to"
      fi
    }

    sync_dock() {
      # dockutil misbehaves under sudo; act as the invoking user.
      export SUDO_USER=""
      local dockutil_args=()
      if [ "''${USER:-}" = "root" ]; then
        # As root, target every end-user's dock, not root's.
        dockutil_args=(--allhomes)
      fi
      local persistents
      persistents="$(dockutil "''${dockutil_args[@]}" -L 2>/dev/null \
        | grep '/nix/store' \
        | grep 'persistentApps' \
        | cut -f1 || true)"
      [ -n "$persistents" ] || return 0
      local existing app base name
      while IFS= read -r existing; do
        [ -n "$existing" ] || continue
        for app in "$@"; do
          base="$(basename "$app")"
          name="''${base%.app}"
          if [ "$name" = "$existing" ]; then
            dockutil "''${dockutil_args[@]}" --add "$(realpath "$app")" --replacing "$existing"
            break
          fi
        done
      done <<< "$persistents"
    }

    # Gather *.app and one level of */*.app (e.g. KDE apps nest themselves).
    sync_trampolines() {
      local from to
      from="$(to_abs_dir "$1")"
      to="$(to_abs_dir "$2")"
      rm -rf "$to"
      # Only build trampolines when the source is a symlinked dir. Since 25.11
      # nix-darwin copies .app folders directly to /Applications, where
      # trampolines only get in the way.
      if [ -L "$from" ] && [ -d "$from" ]; then
        mkdir -p "$to"
        local apps=()
        shopt -s nullglob
        apps=( "$from"/*.app "$from"/*/*.app )
        shopt -u nullglob
        local app base
        for app in "''${apps[@]}"; do
          base="$(basename "$app")"
          mktrampoline "$app" "$to/$base"
        done
        if [ "''${#apps[@]}" -gt 0 ]; then
          sync_dock "''${apps[@]}"
        fi
      fi
    }

    case "''${1:-}" in
      -h|--help)
        usage
        exit 0
        ;;
      mktrampoline)
        if [ "$#" -ne 3 ]; then usage; exit 1; fi
        mktrampoline "$2" "$3"
        ;;
      sync-dock)
        shift
        sync_dock "$@"
        ;;
      sync-trampolines)
        if [ "$#" -ne 3 ]; then usage; exit 1; fi
        sync_trampolines "$2" "$3"
        ;;
      *)
        usage
        exit 1
        ;;
    esac
  '';
}
