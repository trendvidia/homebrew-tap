# trendvidia/homebrew-tap

Homebrew formulae for trendvidia projects.

## go-plus

[go-plus](https://github.com/trendvidia/go) is a fork of Go that adds
`-buildmode=plugin` on Windows and the `goplus` runtime API for the govm
JIT. It installs alongside Homebrew's `go`, on the same machine.

```sh
brew install trendvidia/tap/go-plus
goplus version   # go version go1.27.3 darwin/arm64 (plus v1.27.3d)
```

Only `goplus` is linked. The fork's real `go` and `gofmt` stay in the keg,
and that directory is how a pipeline selects the fork:

```sh
export PATH="$(brew --prefix go-plus)/libexec/bin:$PATH"
go version   # the fork, for Makefiles, linters and scripts alike
```

Use `PATH` rather than `goplus` in pipelines: a script or tool that calls
`go` by name would otherwise get stock Go. `go version` is not proof
either, because it reports the binary even when `GOROOT` points elsewhere.
A build containing `import _ "goplus"` fails on anything but the fork.

Archives are published for darwin/arm64, linux/amd64 and linux/arm64.

### Updating to a new release

After `release-binaries` has attached the archives to the GitHub release:

```sh
./update-go.sh v1.27.3e
brew install --build-from-source trendvidia/tap/go-plus && brew test go-plus
```
