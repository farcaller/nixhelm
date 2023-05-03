{
  description = "Nix-wrapped helm packages";

  inputs = {
    nix-kube-generators.url = "github:farcaller/nix-kube-generators";
  };

  outputs = { self, nixpkgs, flake-utils, nix-kube-generators, ... }: {
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
    in
    {
      chartsDerivations = self.charts { inherit pkgs; };

      packages.helmupdater = pkgs.poetry2nix.mkPoetryApplication {
        python = pkgs.python310;
        projectDir = ./.;
      };

      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixpkgs-fmt
          poetry
          python310Packages.autopep8
          (pkgs.poetry2nix.mkPoetryEnv {
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
