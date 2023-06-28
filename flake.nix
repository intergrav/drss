{
  description = "";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    packwiz2nix.url = "github:getchoo/packwiz2nix";
  };

  outputs = {
    self,
    nixpkgs,
    packwiz2nix,
    ...
  }: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forAllSystems = nixpkgs.lib.genAttrs systems;
    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
      });

    forEachSystem = fn:
      forAllSystems (system:
        fn {
          inherit system;
          pkgs = nixpkgsFor.${system};
        });

    inherit (packwiz2nix.lib) mkMultiMCPack;
  in {
    devShells = forEachSystem ({pkgs, ...}: {
      default = pkgs.mkShell {
        packages = [pkgs.packwiz];
      };
    });

    formatter = forEachSystem ({pkgs, ...}: pkgs.alejandra);

    packages = forEachSystem ({pkgs, ...}: {
      inherit (pkgs) drss;
      default = pkgs.drss;
    });

    overlays.default = _: prev: {
      drss = mkMultiMCPack {
        pkgs = prev;
        filesDir = "${self}/files";
        mods = {};
        name = "drss";
      };
    };
  };
}
