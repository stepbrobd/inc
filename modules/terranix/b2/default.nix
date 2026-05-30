{ lib, ... } @ args:

{ ... }:

let
  inherit (lib) map filter attrNames readDir;
in
{
  imports = map
    (f: import ./${f} args)
    (filter
      (f: f != "default.nix")
      (attrNames (readDir ./.)));

  resource.b2_bucket.stepbrobd = {
    bucket_name = "stepbrobd";
    bucket_type = "allPublic";

    # b2 keeps every version by default
    # prune versions 1 day after they are hidden
    # like repushed nix-cache-info/narinfo or gc-deleted paths, etc.
    # DO NOT set days_from_uploading_to_hiding as it will hide live cache objects
    lifecycle_rules = [{
      file_name_prefix = "";
      days_from_hiding_to_deleting = 1;
    }];
  };
}
