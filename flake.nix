{
  description = "A collection of kubernetes helm charts in a nix-digestable format.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-kube-generators.url = "github:farcaller/nix-kube-generators";
    poetry2nix.url = "github:nix-community/poetry2nix";
    poetry2nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, haumea, nixpkgs, flake-utils, nix-kube-generators, poetry2nix, ... }: {
    chartsMetadata = haumea.lib.load {
      src = ./charts;
      transformer = haumea.lib.transformers.liftDefault;
    };

    charts = { pkgs }:
      let
        kubelib = nix-kube-generators.lib { inherit pkgs; };
        trimBogusVersion = attrs: builtins.removeAttrs attrs ["bogusVersion"];
      in
      haumea.lib.load {
        src = ./charts;
        loader = {...}: p: kubelib.downloadHelmChart (trimBogusVersion (import p));
        transformer = haumea.lib.transformers.liftDefault;
      };
  } // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryEnv mkPoetryApplication;
    in
    {
      chartsDerivations = self.charts { inherit pkgs; };

      packages.helmupdater = mkPoetryApplication {
        python = pkgs.python312;
        projectDir = ./.;
      };

      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixpkgs-fmt
          poetry
          python310Packages.autopep8
          (mkPoetryEnv {
            python = pkgs.python312;
            projectDir = ./.;
            editablePackageSources = {
              manager = ./.;
            };
          })
        ];
      };
    });
}
