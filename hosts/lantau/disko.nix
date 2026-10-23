{
  disko.devices.disk.sda = {
    type = "disk";
    device = "/dev/sda";
    content.type = "gpt";

    content.partitions.BOOT = {
      type = "ef02";
      size = "1M";
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
