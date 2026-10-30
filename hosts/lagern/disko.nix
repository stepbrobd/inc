{
  disko.devices.disk.xvda = {
    type = "disk";
    device = "/dev/xvda";
    content.type = "gpt";

    content.partitions.BOOT = {
      type = "ef02";
      size = "1M";
    };

    content.partitions.ROOT = {
      type = "8300";
      size = "100%";
      uuid = "970c694f-afd0-4b99-b750-cdb7a329ab6f";
      content = {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/";
      };
    };
  };
}
