{
  disko.devices.disk.ld1 = {
    type = "disk";
    device = "/dev/disk/by-path/pci-0000:5c:00.0-scsi-0:1:0:0";
    content.type = "gpt";

    content.partitions.ESP = {
      type = "ef00";
      size = "1G";
      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
        mountOptions = [ "umask=0077" ];
      };
    };

    content.partitions.ROOT = {
      type = "8300";
      size = "100%";
      content = {
        type = "btrfs";
        extraArgs = [ "-f" ];
        subvolumes = {
          "@/nix" = {
            mountpoint = "/nix";
            mountOptions = [ "nofail" "noatime" "rescue=usebackuproot" "compress=zstd:1" ];
          };
          "@/root" = {
            mountpoint = "/";
            mountOptions = [ "nofail" "noatime" "rescue=usebackuproot" "compress=zstd:1" ];
          };
          "@/home" = {
            mountpoint = "/home";
            mountOptions = [ "nofail" "rescue=usebackuproot" "compress=zstd:1" ];
          };
        };
      };
    };
  };
}
