{ lib
, pkgs
, fetchpatch
, kernel
, date ? "2022-07-25"
, commit ? "5549e504645ac9ae570323eab6417b560a7def9b"
, diffHash ? "sha256-DStuK3TSFB2BgVLMFxhL+q7RteURvYDj/RF14D5ENuw="
, kernelPatches # must always be defined in bcachefs' all-packages.nix entry because it's also a top-level attribute supplied by callPackage
, argsOverride ? {}
, ...
} @ args:

# NOTE: bcachefs-tools should be updated simultaneously to preserve compatibility
(kernel.override ( args // {
  argsOverride = {
    version = "${kernel.version}-bcachefs-unstable-${date}";

    extraMeta = {
      branch = "master";
      maintainers = with lib.maintainers; [ davidak Madouura ];
    };
  } // argsOverride;

  kernelPatches = [
    {
      name = "bcachefs-${commit}";

      patch = fetchpatch {
        name = "bcachefs-${commit}.diff";
        url = "https://evilpiepirate.org/git/bcachefs.git/rawdiff/?id=${commit}&id2=v${lib.versions.majorMinor kernel.version}";
        sha256 = diffHash;

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
