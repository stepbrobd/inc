{
  disko.devices.disk.nvme0n1 = {
    type = "disk";
    device = "/dev/nvme0n1";
    content.type = "gpt";

    content.partitions.ESP = {
      type = "ef00";
      size = "1G";
      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
      };
    };

    content.partitions.ROOT = {
      type = "8300";
      size = "100%";
      content = {
        type = "luks";
        name = "crypted";
        settings.allowDiscards = true;
        extraFormatArgs = [ "--type luks2" "--pbkdf argon2id" "--use-random" ];
        content = {
          type = "btrfs";
          extraArgs = [ "-f" ];
          subvolumes = {
            "@/nix" = {
              mountpoint = "/nix";
              mountOptions = [ "nofail" "noatime" "compress=lzo" ];
            };
            "@/root" = {
              mountpoint = "/";
              mountOptions = [ "nofail" "noatime" "compress=lzo" ];
            };
            "@/home" = {
              mountpoint = "/home";
              mountOptions = [ "nofail" "compress=lzo" ];
            };
            "@/swap" = {
              mountpoint = "/swap";
              mountOptions = [ "nofail" "noatime" ];
              swap.swapfile.size = "64G";
            };
          };
        };
      };
    };
  };
}
