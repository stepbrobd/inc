{
  disko.devices.disk.sda = {
    type = "disk";
    device = "/dev/sda";
    content.type = "table";
    content.format = "msdos";

    content.partitions = [
      {
        name = "ROOT";
        start = "1MiB";
        end = "39983MiB";
        bootable = true;
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/";
        };
      }
      {
        name = "EXTENDED";
        part-type = "extended";
        start = "39983MiB";
        end = "100%";
      }
      {
        name = "SWAP";
        part-type = "logical";
        fs-type = "linux-swap";
        start = "39984MiB";
        end = "100%";
        content = {
          type = "swap";
          device = "/dev/sda5";
        };
      }
    ];
  };
}
