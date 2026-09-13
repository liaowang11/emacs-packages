# ABOUTME: Writes the emacsWithPackages paths into the Emacs.app Info.plist LSEnvironment dict.
# ABOUTME: LSEnvironment is the only channel that reaches a macOS login restore, which runs no shell wrapper.
import plistlib
import sys

plist_path, site_lisp, deps_native_lisp, emacs_native_lisp = sys.argv[1:5]

with open(plist_path, "rb") as handle:
    plist = plistlib.load(handle)

plist["LSEnvironment"] = {
    # The trailing empty entry means "then the built-in load path", the same
    # value the emacsWithPackages shell wrapper exports.
    "EMACSLOADPATH": site_lisp + ":",
    "EMACSNATIVELOADPATH": deps_native_lisp + ":" + emacs_native_lisp + ":",
    # site-start.el removes these two from the environment once it has used
    # them, so subprocesses started from Emacs do not inherit them.
    "emacsWithPackages_siteLisp": site_lisp,
    "emacsWithPackages_siteLispNative": deps_native_lisp,
}

with open(plist_path, "wb") as handle:
    plistlib.dump(plist, handle)
