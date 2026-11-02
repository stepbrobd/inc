{ kanidmWithSecretProvisioning_1_12 }:

kanidmWithSecretProvisioning_1_12.overrideAttrs (prev: {
  patches = prev.patches ++ [
    ./custom-deployment.patch
  ];

  postPatch = (prev.postPatch or "") + ''
    cp ${./override.css} server/core/static/override.css
  '';

  __darwinAllowLocalNetworking = true;
})
