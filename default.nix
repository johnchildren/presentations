let
  pkgs = import <nixpkgs> {};
in rec {
  name = "presentations";

  stdenv = pkgs.stdenv;
  texlive = pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-medium beamer; 
  };
  pandoc = pkgs.pandoc;

  slackbot = import ./slackbot/default.nix { inherit stdenv texlive pandoc; };
}
