{
  disko.devices.disk.sda = {
    type = "disk";
    device = "/dev/sda";
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
            swap.swapfile.size = "8G";
          };
        };
      };
    };
  };
}
