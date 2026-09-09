{ lib, ... }:

{ config, pkgs, ... }:

let
  hasTag = lib.hasTag config.networking.hostName;

  # NOTE: in this specific implementation the bucket is tied to Fastly Object Storage
  # see modules/terranix/fastly/backup.nix
  region = "eu-central-1";
  bucket = "backup";

  # all dumps goes here before snapshot (one dir per job)
  dir = "/var/backup";

  hasDumps = job: job.postgresql != [ ] || job.clickhouse != [ ] || job.sqlite != { };
  dumps = lib.filterAttrs (_: hasDumps) config.services.restic.backups;

  # every dump is one file or directory that one identity writes with one command
  # postgres and clickhouse dump as the identity their server runs as and sqlite as the declared owner
  # root prepares the directory and clears the previous dump
  # then setpriv drops to the owner without setuid or pam and no-new-privs keeps the child there
  dumpScript = name: job:
    let
      base = "${dir}/${name}";
      dumps = lib.map
        (db: {
          inherit (config.systemd.services.postgresql.serviceConfig) User Group;
          path = "${base}/postgresql/${db}.sql";
          # plain sql so restic deduplicates across days
          command = ''${lib.getExe' config.services.postgresql.package "pg_dump"} --clean --if-exists --create --file ${base}/postgresql/${db}.sql ${db}'';
        })
        job.postgresql
      ++ lib.map
        (db: {
          inherit (config.systemd.services.clickhouse.serviceConfig) User Group;
          path = "${base}/clickhouse/${db}";
          command = ''${lib.getExe' config.services.clickhouse.package "clickhouse-client"} --query "BACKUP DATABASE ${db} TO File('${base}/clickhouse/${db}')"'';
        })
        job.clickhouse
      ++ lib.mapAttrsToList
        (db: sqlite: {
          User = sqlite.user;
          Group = config.users.users.${sqlite.user}.group;
          path = "${base}/sqlite/${db}/${db}.db";
          command = ''${lib.getExe' pkgs.sqlite "sqlite3"} ${sqlite.path} ".backup ${base}/sqlite/${db}/${db}.db"'';
        })
        job.sqlite;
    in
    lib.concatMapStringsSep "\n"
      (dump: ''
        install -d -m 0700 -o ${dump.User} -g ${dump.Group} ${lib.dirOf dump.path}
        rm -rf ${dump.path}
        ${lib.getExe' pkgs.util-linux "setpriv"} --reuid=${dump.User} --regid=${dump.Group} --init-groups --no-new-privs --reset-env -- ${dump.command}
      '')
      dumps;
in
{
  # every job may declare databases to dump right before its snapshot
  options.services.restic.backups = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({ name, config, ... }: {
      options = {
        postgresql = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Databases pg_dump writes to ${dir}/<job>/postgresql before the snapshot";
        };

        clickhouse = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Databases ClickHouse BACKUP writes to ${dir}/<job>/clickhouse before the snapshot";
        };

        sqlite = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              path = lib.mkOption {
                type = lib.types.str;
                description = "SQLite database file";
              };
              user = lib.mkOption {
                type = lib.types.str;
                description = "Owner of the database, the copy runs as this user";
              };
            };
          });
          default = { };
          description = "Databases copied through the SQLite online backup API to ${dir}/<job>/sqlite/<name>/<name>.db before the snapshot";
        };
      };

      # the job's dump directory rides along with whatever else it declares
      config.paths = lib.optional (hasDumps config) "${dir}/${name}";
    }));
  };

  config = lib.mkMerge [
    (lib.mkIf (hasTag "backup") {
      sops.secrets.restic = { };

      services.restic.backups.s3 = {
        repository = "s3:https://${region}.object.fastlystorage.app/${bucket}/${config.networking.fqdn}";
        environmentFile = config.sops.secrets.restic.path;
        # FIXME: a bucket scoped key cannot HeadBucket
        # repository is created once from my laptop with admin key
        initialize = false;
        extraOptions = [ "s3.bucket-lookup=path" "s3.region=${region}" ];
        # storage is not the constraint
        # snapshot every hour and spread hosts over it
        timerConfig = {
          OnCalendar = "hourly";
          RandomizedDelaySec = "30m";
          Persistent = true;
        };
        # one group per host
        # o.w. every past set of paths keeps its own snapshots forever
        pruneOpts = [ "--group-by host" "--keep-hourly 48" "--keep-daily 30" "--keep-weekly 12" "--keep-monthly 24" ];
        checkOpts = [ "--read-data-subset=1%" ];
      };

      systemd.services.restic-backups-s3.serviceConfig = {
        Nice = 19;
        IOSchedulingClass = "idle";
      };
    })

    {
      assertions = lib.concatLists (lib.mapAttrsToList
        (name: job: [
          {
            assertion = job.postgresql != [ ] -> config.services.postgresql.enable;
            message = "services.restic.backups.${name}.postgresql declares databases but services.postgresql is not enabled";
          }
          {
            assertion = job.clickhouse != [ ] -> config.services.clickhouse.enable;
            message = "services.restic.backups.${name}.clickhouse declares databases but services.clickhouse is not enabled";
          }
        ] ++ lib.mapAttrsToList
          (db: sqlite: {
            assertion = config.users.users ? ${sqlite.user};
            message = "services.restic.backups.${name}.sqlite.${db} runs as ${sqlite.user}, which is not a user on this host";
          })
          job.sqlite)
        dumps);

      # dumps run in the unit's own preStart after restic reached the repository (a failed dump fails the snapshot)
      systemd.services = lib.mapAttrs' (name: job: lib.nameValuePair "restic-backups-${name}" { preStart = lib.mkAfter (dumpScript name job); }) dumps;

      # File() backups may only land under an allowed path
      services.clickhouse.serverConfig = lib.mkIf (lib.any (job: job.clickhouse != [ ]) (lib.attrValues dumps)) {
        backups.allowed_path = "${dir}/";
      };
    }
  ];
}
