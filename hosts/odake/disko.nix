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
      uuid = "724f59df-1b60-41ee-b297-4574c7bfd127";
      content = {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/";
      };
    };
  };
}
