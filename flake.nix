{
  description = "My Emacs configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = {
    self,
    nixpkgs,
  }: let
    inherit (nixpkgs) lib;
    supportedSystems = ["x86_64-linux"];
    forAllSystems = function:
      lib.attrsets.genAttrs
      supportedSystems
      (system: function nixpkgs.legacyPackages.${system});
  in {
    packages = forAllSystems (pkgs: let
      package = pkgs.emacs30.override {
        withPgtk = true;
        withTreeSitter = true;
        withNativeCompilation = true;
      };
    in {
      emacs = pkgs.callPackage ./nix/package.nix {emacs = package;};
      default = self.packages.${pkgs.stdenv.system}.emacs;
    });
  };
}
