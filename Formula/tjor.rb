class Tjor < Formula
  desc "Run AI coding agents inside a portable, fail-closed container cage"
  homepage "https://github.com/bjorges/tjor"
  url "https://github.com/bjorges/tjor/archive/refs/tags/v0.6.0.tar.gz"
  sha256 "8f1aa79ca3d54d4d39d92a20d5c288f82f99fa6226128f0ac0b182fe73f2c225"
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
