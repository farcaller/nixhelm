{
  description = "Nix-wrapped helm packages";

  inputs = {
    nix-kube-generators.url = "github:farcaller/nix-kube-generators";
  };

  outputs = { nixpkgs, flake-utils, nix-kube-generators, ... }:
    let
      repos = builtins.attrNames (builtins.readDir ./charts);
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        kubelib = nix-kube-generators.lib { inherit pkgs; };
      in
      rec {
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
          repos);
        charts = builtins.mapAttrs
          (
            reponame: charts:
              builtins.mapAttrs (chartname: kubelib.downloadHelmChart) charts
          )
          chartsMetadata;
      }
    );
}
