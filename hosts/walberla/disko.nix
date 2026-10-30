{
  disko.devices.disk.sda = {
    type = "disk";
    device = "/dev/sda";
    content.type = "gpt";

    content.partitions.BOOT = {
      type = "ef02";
      size = "1M";
    };

    content.partitions.ESP = {
      type = "ef00";
      size = "244M";
      content = {
        type = "filesystem";
        format = "vfat";
      };
    };

    content.partitions.ROOT = {
      type = "8300";
      size = "100%";
      uuid = "a8fb3d96-b6ce-47c8-8a81-ac4261d9b31f";
      content = {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/";
      };
    };
  };
}
