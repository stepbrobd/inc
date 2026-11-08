{ pkgsPrev }: pkgsPrev.himalaya.override { buildFeatures = [ "native-tls" ]; }
