{ pkgs
, pkgsPrev ? pkgs
, fetchFromGitLab
, fetchpatch2
}:

pkgsPrev.bird3.overrideAttrs (finalAttrs: oldAttrs: {
  version = "3.3.1";

  src = fetchFromGitLab {
    domain = "gitlab.nic.cz";
    owner = "labs";
    repo = "bird";
    tag = "v${finalAttrs.version}";
    hash = "sha256-aJo6Ut/ULBDGoekSXgN1WvmFmonTzNA3TES1FHqCiOM=";
  };

  patches = (oldAttrs.patches or [ ]) ++ [
    # link quality algo selection
    (fetchpatch2 {
      url = "https://github.com/nickcao/bird/commit/0b21028f41c00097b3232a83258a0c574300f1fc.patch";
      hash = "sha256-KcAG03qGAaxb/1MGAnWHNzxVrIE5csqBc9+jqxD4ID4=";
    })
    # iface deletion race
    (fetchpatch2 {
      url = "https://github.com/nickcao/bird/commit/18175de3cc75b4e662b5f43d8a93a1c062a8b3ab.patch";
      hash = "sha256-N11bkhn67fPXPSfrJ32v+t6Gwyh0qIOuisJ7uk1WGPA=";
    })
  ];
})
