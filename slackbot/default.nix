{ stdenv, texlive, pandoc }:

stdenv.mkDerivation {
  name = "slackbot-presentation";
  src = ./.;

  buildPhase = ''
    pandoc -t beamer -V theme:Rochester -V colortheme:lily -o slides.pdf slides.md
  '';

  installPhase = ''
    mkdir -p $out
    cp slides.pdf $out
  '';

  buildInputs = [texlive pandoc];
}
