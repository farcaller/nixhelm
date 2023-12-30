{
  description = "A collection of kubernetes helm charts in a nix-digestable format.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-kube-generators.url = "github:farcaller/nix-kube-generators";
    poetry2nix.url = "github:nix-community/poetry2nix";
    poetry2nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, nix-kube-generators, poetry2nix, ... }: {
    chartsMetadata = builtins.listToAttrs (map
      (repo: {
        name = repo;
        value =
          let
            charts = builtins.attrNames (builtins.readDir ./charts/${repo});
          in
          builtins.listToAttrs (map
            (name: {
              inherit name;
              value = import ./charts/${repo}/${name};
            })
            charts);
      })
      (builtins.attrNames (builtins.readDir ./charts)));

    charts = { pkgs }:
      let
        kubelib = nix-kube-generators.lib { inherit pkgs; };
      in
      builtins.mapAttrs
        (
          reponame: charts:
            builtins.mapAttrs
              (
                chartname: chartspec:
                  (kubelib.downloadHelmChart (builtins.removeAttrs chartspec ["bogusVersion"]))
              )
              charts
        )
        self.chartsMetadata;
  } // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (poetry2nix.lib.mkPoetry2Nix { inherit pkgs; }) mkPoetryEnv mkPoetryApplication;
    in
    {
      chartsDerivations = self.charts { inherit pkgs; };

      packages.helmupdater = mkPoetryApplication {
        python = pkgs.python310;
        projectDir = ./.;
      };

      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixpkgs-fmt
          poetry
          python310Packages.autopep8
          (mkPoetryEnv {
            python = pkgs.python310;
            projectDir = ./.;
            editablePackageSources = {
              manager = ./.;
            };
          })
        ];
      };
    });
}
