{ python3PackagesPrev
, fetchFromGitHub
}:

python3PackagesPrev.pip-chill.overridePythonAttrs {
  version = "1.0.3-unstable-2026-01-25";

  src = fetchFromGitHub {
    owner = "rbanffy";
    repo = "pip-chill";
    rev = "e978cc0a0ced8cce685db92fcf4f5ab3fca6f21e";
    hash = "sha256-Sn7BfNnslLaVcCJsEMgZaOubD4YfkuO6VhX7aS+7yxg=";
  };
}
