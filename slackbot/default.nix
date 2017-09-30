{ stdenv, texlive, pandoc }:

stdenv.mkDerivation {
  name = "slackbot-presentation";
  src = ./.;

  buildInputs = [texlive pandoc];
}
