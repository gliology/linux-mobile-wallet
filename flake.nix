{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

    mobile-nixos = {
      url = github:FlorianFranzen/mobile-nixos/develop;
      flake = false;
    };
  };

  outputs = { self, nixpkgs, mobile-nixos }: let
    mobileConfig = device: import "${mobile-nixos}/lib/configuration.nix" { inherit device; };

    config = self.nixosConfigurations.wallet.config;

    outputs = config.mobile.outputs // config.mobile.outputs.${config.mobile.system.type};
    derivations = with nixpkgs.lib; filterAttrs (_key: isDerivation) outputs;
  in {
    nixosConfigurations.wallet = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        (mobileConfig "pine64-pinephone")
        ./config.nix
      ];
    };

    # FIXME We abuse the system notation here expecting a host with binfmt
    packages.x86_64-linux = derivations;
    packages.aarch64-linux = derivations;

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.default;
    defaultPackage.aarch64-linux = self.packages.aarch64-linux.default;
  };
}
