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
            builtins.mapAttrs (chartname: kubelib.downloadHelmChart) charts
        )
        self.chartsMetadata;
  } // flake-utils.lib.eachDefaultSystem (system: { chartsDerivations = self.charts { pkgs = nixpkgs.legacyPackages.${system}; }; });
}
