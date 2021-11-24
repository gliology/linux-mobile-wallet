{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

    mobile-nixos = {
      url = github:NixOS/mobile-nixos;
      flake = false;
    };
  };

  outputs = { self, nixpkgs, mobile-nixos }: let
    eval = self.nixosConfigurations.wallet;

    potentialOutputs = eval.config.mobile.outputs // eval.config.mobile.outputs.${eval.config.mobile.system.type};
    actualOutputs = with nixpkgs.lib; filterAttrs (_key: isDerivation) potentialOutputs;
  in {
    nixosConfigurations.wallet = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        (import "${mobile-nixos}/lib/configuration.nix" { device = "pine64-pinephone"; })
        ./config.nix
      ];
    };

    packages.x86_64-linux = actualOutputs;

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.default;
  };
}
