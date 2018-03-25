# https://discourse.brew.sh/t/convert-formulae-manticoresearch-is-a-community-focused-fork-of-sphinxsearch-made-by-sphinx-insiders/1258
class Manticore < Formula
  # "Manticore, a Sphinxsearch drop-in replacement with same defaults. Install. Stop sphinxsearch; rebuild indexes and start manticore. Done!"
  desc "Full-text search engine (forked from sphinxsearch 2017)"
  homepage "https://manticoresearch.com/"
  # documentation "http://docs.manticoresearch.com/latest/html/"

  url "https://github.com/manticoresoftware/manticore/releases/download/2.5.1/manticore-2.5.1-171123-b751d2b-release.tar.gz"
  sha256 "499332efda582a9d091045a88c3260aea7ac8812b299b5e03810becdbc53b2ac"
  head "https://github.com/manticoresoftware/manticore.git"

  bottle do
    sha256 "b890cf523db9777c7d125842fd6b0a53fe9a7a5a4cb816389ba6f5ee6483c78d" => :high_sierra
    sha256 "55ce34bdedf13946fa614bde50839d93135eae720f1021e2c87807d04515ab18" => :sierra
    sha256 "c75e018d69afb7d3cb662ebd129af67607d47f7b7f71ce8ea95be75d66dc502d" => :el_capitan
    sha256 "f89b43df8735d295a55c74f18d6af4a1a10b9f3ae81df69713c27f9240f78d14" => :yosemite
    sha256 "4ec1f1ea71e17b9e924e9f36747d7184114463640f100022cdbb46202e46261f" => :mavericks
  end

  option "with-mysql", "Force compiling against MySQL"
  option "with-postgresql", "Force compiling against PostgreSQL"
  option "with-id64", "Force compiling with 64-bit ID support"

  depends_on "re2" => :optional
  depends_on :mysql => :optional
  depends_on :postgresql => :optional
  depends_on "openssl" if build.with? "mysql"

  resource "stemmer" do
    url "https://github.com/snowballstem/snowball.git",
        :revision => "9b58e92c965cd7e3208247ace3cc00d173397f3c"
  end

  fails_with :clang do
    build 421
    cause "sphinxexpr.cpp:1802:11: error: use of undeclared identifier 'ExprEval'"
  end

  needs :cxx11 if build.with? "re2"

  def install
    # if build.with? "re2"
    #   ENV.cxx11
    #   # Fix "error: invalid suffix on literal" and "error:
    #   # non-constant-expression cannot be narrowed from type 'long' to 'int'"
    #   # Upstream issue from 7 Dec 2016 http://sphinxsearch.com/bugs/view.php?id=2578
    #   ENV.append "CXXFLAGS", "-Wno-reserved-user-defined-literal -Wno-c++11-narrowing"
    # end

    resource("stemmer").stage do
      system "make", "dist_libstemmer_c"
      system "tar", "xzf", "dist/libstemmer_c.tgz", "-C", buildpath
    end

    # defaults are:
    #   CMAKE_BUILD_TYPE=RelWithDebInfo, USE_BISON, USE_FLEX, WITH_STEMMER (bundled libstemmer_c/),
    #   WITH_RE2 (bundled libre2/),
    args = %W[
      -DCMAKE_INSTALL_PREFIX=#{prefix}
      --localstatedir=#{var}
      -D WITH_STEMMER=ON
      -D WITH_ZLIB=ON
    ]
    # --disable-dependency-tracking

    # args << "--enable-id64" if build.with? "id64"

    # if build.with? "re2"
      args << "-D WITH_RE2=1"
    # else
    #   args << "-D WITH_RE2=0"
    # end

    if build.with? "mysql"
      args << "-D WITH_MYSQL=1"
    else
      args << "-D WITH_MYSQL=0"
    end

    if build.with? "postgresql"
      args << "-D WITH_PGSQL=1"
    else
      args << "-D WITH_PGSQL=0"
    end

    args << '.'
    p "cmake", *args
    p Dir.pwd
  STDIN.read
    system "cmake", *args
    system "make", "-j4 install"
  end

  def caveats; <<~EOS
    Manticore forked away from Sphinx search in 2017, with API compatibility for 2.x versions. #semver

    Manticore has been compiled with libstemmer (snowballstem/snowball.git @ 9b58e9) support.

    To use non-RT indexes, you must have mySQL or Postgres. Handy install commands:
      brew install mysql # For MySQL server.
      brew install mysql-connector-c # For MySQL client libraries only.
      brew install postgresql # For PostgreSQL server.

    These are not strict dependencies, so you'll have to pick and install these yourself.
    EOS
  end

  test do
    system bin/"searchd", "--help"
  end
end
