# bjorges/homebrew-tap

Personal Homebrew tap.

```console
$ brew install bjorges/tap/tjor
```

| Formula | What |
|---|---|
| [`tjor`](Formula/tjor.rb) | Run AI coding agents inside a portable, fail-closed container cage — [bjorges/tjor](https://github.com/bjorges/tjor) |

## How the formula is kept current

`tjor` follows [bjorges/tjor](https://github.com/bjorges/tjor)'s releases by
itself: `.github/workflows/update-tjor.yml` runs every six hours, and on
demand (`gh workflow run update-tjor.yml -R bjorges/homebrew-tap`, right after
a release; a specific tag can be named and a dry run requested). A run first
asks, with one API call, whether the formula is behind the latest release; if
not, it ends there in seconds. If it is, `scripts/update-tjor.sh` downloads
the tag's tarball, checks it is the tagged tree, rewrites the formula's `url`
and `sha256`, and the workflow installs and tests the formula with Homebrew
before it commits `tjor X.Y.Z` and pushes. A failed step leaves the tap
untouched and the run red. It never downgrades and never rewrites a version
already committed with a different checksum.

Residuals, stated plainly: the tap can lag a release by up to six hours unless
the workflow is run by hand; GitHub disables a scheduled workflow in a
repository without commits for 60 days, so a long quiet spell needs one click
under Actions to re-enable it (the manual run keeps working); the formula's
`depends_on` lines still change by hand.
