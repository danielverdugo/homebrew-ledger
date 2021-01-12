class Ledger < Formula
  desc "Command-line, double-entry accounting tool (built with Python Support)"
  homepage "https://ledger-cli.org"
  url "https://github.com/ledger/ledger/archive/v3.2.1.tar.gz"
  sha256 "92bf09bc385b171987f456fe3ee9fa998ed5e40b97b3acdd562b663aa364384a"

  bottle do
    root_url "https://github.com/danielverdugo/homebrew-ledger/releases/download/ledger-3.2.1"
    sha256 "3a5631a1ce9e54c750036ab89e9f5f534b5d7bb5f8a4ec55cd3f9165078f6086" => :big_sur
  end

  depends_on "cmake" => :build
  depends_on "boost"
  depends_on "boost-python3"
  depends_on "gmp"
  depends_on "mpfr"
  depends_on "python@3.9"

  def install
    ENV.cxx11
    ENV.prepend_path "PATH", Formula["python@3.9"].opt_libexec/"bin"

    args = %W[
      --jobs=#{ENV.make_jobs}
      --output=build
      --prefix=#{prefix}
      --boost=#{Formula["boost"].opt_prefix}
      --python
      --
      -DBUILD_DOCS=1
      -DBUILD_WEB_DOCS=1
      -DBoost_NO_BOOST_CMAKE=ON
      -DPython_FIND_VERSION_MAJOR=3
    ] + std_cmake_args

    python_formula_version = Formula["python@3.9"].version
    python_formula_revision = Formula["python@3.9"].revision
    python_framework = "#{HOMEBREW_PREFIX}/Cellar/python@3.9/#{python_formula_version}_#{python_formula_revision}/Frameworks/Python.framework/Versions/3.9"
    site_packages_dir = lib/"python3.9/site-packages"

    system "./acprep", "opt", "make", *args

    inreplace "build/src/cmake_install.cmake", "#{python_framework}/lib/python3.9/site-packages", "#{site_packages_dir}"

    system "./acprep", "opt", "make", "doc", *args
    system "./acprep", "opt", "make", "install", *args

    (pkgshare/"examples").install Dir["test/input/*.dat"]
    pkgshare.install "contrib"
    elisp.install Dir["lisp/*.el", "lisp/*.elc"]
    bash_completion.install pkgshare/"contrib/ledger-completion.bash"
  end

  test do
    balance = testpath/"output"
    system bin/"ledger",
      "--args-only",
      "--file", "#{pkgshare}/examples/sample.dat",
      "--output", balance,
      "balance", "--collapse", "equity"
    assert_equal "          $-2,500.00  Equity", balance.read.chomp
    assert_equal 0, $CHILD_STATUS.exitstatus
  end
end
