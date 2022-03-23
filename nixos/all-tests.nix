with import ../lib;

{ nixpkgs ? { outPath = cleanSource ./..; revCount = 130979; shortRev = "gfedcba"; }
, stableBranch ? false
, supportedSystems ? [ "x86_64-linux" ]
, configuration ? {}
}:

with import ../pkgs/top-level/release-lib.nix { inherit supportedSystems; };

let
  # Run the tests for each platform.  You can run a test by doing
  # e.g. ‘nix-build -A tests.login.x86_64-linux’, or equivalently,
  # ‘nix-build tests/login.nix -A result’.
  allTestsForSystem = system:
    import ./tests/all-tests.nix {
      inherit system;
      pkgs = import ./.. { inherit system; };
      callTest = t: {
        ${system} = hydraJob t.test;
      };
    };
  allTests =
    foldAttrs recursiveUpdate {} (map allTestsForSystem supportedSystems);

in rec {
  tests = allTests;
}
