{ stdenv, pandoc, texlive, haskellPackages }:

stdenv.mkDerivation rec {
  name = "dbextensions-presentation";
  src = ./.;

  buildPhase = ''
    pandoc -t beamer -o ${name}.pdf slides.md
  '';

  installPhase = ''
    mkdir -p $out
    cp ${name}.pdf $out
  '';

  buildInputs = [ texlive pandoc haskellPackages.pandoc-citeproc ];
}
