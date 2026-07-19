{ lib
, python3Packages
, fetchFromGitHub
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "kobo-book-downloader";
  version = "0.14.0";
  pyproject = true;

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "subdavis";
    repo = "kobo-book-downloader";
    tag = finalAttrs.version;
    hash = "sha256-z1q5kqcyJFbmRzQQyAIjDk3lBholwcKsbrsss5eOumQ=";
  };

  build-system = [
    python3Packages.poetry-core
  ];

  dependencies = with python3Packages; [
    beautifulsoup4
    click
    dataclasses-json
    flask
    pycryptodome
    requests
    setuptools
    tabulate
  ];

  pythonImportsCheck = [
    "kobodl"
  ];

  pythonRemoveDeps = [
    "dataclasses"
  ];

  pythonRelaxDeps = [
    "dataclasses-json"
    "flask"
    "setuptools"
    "tabulate"
  ];

  meta = {
    description = "A tool to download and remove DRM from your purchased Kobo.com ebooks and audiobooks";
    homepage = "https://github.com/subdavis/kobo-book-downloader";
    changelog = "https://github.com/subdavis/kobo-book-downloader/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.unlicense;
    maintainers = with lib.maintainers; [ stepbrobd ];
    mainProgram = "kobodl";
  };
})
