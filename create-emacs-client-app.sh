#!/bin/sh

set -eu

app_dir="$1"
emacs_app="$2"
emacs_bin="$emacs_app/Contents/MacOS/Emacs"
emacsclient_bin="$3"

client_app="$app_dir/Emacs Client.app"
tmpdir="${TMPDIR:-/tmp}"
client_script="$(mktemp "$tmpdir/emacs-client.XXXXXX.applescript")"
trap 'rm -f "$client_script"' EXIT

cat > "$client_script" <<APPLESCRIPT
property emacsClientPath : "$emacsclient_bin"
property emacsAppPath : "$emacs_app"

on open theDropped
  repeat with oneDrop in theDropped
    set dropPath to quoted form of POSIX path of oneDrop
    try
      do shell script quoted form of emacsClientPath & " -c -a '' -n " & dropPath
    end try
  end repeat
  try
    do shell script "open " & quoted form of emacsAppPath
  end try
end open

on run
  try
    do shell script quoted form of emacsClientPath & " -c -a '' -n"
  end try
  try
    do shell script "open " & quoted form of emacsAppPath
  end try
end run

on open location this_URL
  try
    do shell script quoted form of emacsClientPath & " -n " & quoted form of this_URL
  end try
  try
    do shell script "open " & quoted form of emacsAppPath
  end try
end open location
APPLESCRIPT

/usr/bin/osacompile -o "$client_app" "$client_script"

emacs_version="$("$emacs_bin" --version | sed -n '1s/^GNU Emacs //p' | cut -d' ' -f1)"
client_plist="$client_app/Contents/Info.plist"
client_resources="$client_app/Contents/Resources"

plist_set() {
  /usr/libexec/PlistBuddy -c "Add :$1 $2 $3" "$client_plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :$1 $3" "$client_plist"
}

plist_set "CFBundleIdentifier" "string" "org.gnu.EmacsClient"
plist_set "CFBundleName" "string" "Emacs Client"
plist_set "CFBundleDisplayName" "string" "Emacs Client"
plist_set "CFBundleGetInfoString" "string" "Emacs Client $emacs_version"
plist_set "CFBundleVersion" "string" "$emacs_version"
plist_set "CFBundleShortVersionString" "string" "$emacs_version"
plist_set "LSApplicationCategoryType" "string" "public.app-category.productivity"

/usr/libexec/PlistBuddy -c "Delete :CFBundleDocumentTypes" "$client_plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes array" "$client_plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0 dict" "$client_plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:CFBundleTypeRole string Editor" "$client_plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:CFBundleTypeName string 'Text Document'" "$client_plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes array" "$client_plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:0 string public.text" "$client_plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:1 string public.plain-text" "$client_plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:2 string public.source-code" "$client_plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:3 string public.script" "$client_plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:4 string public.shell-script" "$client_plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:5 string public.data" "$client_plist"

/usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes" "$client_plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "$client_plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "$client_plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLName string 'Org Protocol'" "$client_plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "$client_plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string org-protocol" "$client_plist"

cp "$emacs_app/Contents/Resources/Emacs.icns" "$client_resources/applet.icns"
rm -f "$client_resources/droplet.icns" "$client_resources/droplet.rsrc" "$client_resources/Assets.car"
/usr/libexec/PlistBuddy -c "Delete :CFBundleIconFile" "$client_plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string applet" "$client_plist"
