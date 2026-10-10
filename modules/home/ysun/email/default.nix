{ lib, ... }:

{ config, pkgs, ... }:

let
  accounts = {
    ENS = {
      key = "ens";
      address = "yifei.sun@ens-lyon.fr";
      userName = "ysun05";
      imap.host = "imap.ens-lyon.fr";
      smtp = {
        host = "smtp.ens-lyon.fr";
        port = 587;
      };
      # namespace INBOX/
      prefix = "INBOX/";
    };

    iCloud = {
      key = "icloud";
      address = "sun.yifei@icloud.com";
      imap.host = "imap.mail.me.com";
      smtp = {
        host = "smtp.mail.me.com";
        port = 587;
      };
      # system folders and icloud refuses to rename them
      folders = {
        sent = "Sent Messages";
        trash = "Deleted Messages";
      };
    };

    Inria = {
      key = "inria";
      address = "yifei.sun@inria.fr";
      userName = "yisun";
      imap.host = "zimbra.inria.fr";
      smtp = {
        host = "smtp.inria.fr";
        port = 587;
      };
    };

    SoftBank = {
      key = "softbank";
      address = "ysun@i.softbank.jp";
      imap = {
        host = "imap.softbank.jp";
        # does not have AUTH only IMAP LOGIN command
        authentication = "login";
        # half the backends only offer static RSA key exchange
        tlsProvider = "native-tls";
      };
      smtp = {
        host = "smtp.softbank.jp";
        port = 465;
      };
    };

    StepBroBD = {
      key = "stepbrobd";
      primary = true;
      address = "ysun@stepbrobd.com";
      imap.host = "imap.purelymail.com";
      smtp = {
        host = "smtp.purelymail.com";
        port = 465;
      };
    };

    UGA = {
      key = "uga";
      address = "yifei.sun@univ-grenoble-alpes.fr";
      userName = "sunyif";
      imap.host = "zimbra.univ-grenoble-alpes.fr";
      smtp = {
        host = "smtps.univ-grenoble-alpes.fr";
        port = 465;
      };
    };
  };

  layout = {
    drafts = "Drafts";
    sent = "Sent";
    trash = "Trash";
    junk = "Junk";
    archive = "Archive";
  };

  mkAccount =
    _:
    { key
    , address
    , userName ? address
    , primary ? false
    , prefix ? ""
    , imap
    , smtp
    , folders ? { }
    ,
    }:
    let
      realName = "Yifei Sun";
      path = name: prefix + (layout // folders).${name};
    in
    {
      inherit
        address
        userName
        primary
        realName
        ;
      folders = lib.genAttrs [ "drafts" "sent" "trash" ] path;
      passwordCommand = "${lib.getExe' pkgs.coreutils "cat"} ${config.sops.secrets."mail/${key}/pass".path}";
      imap = {
        inherit (imap) host;
        port = 993;
        authentication = imap.authentication or "plain";
      };
      smtp = {
        inherit (smtp) host port;
        tls.useStartTls = smtp.port == 587;
        authentication = "plain";
      };
      himalaya = {
        enable = true;
        settings = {
          email = address;
          display-name = realName;
          mailbox.alias = lib.genAttrs [ "junk" "archive" ] path;
        }
        // lib.optionalAttrs (imap ? tlsProvider) { imap.tls.provider = imap.tlsProvider; };
      };
      thunderbird.enable = true;
    };
in
{
  accounts.email.accounts = lib.mapAttrs mkAccount accounts;

  sops.secrets = lib.listToAttrs (
    lib.mapAttrsToList
      (
        _: account: lib.nameValuePair "mail/${account.key}/pass" { sopsFile = ./secrets.yaml; }
      )
      accounts
  );

  programs.himalaya = {
    enable = true;
    package = pkgs.himalaya.override { buildFeatures = [ "native-tls" ]; };
    settings = {
      downloads-dir = "${config.home.homeDirectory}/Downloads";
      message.send.save-copy = "sent";
    };
  };

  xdg.configFile."carapace/choices/himalaya".text = "himalaya/zsh@bridge\n";
  xdg.configFile."carapace/overlays/himalaya.yaml".source = (pkgs.formats.yaml { }).generate "himalaya.yaml" {
    name = "himalaya";
    persistentflags = {
      "-a, --account=" = "Override the default account";
      "-m, --mailbox=" = "Mailbox name, alias, role or backend-native id";
    };
    completion.flag = {
      account = lib.attrNames accounts;
      mailbox = [ "inbox" ] ++ lib.attrNames layout;
    };
  };

  programs.thunderbird = {
    enable = pkgs.stdenv.hostPlatform.isLinux;
    profiles.Default = {
      isDefault = true;
      # use one archive folder per account
      settings."mail.identity.default.archive_granularity" = 0;
    };
    package = pkgs.thunderbird-bin;
  };
}
