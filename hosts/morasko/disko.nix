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
            mountOptions = [ "nofail" "noatime" "rescue=usebackuproot" "compress=zstd" ];
          };
          "@/root" = {
            mountpoint = "/";
            mountOptions = [ "nofail" "noatime" "rescue=usebackuproot" "compress=zstd" ];
          };
          "@/home" = {
            mountpoint = "/home";
            mountOptions = [ "nofail" "rescue=usebackuproot" "compress=zstd" ];
          };
          "@/swap" = {
            mountpoint = "/swap";
            mountOptions = [ "nofail" "noatime" "rescue=usebackuproot" ];
            swap.swapfile.size = "8G";
          };
        };
      };
    };
  };
}
