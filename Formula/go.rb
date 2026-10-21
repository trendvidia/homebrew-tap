class Go < Formula
  desc "Trendvidia \"plus\" fork of Go with extended -buildmode=plugin support"
  homepage "https://github.com/trendvidia/go"
  version "1.27.3a"
  license "BSD-3-Clause"

  # Prebuilt toolchain archives from the release. macOS is arm64-only
  # (no Intel build is published); Linux covers arm64 and x86_64.
  on_macos do
    on_arm do
      url "https://github.com/trendvidia/go/releases/download/v1.27.3a/go1.27.3-plus.darwin-arm64.tar.gz"
      sha256 "6c930bdc53e188b1bbdfa3bf938906be89e5123a4a0897bb7898d1117299c8e3"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/trendvidia/go/releases/download/v1.27.3a/go1.27.3-plus.linux-arm64.tar.gz"
      sha256 "f15a6b23c29f8f36a6fc5a3ab50b17081abfb73eb194bc0819571b8692bcca9f"
    end
    on_intel do
      url "https://github.com/trendvidia/go/releases/download/v1.27.3a/go1.27.3-plus.linux-amd64.tar.gz"
      sha256 "ca856ca85a8bfd872ad2c25e780b6ef108b015aa60afd084b58bfb94b49ffc08"
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
    # so a stale url/sha pair would still have passed. forkVersionMarker in
    # the toolchain names the release tag, so pin to it via version.
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
