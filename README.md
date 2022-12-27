# nixhelm

This is a collection of helm charts in a nix-digestable format.

## Outputs

The flake has two primary outputs:

`chartsMetadata.${system}.${repo}.${chart}` contains the metadata about a specific chart.

`charts.${system}.${repo}.${chart}` contains derivation that produces the chart.

The charts are updated from artifacthub.io.

## Adding new charts

Send in a pull request! As long as the chart is known to artifacthub, it will be
updated automatically.

## License

Apache-2.0
