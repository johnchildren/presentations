{ stdenv, texlive, pandoc }:

stdenv.mkDerivation {
  name = "slackbot-presentation";
  src = ./.;

  buildPhase = ''
    pandoc -t beamer --highlight-style=pygments -H theme.tex -o slides.pdf slides.md
  '';

  installPhase = ''
    mkdir -p $out
    cp slides.pdf $out
  '';

  buildInputs = [texlive pandoc];
}
