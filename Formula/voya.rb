class Voya < Formula
  desc "Local emulator of Fly.io's networking model"
  homepage "https://github.com/trendvidia/voya"
  # The git tag rather than a tarball: voya reads its version from the Go
  # toolchain's stamp, which needs the tagged checkout. A tarball build
  # would report (devel).
  url "https://github.com/trendvidia/voya.git",
      tag:      "v0.3.0",
      revision: "351b2becd43f2b2583691683beeaffd72da660ff"
  license "MIT"

  depends_on "go" => :build

  def install
    # CGO_ENABLED=0 is how voya ships: its Makefile pins it, because the
    # resolver behaviour voya has to prove differs in a cgo build. GOWORK=off
    # builds against the published sibling modules, as `go install` does,
    # rather than the workspace's unreleased checkouts.
    ENV["CGO_ENABLED"] = "0"
    ENV["GOWORK"] = "off"
    system "go", "build", *std_go_args, "./cmd/voya"
  end

  test do
    assert_equal "v#{version}", shell_output("#{bin}/voya version").strip

    # Start the real daemon on free ports, so a test cannot collide with a
    # voya already running, and ask it who it is.
    proxy_port = free_port
    dns_port = free_port
    registration_port = free_port
    (testpath/"config/voya.pxf").write <<~PXF
      proxy_port = #{proxy_port}
      dns_port = #{dns_port}
      registration_port = #{registration_port}
    PXF

    ENV["VOYA_CONFIG_DIR"] = (testpath/"config").to_s
    pid = spawn bin/"voya", "run"
    begin
      sleep 2
      assert_match "v#{version}", shell_output("#{bin}/voya status")
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
