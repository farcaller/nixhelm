# nixhelm

This is a collection of helm charts in a nix-digestable format.

## Outputs

The flake has the following outputs:

`chartsMetadata.${repo}.${chart}` contains the metadata about a specific chart.

`chartsDerivations.${system}.${repo}.${chart}` contains the derivations producing the charts.

`charts { pkgs = ... }.${repo}.${chart}` a shortcut for the above that doesn't
depend on the nixpkgs input and allows to specify any nixpkgs.

The charts are updated nightly.

## Using the cache

This repository and all the charts within are publicly cached at cachix as
[nixhelm](https://app.cachix.org/cache/nixhelm). Here's how you can quickly
enable it in your nix installation:

```
# without flakes
nix-env -iA cachix -f https://cachix.org/api/v1/install

# with flakes
nix profile install nixpkgs#cachix

# then enable the cache
cachix use nixhelm
```

Alternatively, manually add this to `/etc/nix/nix.conf`:

```
substituters = https://cache.nixos.org https://nixhelm.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nixhelm.cachix.org-1:esqauAsR4opRF0UsGrA6H3gD21OrzMnBBYvJXeddjtY=
```

## Adding new charts

Clone the repository and run the following command from within it:

```
nix run .#helmupdater -- init $REPO $REPO_NAME/$CHART_NAME --commit
```

Where `REPO` is the url to the chart, `REPO_NAME` is the short name for the
repository and the `CHART_NAME` is the name of the chart in the repository.

For example, if you want to add [bitnami's
nginx](https://github.com/bitnami/charts/tree/main/bitnami/nginx), run the
following command:

```
nix run .#helmupdater -- init "https://charts.bitnami.com/bitnami" bitnami/nginx --commit
```

The command will create the properly formatted commit that you can then submit
as a pull request to the repo.

## License

Apache-2.0
