{ lib, ... }:
{
  options.device = {
    hasFingerprint = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this device has a fingerprint reader.";
    };
  };
}
