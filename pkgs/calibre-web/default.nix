{ lib
, pkgsPrev
}:

pkgsPrev.calibre-web.overridePythonAttrs (prev: {
  patches = prev.patches ++ [ ./header-and-stats.patch ];

  dependencies =
    prev.dependencies
    ++ lib.flatten (with prev.optional-dependencies; [ comics kobo ldap metadata ]);

  pythonRelaxDeps = prev.pythonRelaxDeps ++ [ "requests" "wand" ];
})
