class Tjor < Formula
  desc "Run AI coding agents inside a portable, fail-closed container cage"
  homepage "https://github.com/bjorges/tjor"
  url "https://github.com/bjorges/tjor/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "f211a823096c2d29356aba750aeb6137edb50af7d4d2d7cc215330bf1728ee27"
  license "MIT"

  depends_on "bash"
  depends_on "python@3.13"

  def install
    libexec.install Dir["*"]
    bin.install_symlink libexec/"bin/tjor"
  end

  def caveats
    <<~EOS
      tjor drives Docker: it needs a running engine with compose v2
      (colima + docker + docker-compose, or Docker Desktop).

      Verify your host and runtime:
        tjor doctor
      Prove the boundary holds on YOUR runtime:
        tjor conformance
      Then, from any repo:
        tjor run
    EOS
  end

  test do
    assert_match "fail-closed container cage", shell_output("#{bin}/tjor help")
  end
end
