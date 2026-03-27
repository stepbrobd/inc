{ lib }:

hostName: tag:
let
  host = lib.blueprint.hosts.${hostName} or null;
in
host != null && lib.elem tag (host.tags or [ ])
