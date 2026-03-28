{
  disko.devices.disk.nvme0n1 = {
    type = "disk";
    device = "/dev/nvme0n1";
    content.type = "gpt";

    content.partitions.FIRMWARE = {
      priority = 1;
      type = "0700";
      size = "1G";
      attributes = [ 0 ]; # required partition 
      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot/firmware";
        mountOptions = [
          "noatime"
          "noauto"
          "x-systemd.automount"
          "x-systemd.idle-timeout=1min"
        ];
      };
    };

    content.partitions.ESP = {
      type = "ef00";
      size = "1G";
      attributes = [ 2 ]; # legacy BIOS bootable, for uboot to find extlinux config
      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
        mountOptions = [
          "noatime"
          "noauto"
          "x-systemd.automount"
          "x-systemd.idle-timeout=1min"
          "umask=0077"
        ];
      };
    };

    content.partitions.ROOT = {
      type = "8300";
      size = "100%";
      content = {
        type = "filesystem";
        format = "ext4";
        mountpoint = "/";
      };
    };
  };
}
