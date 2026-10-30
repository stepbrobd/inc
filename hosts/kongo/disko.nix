{
  disko.devices.disk.vda = {
    type = "disk";
    device = "/dev/vda";
    content.type = "gpt";

    content.partitions.ESP = {
      type = "ef00";
      size = "512M";
      uuid = "cdd9cf6c-73da-4a4c-b6bf-bae3447c2d48";
      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
      };
    };

    content.partitions.ROOT = {
      type = "8300";
      size = "100%";
      uuid = "f73abf07-9727-4047-b416-48bafae59e9b";
      content = {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/";
      };
    };
  };
}
