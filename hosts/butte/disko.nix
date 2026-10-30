{
  disko.devices.disk.vda = {
    type = "disk";
    device = "/dev/vda";
    content.type = "table";
    content.format = "msdos";

    content.partitions = [
      {
        name = "ROOT";
        start = "1MiB";
        end = "100%";
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/";
        };
      }
    ];
  };
}
