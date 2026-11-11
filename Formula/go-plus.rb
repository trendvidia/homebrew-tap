class GoPlus < Formula
  desc "Trendvidia \"plus\" fork of Go with extended -buildmode=plugin support"
  homepage "https://github.com/trendvidia/go"
  version "1.27.4"
  license "BSD-3-Clause"

  # Prebuilt toolchain archives from the release. macOS is arm64-only
  # (no Intel build is published); Linux covers arm64 and x86_64.
  on_macos do
    depends_on arch: :arm64
    on_arm do
      url "https://github.com/trendvidia/go/releases/download/v1.27.4/go1.27.4-plus.darwin-arm64.tar.gz"
      sha256 "9bc2c49f6d82534a625359780b82c77881c0c9d005379e0693b2fb03d357e80b"
    end
    # Never installed: depends_on above refuses an Intel Mac. `brew tap`
    # loads every formula as each OS/arch, though, and a formula with no
    # url on Intel macOS fails that check and aborts the whole tap.
    on_intel do
      url "https://github.com/trendvidia/go/releases/download/v1.27.4/go1.27.4-plus.darwin-arm64.tar.gz"
      sha256 "9bc2c49f6d82534a625359780b82c77881c0c9d005379e0693b2fb03d357e80b"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/trendvidia/go/releases/download/v1.27.4/go1.27.4-plus.linux-arm64.tar.gz"
      sha256 "daf4aecea6cd0b4fc99f1d3d7f810d5c7f2197f8081aaf171022464cd06dc08e"
    end
    on_intel do
      url "https://github.com/trendvidia/go/releases/download/v1.27.4/go1.27.4-plus.linux-amd64.tar.gz"
      sha256 "b207eef37f062b008d4ffe0c800497d7143906cfa36a6d4b61e9cc966edeb919"
    end
  end

  def install
    # The archive contains a top-level go/ tree (bin, pkg/tool, src, ...);
    # Homebrew strips it, so install the contents into libexec and expose
    # the tools. GOROOT is derived from the go binary's location.
    libexec.install Dir["*"]

    # Only `goplus` is linked, so this coexists with the stock `go` formula.
    # The real `go` and `gofmt` stay in libexec/bin, unlinked: pipelines put
    # that directory on PATH, the same shape as coreutils' libexec/gnubin.
    bin.install_symlink libexec/"bin/go" => "goplus"

    # Drop testdata carrying non-native binaries (avoids Linux patchelf
    # relocation over foreign objects), matching the upstream formula.
    rm_r(libexec/"src/debug/elf/testdata")
    rm_r(libexec/"src/runtime/pprof/testdata")
    rm_r(libexec/"src/debug/dwarf/testdata")
  end

  def caveats
    <<~EOS
      Only `goplus` is linked, so this installs alongside Homebrew's `go`.
      To make `go` and `gofmt` the fork, for a pipeline or a shell, run:
        export PATH="#{opt_libexec}/bin:$PATH"
    EOS
  end

  test do
    # Must be the fork toolchain, and must be THIS release. The old
    # assertion only checked for "(plus)", which any fork build satisfies,
    # so a stale url/sha pair would still have passed. The toolchain names
    # the release tag (PlusRelease in internal/goversion), so pin to it via
    # version.
    assert_match "(plus v#{version})", shell_output("#{bin}/goplus version")

    # Coexisting with the stock formula depends on this: linking `go` or
    # `gofmt` would collide with it in the prefix's bin.
    assert_equal ["goplus"], bin.children.map { |f| f.basename.to_s }

    # The name pipelines rely on must work too, and find the same GOROOT.
    assert_match "(plus v#{version})", shell_output("#{libexec}/bin/go version")
    assert_equal shell_output("#{libexec}/bin/go env GOROOT"), shell_output("#{bin}/goplus env GOROOT")

    (testpath/"hello.go").write <<~GO
      package main

      import "fmt"

      func main() {
          fmt.Println("Hello World")
      }
    GO

    system bin/"goplus", "fmt", "hello.go"
    assert_equal "Hello World\n", shell_output("#{bin}/goplus run hello.go")

    (testpath/"hello_cgo.go").write <<~GO
      package main

      /*
      #include <stdlib.h>
      #include <stdio.h>
      void hello() { printf("%s\\n", "Hello from cgo!"); fflush(stdout); }
      */
      import "C"

      func main() {
          C.hello()
      }
    GO

    with_env(CGO_ENABLED: "1") do
      assert_equal "Hello from cgo!\n", shell_output("#{bin}/goplus run hello_cgo.go")
    end
  end
end
