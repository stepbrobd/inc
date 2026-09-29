# TODO: FIXME: drop after upstream fix
{ pkgsPrev }: pkgsPrev.mergiraf.overrideAttrs { doCheck = false; }
