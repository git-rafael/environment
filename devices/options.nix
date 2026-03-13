{ lib, ... }:
{
  options.device = {

    username = lib.mkOption {
      type = lib.types.str;
      description = "Primary user username.";
    };

    userDescription = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Primary user display name.";
    };

    hasFingerprint = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this device has a fingerprint reader.";
    };
  };
}
