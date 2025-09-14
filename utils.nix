# Useful helper functions
# I recommend calling it into it's own variable:
#     utilities = (defaults-flake.lib pkgs);
{ pkgs, ... }:
rec {
  # Overrides a derivation to include new CFLAGS alongside existing CFLAGS
  # flags is a list of a strings representing the CFLAGS to be set
  optimizeWithFlags = pkg: flags:
    pkgs.lib.overrideDerivation pkg (old:
      let
        newflags = pkgs.lib.foldl' (acc: x: "${acc} ${x}") "" flags;
        oldflags =
          if (pkgs.lib.hasAttr "NIX_CFLAGS_COMPILE" old)
          then "${old.NIX_CFLAGS_COMPILE}"
          else "";
      in
      {
        NIX_CFLAGS_COMPILE = "${oldflags} ${newflags}";
      });

  # Ensure all possible optimizations for this machine
  optimizeForThisMachine = pkg:
    optimizeWithFlags pkg [
      # Optimize level 3 (highest level)
      "-O3"
      # Optimize using specific microcode and ISA implementations for this machine
      "-march=native"
      # No relative pointer index offets (Position Independent Code)
      "-fPIC"
    ];

  # Harden the code to make it less likely to be expoloited
  compileTimeHardening = pkg:
    optimizeWithFlags pkg [
      # Warn when printf/scanf don't use string literals
      "-Wformat"
      "-Wformat-security"
      "-Werror=format-security"
      # Add overwrite canaries to buffers greater than 4 bytes
      "-fstack-protector-strong"
      "--param ssp-buffer-size=4"
      # Add buffer overflow checks at compile and at runtime; no using %n in
      # string formatting functions (e.g. printf()) unless they are read only
      "-O2"
      "-D_FORTIFY_SOURCE=2"
      # No relative pointer index offets (Position Independent Code) and makes
      # ASLR possible
      "-fPIC"
      # Adds interger overflow checking to prevent errors
      "-fno-strict-overflow"
    ];

  # Build with DEBUG flags
  withDebuggingCompiled = pkg:
    optimizeWithFlags pkg [ "-DDEBUG" ];
}
