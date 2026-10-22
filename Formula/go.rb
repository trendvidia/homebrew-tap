class Go < Formula
  desc "Trendvidia \"plus\" fork of Go with extended -buildmode=plugin support"
  homepage "https://github.com/trendvidia/go"
  version "1.27.3c"
  license "BSD-3-Clause"

  # Prebuilt toolchain archives from the release. macOS is arm64-only
  # (no Intel build is published); Linux covers arm64 and x86_64.
  on_macos do
    on_arm do
      url "https://github.com/trendvidia/go/releases/download/v1.27.3c/go1.27.3-plus.darwin-arm64.tar.gz"
      sha256 "dca16c249ce296cfd94e2234aadb416ebb50633090a78c63a6c54b6c559baac8"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/trendvidia/go/releases/download/v1.27.3c/go1.27.3-plus.linux-arm64.tar.gz"
      sha256 "262ef27c39460012f4135abcbc2c1b505abd576d1ee2fb441b03fe78af3e6bb2"
    end
    on_intel do
      url "https://github.com/trendvidia/go/releases/download/v1.27.3c/go1.27.3-plus.linux-amd64.tar.gz"
      sha256 "c78b9c4d6ce962a5a92b287f5d65cfb8d5d3b4053d79d37cff2dfffc96ba70ff"
    end
  end

  # Installs the same `go` and `gofmt` binaries as the upstream formula.
  conflicts_with "go", because: "both install `go` and `gofmt` binaries"

  def install
    # The archive contains a top-level go/ tree (bin, pkg/tool, src, ...);
    # Homebrew strips it, so install the contents into libexec and expose
    # the tools. GOROOT is derived from the go binary's location.
    libexec.install Dir["*"]
    bin.install_symlink Dir[libexec/"bin/*"]

    # Drop testdata carrying non-native binaries (avoids Linux patchelf
    # relocation over foreign objects), matching the upstream formula.
    rm_r(libexec/"src/debug/elf/testdata")
    rm_r(libexec/"src/runtime/pprof/testdata")
    rm_r(libexec/"src/debug/dwarf/testdata")
  end

  test do
    # Must be the fork toolchain, and must be THIS release. The old
    # assertion only checked for "(plus)", which any fork build satisfies,
    # so a stale url/sha pair would still have passed. The toolchain names
    # the release tag (PlusRelease in internal/goversion), so pin to it via
    # version.
    assert_match "(plus v#{version})", shell_output("#{bin}/go version")

    (testpath/"hello.go").write <<~GO
      package main

      import "fmt"

      func main() {
          fmt.Println("Hello World")
      }
    GO

    system bin/"go", "fmt", "hello.go"
    assert_equal "Hello World\n", shell_output("#{bin}/go run hello.go")

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
      assert_equal "Hello from cgo!\n", shell_output("#{bin}/go run hello_cgo.go")
    end
  end
end
