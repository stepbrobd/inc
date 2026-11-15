{
  disko.devices.disk.vda = {
    type = "disk";
    device = "/dev/vda";
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
        type = "btrfs";
        extraArgs = [ "-f" ];
        subvolumes = {
          "@/nix" = {
            mountpoint = "/nix";
            mountOptions = [ "nofail" "noatime" "compress=zstd" ];
          };
          "@/root" = {
            mountpoint = "/";
            mountOptions = [ "nofail" "noatime" "compress=zstd" ];
          };
          "@/home" = {
            mountpoint = "/home";
            mountOptions = [ "nofail" "compress=zstd" ];
          };
          "@/swap" = {
            mountpoint = "/swap";
            mountOptions = [ "nofail" "noatime" ];
            swap.swapfile.size = "8G";
          };
        };
      };
    };
  };
}
