{ newUser, ... }:

newUser {
  userName = "ysun";
  fullName = "Yifei Sun";

  profilePicture = ./profile.jpg;
  wallpapersDir = ./wallpapers;

  keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBVZ9mzYNxccuh3uQR7Hly4KjhbRh4s6UlGQe2GjMtIC" # framework
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHaMDj2MpMGwDcUfDcfNHb9UR7gA5Pgtt4EPyC+1OkBP" # xps
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ47Qtg6qSenUh6Whg3ZIpIhdZZdqdG+L1z2f9UnB+Mw" # macbook
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOQCjwNmB60FQhDncIyX/wCRAPIlLD5KLAGrgAdt4xGw" # servercat
  ];
}
