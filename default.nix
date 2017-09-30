let
  pkgs = import <nixpkgs> {};

  stdenv = pkgs.stdenv;
  texlive = pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-small beamer; 
  };
  pandoc = pkgs.pandoc;
in rec {
  name = "presentations";

  slackbot = import ./slackbot/default.nix { inherit stdenv texlive pandoc; };
}
