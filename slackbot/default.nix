{ stdenv, pandoc, texlive, revealjs }:

stdenv.mkDerivation {
  name = "slackbot-presentation";
  src = ./.;

  buildPhase = ''
    pandoc -t beamer -V theme:Rochester -V colortheme:lily -o slides.pdf slides.md
    pandoc -t revealjs -s -V theme=black -o slides.html slides.md
  '';

  installPhase = ''
    mkdir -p $out
    cp slides.pdf $out
    cp slides.html $out
    cp -r ${revealjs}/reveal.js/ $out
  '';

  buildInputs = [texlive pandoc revealjs];
}
