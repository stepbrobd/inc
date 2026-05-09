{ kanidmWithSecretProvisioning_1_10 }:

kanidmWithSecretProvisioning_1_10.overrideAttrs (prev: {
  # the patch probably only need to inject plausible script now
  # but lets just leave private cache and csp as is in there
  patches = prev.patches ++ [ ./custom-deployment.patch ];

  # some darwin test failures?
  __darwinAllowLocalNetworking = true;
})
