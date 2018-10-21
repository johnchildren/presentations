{ stdenv, pandoc, texlive, revealjs }:

stdenv.mkDerivation rec {
  name = "slackbot-presentation";
  src = ./.;

  buildPhase = ''
    pandoc -t beamer -V theme:Rochester -V colortheme:lily -o ${name}.pdf slides.md
    pandoc -t revealjs -s -V theme=black -o ${name}.html slides.md
  '';

  installPhase = ''
    mkdir -p $out
    cp ${name}.pdf $out
    cp ${name}.html $out
    cp -r images/ $out
    cp -r ${revealjs}/reveal.js/ $out
  '';

  buildInputs = [ texlive pandoc revealjs ];
}
