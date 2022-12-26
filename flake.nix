{
  description = "Nix-wrapped helm packages";

  inputs = {
    nix-kube-generators.url = "github:farcaller/nix-kube-generators";
  };

  outputs = { self, nixpkgs, nix-kube-generators }:
    let
      lib = (import nix-kube-generators { inherit nixpkgs; }).lib;
      repos = builtins.attrNames (builtins.readDir ./charts);
    in
    {
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
            builtins.mapAttrs (chartname: lib.downloadHelmChart) charts
        )
        self.chartsMetadata;
    };
}
