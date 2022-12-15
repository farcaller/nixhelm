{
  description = "Nix-wrapped helm packages";

  inputs = {
    nix-kube-generators.url = "github:farcaller/nix-kube-generators";
  };

  outputs = { self, nixpkgs, nix-kube-generators }:
    let
      lib = (import nix-kube-generators { inherit nixpkgs; }).lib;
      repos = [ "prometheus-community" ];
    in
    {
      chartsMetadata = builtins.listToAttrs (map
        (name: {
          inherit name;
          value = import ./charts/${name};
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
