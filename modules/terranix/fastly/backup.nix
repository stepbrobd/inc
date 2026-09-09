{ lib, ... }:

let
  inherit (lib.terranix) tfRef;
in
{
  resource.aws_s3_bucket.backup = {
    provider = "aws.fra";
    bucket = "backup";
  };

  resource.fastly_object_storage_access_keys.backup = {
    description = "RW key for Restic backup.";
    permission = "read-write-objects";
    buckets = [ (tfRef "aws_s3_bucket.backup.bucket") ];
  };
}
