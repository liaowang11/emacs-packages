# ABOUTME: Ensures the Build workflow stays manual-only with no automatic triggers.
let
  workflowText = builtins.readFile ../.github/workflows/build.yml;
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
    (assertLacks "push:" workflowText)
    (assertLacks "pull_request:" workflowText)
    (assertHas "nix flake check" workflowText)
    (assertHas "nix build" workflowText)
  ];
in
builtins.foldl' (acc: check: builtins.seq acc check) true checks
