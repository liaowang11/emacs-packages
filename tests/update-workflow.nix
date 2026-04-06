# ABOUTME: Ensures the standalone repo defines a scheduled input update workflow.
# ABOUTME: Keeps the Friday update-and-rebuild path from silently disappearing.
let
  workflowText = builtins.readFile ../.github/workflows/update-flake-inputs.yml;
  hasInfix = needle: text: builtins.replaceStrings [ needle ] [ "" ] text != text;

  assertHas =
    needle: text:
    assert hasInfix needle text;
    true;

  checks = [
    (assertHas "schedule:" workflowText)
    (assertHas "cron: '0 3 * * 5'" workflowText)
    (assertHas "nix flake update" workflowText)
    (assertHas "git push origin HEAD:main" workflowText)
  ];
in
builtins.foldl' (acc: check: builtins.seq acc check) true checks
