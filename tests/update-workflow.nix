# ABOUTME: Ensures the standalone repo defines the manual input update workflow.
# ABOUTME: Guards the update-and-rebuild path against automatic triggers returning.
let
  workflowText = builtins.readFile ../.github/workflows/update-flake-inputs.yml;
  hasInfix = needle: text: builtins.replaceStrings [ needle ] [ "" ] text != text;

  assertHas =
    needle: text:
    assert hasInfix needle text;
    true;

  assertLacks =
    needle: text:
    assert !hasInfix needle text;
    true;

  checks = [
    (assertHas "workflow_dispatch:" workflowText)
    (assertLacks "schedule:" workflowText)
    (assertLacks "cron:" workflowText)
    (assertHas "nix flake update" workflowText)
    (assertHas ".#packages.aarch64-darwin.tramp-rpc-server" workflowText)
    (assertHas ".#packages.x86_64-linux.tramp-rpc-server" workflowText)
    (assertHas ".#packages.aarch64-linux.tramp-rpc-server" workflowText)
    (assertHas "git push origin HEAD:main" workflowText)
  ];
in
builtins.foldl' (acc: check: builtins.seq acc check) true checks
