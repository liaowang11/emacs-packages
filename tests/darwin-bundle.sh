#!/usr/bin/env bash
# ABOUTME: Checks that the Darwin Emacs.app starts from a copy outside the store with no wrapper environment.
# ABOUTME: Guards the login-restore fix: real executable in the bundle, preloaded .eln beside it, paths in LSEnvironment.
set -euo pipefail

package="$1"
app="$package/Applications/Emacs.app"

fail() {
  echo "darwin-bundle: $*" >&2
  exit 1
}

[ -d "$app" ] || fail "no Emacs.app in $package"

# The wrapper stub has to be gone, replaced by the real executable. macOS keys
# the login restore on the bundle owning the running executable, so a stub that
# execs the store would put the base Emacs back into the restore list.
if [ -e "$app/Contents/MacOS/.Emacs-wrapped" ]; then
  fail "the emacsWithPackages stub is still in the bundle"
fi
executable="$app/Contents/MacOS/Emacs"
[ -f "$executable" ] || fail "missing $executable"
file "$executable" | grep -q "Mach-O" || fail "not a Mach-O: $(file "$executable")"
size="$(wc -c <"$executable")"
[ "$size" -gt 1000000 ] || fail "executable is only $size bytes, still a wrapper stub"

# pdumper.c looks for the preloaded .eln next to the executable, before Lisp
# runs. A symlink here would be followed by the copyApps rsync, which would
# then copy the whole native-lisp tree on every generation.
if [ -L "$app/Contents/native-lisp" ]; then
  fail "Contents/native-lisp is a symlink, the copyApps rsync would follow it"
fi
preloaded="$(echo "$app"/Contents/native-lisp/*/preloaded)"
[ -d "$preloaded" ] || fail "no Contents/native-lisp/<abi>/preloaded in the bundle"
elnCount="$(find "$preloaded" -name '*.eln' | wc -l | tr -d ' ')"
[ "$elnCount" -gt 100 ] || fail "only $elnCount preloaded .eln files in the bundle"

plist="$app/Contents/Info.plist"
for key in EMACSLOADPATH EMACSNATIVELOADPATH emacsWithPackages_siteLisp emacsWithPackages_siteLispNative; do
  grep -q "<key>$key</key>" "$plist" || fail "Info.plist LSEnvironment is missing $key"
done

# Home Manager copies the bundle out of the store into a path with spaces.
work="$(mktemp -d)"
target="$work/Home Manager Apps"
mkdir -p "$target" "$work/home"
cp -R "$app" "$target/Emacs.app"
chmod -R u+w "$target/Emacs.app"
copied="$target/Emacs.app/Contents/MacOS/Emacs"

cat >"$work/probe.el" <<'ELISP'
;;; -*- lexical-binding: t -*-
(require 'cl-macs)

(defvar probe-failures nil)

(defun probe-check (label value)
  (message "  %-22s %S" label value)
  (unless value (push label probe-failures)))

(probe-check "invocation-directory"
             (equal (file-truename invocation-directory)
                    (file-truename (expand-file-name
                                    "Contents/MacOS/"
                                    (getenv "PROBE_BUNDLE")))))
(probe-check "data-directory" (file-directory-p data-directory))
(probe-check "exec-directory" (file-directory-p exec-directory))
(probe-check "native-compile" (featurep 'native-compile))

(when (equal (getenv "PROBE_MODE") "packages")
  (probe-check "package site-start"
               (equal (locate-library "site-start")
                      (concat (getenv "PROBE_SITE_LISP") "/site-start.elc")))
  (dolist (library '("tramp-rpc" "vterm" "mu4e"))
    (probe-check library (and (locate-library library) t)))
  (probe-check "python grammar" (treesit-language-available-p 'python))
  ;; Proves the store native-lisp directory resolved. A jit fallback would
  ;; leave this one byte-compiled.
  (probe-check "native cl-macs"
               (native-comp-function-p (symbol-function 'cl--parse-loop-clause))))

(when probe-failures
  (message "FAILED: %s" (mapconcat #'identity (nreverse probe-failures) ", "))
  (kill-emacs 1))
ELISP

lsEnvironment=()
while IFS= read -r entry; do
  lsEnvironment+=("$entry")
done < <(python3 - "$target/Emacs.app/Contents/Info.plist" <<'PYTHON'
import plistlib
import sys

for name, value in plistlib.load(open(sys.argv[1], "rb"))["LSEnvironment"].items():
    print(name + "=" + value)
PYTHON
)

siteLisp=""
for entry in "${lsEnvironment[@]}"; do
  case "$entry" in
    emacsWithPackages_siteLisp=*) siteLisp="${entry#*=}" ;;
  esac
done
[ -n "$siteLisp" ] || fail "could not read emacsWithPackages_siteLisp back from Info.plist"

# A start with nothing in the environment. Only the bundle keeps Emacs alive
# here: this is the case that used to die with "Error using execdir".
echo "darwin-bundle: bare environment"
env -i \
  HOME="$work/home" \
  PATH="$PATH" \
  TMPDIR="$work" \
  PROBE_MODE=bare \
  PROBE_BUNDLE="$target/Emacs.app" \
  "$copied" --batch -l "$work/probe.el"

# A LaunchServices start, which is what a login restore does: the environment
# comes from Info.plist and from nowhere else.
echo "darwin-bundle: LSEnvironment only"
env -i \
  HOME="$work/home" \
  PATH="$PATH" \
  TMPDIR="$work" \
  PROBE_MODE=packages \
  PROBE_BUNDLE="$target/Emacs.app" \
  PROBE_SITE_LISP="$siteLisp" \
  "${lsEnvironment[@]}" \
  "$copied" --batch -l "$work/probe.el"

rm -rf "$work"
echo "Copied bundle startup passed"
