# trendvidia/homebrew-tap

Homebrew formulae for trendvidia projects.

## go-plus

[go-plus](https://github.com/trendvidia/go) is a fork of Go that adds
`-buildmode=plugin` on Windows and the `goplus` runtime API for the govm
JIT. It installs the same `go` and `gofmt` as Homebrew's `go`, so the two
conflict.

```sh
brew install trendvidia/tap/go
go version   # go version go1.27.2 darwin/arm64 (plus v1.27.2a)
```

Archives are published for darwin/arm64, linux/amd64 and linux/arm64.

### Updating to a new release

After `release-binaries` has attached the archives to the GitHub release:

```sh
./update-go.sh v1.27.2a
brew install --build-from-source ./Formula/go.rb && brew test go
```
