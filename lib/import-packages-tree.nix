{ lib }:

{ dir
, currentFinal
, currentPrev
, inheritedArgs ? { }
}:

let
  inherit (lib)
    baseNameOf
    callPackageWith
    childDirsWithDefault
    fix
    hasAttrByPath
    isAttrs
    importPackagesTree
    isDerivation
    isFunction
    length
    makeScope
    mkDynamicAttrs
    pathExists
    ;
in
mkDynamicAttrs (
  fix (self: {
    inherit dir;
    fun =
      name:
      (
        # was importPackagesWith (dropped in a916dc95e3d342a00a4b9353f9be5de2d987fb22):
        # <resulting package set> :: <the file we are calling> :: <callPackage args>
        pkgs: pkg: args:
        let
          scopeName = baseNameOf pkg;
          hasDefaultNix = pathExists (pkg + "/default.nix");
          childScopeNames = if !hasDefaultNix then childDirsWithDefault pkg else [ ];
          hasChildScopes = length childScopeNames > 0;

          # lazy eval, only touch currentPrev when the local package path has no default.nix and guard alias throws with tryEval
          hasScopeAttr = !hasDefaultNix && hasAttrByPath [ scopeName ] currentPrev;
          scopeEval =
            if hasScopeAttr then
              builtins.tryEval currentPrev.${scopeName}
            else
              {
                success = false;
                value = null;
              };
          hasScopeValue = scopeEval.success;
          scopeValue = if hasScopeValue then scopeEval.value else null;
          hasOverrideScope = hasScopeValue && isAttrs scopeValue && scopeValue ? overrideScope;
          hasExtend = hasScopeValue && isAttrs scopeValue && scopeValue ? extend;

          # note that some scopes expose extend rather than overrideScope, e.g. haskellPackages
          isScope = hasScopeValue && isAttrs scopeValue && !isDerivation scopeValue && (hasOverrideScope || hasExtend);
          scopeOverride =
            if hasOverrideScope then
              scopeValue.overrideScope
            else
              scopeValue.extend;
        in
        if hasDefaultNix then
          let
            imported = import pkg;
          in
          # case 1: local package/default.nix always wins over currentPrev attrs
          if !isFunction imported then
            imported
          else
            (pkgs.lib.callPackageWith pkgs) pkg args
        # case 2: the imported dir is an existing scope in currentPrev
        # i've decided that having a entry point for scoped pkgs to override arguments used
        # is a antipattern, injecting root level pkgsPrev and pkgsFinal with scope level
        # fixedpoints is a better idea
        else if isScope then
          scopeOverride
            (
              scopeFinal: scopePrev:
              let
                inheritedScopeArgs = inheritedArgs // {
                  "${scopeName}Final" = scopeFinal;
                  "${scopeName}Prev" = scopePrev;
                };
              in
              # recurse:
              importPackagesTree {
                dir = pkg;
                currentFinal = scopeFinal;
                currentPrev = scopePrev;
                inheritedArgs = inheritedScopeArgs;
              }
            )
        # case 3: local scope (no default.nix, but has child dirs with default.nix)
        else if hasChildScopes then
          makeScope callPackageWith
            (
              localScopeFinal:
              let
                inheritedScopeArgs = inheritedArgs // {
                  "${scopeName}Final" = localScopeFinal;
                  "${scopeName}Prev" = localScopeFinal;
                };
              in
              # recurse:
              importPackagesTree {
                dir = pkg;
                currentFinal = localScopeFinal;
                currentPrev = currentPrev;
                inheritedArgs = inheritedScopeArgs;
              }
            )
        # bail if not scope and does not have default.nix
        else
          throw
            "path ${toString pkg} has no default.nix and is not a scope"
      )
        (
          # always expose top-level package args (e.g. fetchgit) and then scope args
          # (e.g. mkDerivation) with scope args taking precedence.
          (if hasAttrByPath [ "pkgsFinal" ] inheritedArgs then inheritedArgs.pkgsFinal else currentFinal)
          // currentFinal
          // inheritedArgs
        )
        (self.dir + "/${name}")
        { };
  })
)
