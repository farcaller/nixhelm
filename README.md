# nixhelm

This is a collection of helm charts in a nix-digestable format.

## Outputs

The flake has the following outputs:

`chartsMetadata.${repo}.${chart}` contains the metadata about a specific chart.

`chartsDerivations.${system}.${repo}.${chart}` contains the derivations producing the charts.

`charts { pkgs = ... }.${repo}.${chart}` a shortcut for the above that doesn't
depend on the nixpkgs input and allows to specify any nixpkgs.

The charts are updated from artifacthub.io.

## Adding new charts

Send in a pull request! As long as the chart is known to artifacthub, it will be
updated automatically.

## License

Apache-2.0
