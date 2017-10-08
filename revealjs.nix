{ stdenv, fetchurl }:

stdenv.mkDerivation {
  name = "reveal-js-3.5";
  src = fetchurl {
    url = "https://github.com/hakimel/reveal.js/archive/3.5.0.tar.gz";
    sha256 = "1bfcvzz023s5kbcnzz0h9zil069x58lazrc5l58shhagw44qiiaf";
  };
  installPhase = ''
    mkdir -p $out/reveal.js/
    cp -r {css,js,lib,plugin} $out/reveal.js/
  '';
}
