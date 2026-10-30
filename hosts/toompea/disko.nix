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
      end = "-975M";
      content = {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/";
      };
    };

    content.partitions.SWAP = {
      type = "8200";
      size = "100%";
      content.type = "swap";
    };
  };
}
