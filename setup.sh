#!/usr/bin/env bash
# Generates the android/ios platform folders for both apps (needs Flutter installed),
# then fetches packages. Run once from the mmb/ folder:  bash setup.sh
set -e
for app in mmb_seller mmb_buyer; do
  tmp=$(mktemp -d)
  (cd "$tmp" && flutter create --org com.mmb --platforms=android,ios "$app")
  cp -r "$tmp/$app/android" "$tmp/$app/ios" "$app/"
  rm -rf "$tmp"
  (cd "$app" && flutter pub get)
done
echo "Done. Next: add Firebase config files (see README.md)."
