{ lib
, pkgs
, fetchpatch
, kernel
, bcachefsCommitDate ? "2022-09-24"
, bcachefsCommitId ? "e46b9641edd5ed1825f344dbc78cbaea17c8e250"
, bcachefsDiffHash ? "sha256-HA5wkPRhcCJWe8RvWjWoh3lDjtnYFXFdPESYCzWCovw="
, kernelPatches # must always be defined in bcachefs' all-packages.nix entry because it's also a top-level attribute supplied by callPackage
, argsOverride ? {}
, ...
} @ args:

# NOTE: bcachefs-tools should be updated simultaneously to preserve compatibility
(kernel.override ( args // {
  argsOverride = {
    version = "${kernel.version}-bcachefs-unstable-${bcachefsCommitDate}";

    extraMeta = {
      branch = "master";
      maintainers = with lib.maintainers; [ davidak Madouura ];
    };
  } // argsOverride;

  kernelPatches = [
    {
      name = "bcachefs-${bcachefsCommitId}";

      patch = fetchpatch {
        name = "bcachefs-${bcachefsCommitId}.diff";
        url = "https://evilpiepirate.org/git/bcachefs.git/rawdiff/?id=${bcachefsCommitId}&id2=v${lib.versions.majorMinor kernel.version}";
        sha256 = bcachefsDiffHash;

        postFetch = ''
          ${pkgs.buildPackages.patchutils}/bin/filterdiff -x 'a/block/bio.c' "$out" > "$tmpfile"
          mv "$tmpfile" "$out"
        '';
      };

      extraConfig = "BCACHEFS_FS y";
    }

    {
      # Needed due to patching failure otherwise
      name = "linux-bcachefs-bio.c-fix";
      patch = ./linux-bcachefs-bio.c-fix.patch;
    }
  ] ++ kernelPatches;
}))
