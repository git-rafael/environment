#!/usr/bin/awk -f
#
# Filter applied to `rc2nix` output by `env-load user ui-update`.
# Strips transient state that should not be versioned:
#
#   shortcuts  - drops entries with an empty binding ([ ])
#   configFile - drops dolphin timestamps, spectacle last-save path,
#                plasma notification "Seen" flags, and per-monitor
#                kwin Tiling layouts keyed by volatile UUIDs
#   dataFile   - drops the entire Kate anonymous session state
#
# Any block that ends up empty is removed along with its header.

# Track the current top-level block inside `programs.plasma`.
/^    shortcuts = \{$/  { block = "shortcuts";  buf = $0; bufn = 1; next }
/^    configFile = \{$/ { block = "configFile"; buf = $0; bufn = 1; next }
/^    dataFile = \{$/   { block = "dataFile";   buf = $0; bufn = 1; next }

# Closing brace of a tracked block: flush unless empty.
block != "" && /^    \};$/ {
  if (bufn > 1) {
    print buf;
    print $0;
  }
  block = "";
  buf = "";
  bufn = 0;
  next;
}

# Inside a tracked block: apply per-block filters.
block == "shortcuts" {
  # Drop entries with no binding (e.g. `foo = [ ];`).
  if ($0 ~ /= \[ \];$/) next;
  buf = buf "\n" $0;
  bufn++;
  next;
}

block == "configFile" {
  if ($0 ~ /^      dolphinrc\.General\.ViewPropsTimestamp /) next;
  if ($0 ~ /^      spectaclerc\.ImageSave\.lastImageSaveLocation /) next;
  if ($0 ~ /^      plasmanotifyrc\."Applications\/[^"]+"\.Seen /) next;
  if ($0 ~ /^      kwinrc\."Tiling\//) next;
  buf = buf "\n" $0;
  bufn++;
  next;
}

block == "dataFile" {
  # Swallow everything; the block header is dropped on close too.
  next;
}

# Outside tracked blocks: pass through unchanged.
{ print }
