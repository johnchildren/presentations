let
  pkgs = import <nixpkgs> {};

  stdenv = pkgs.stdenv;
  fetchurl = pkgs.fetchurl;
  texlive = pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-small beamer; 
  };
  pandoc = pkgs.pandoc;
  revealjs = import ./revealjs.nix { inherit stdenv fetchurl; };
in rec {
  name = "presentations";

  slackbot = import ./slackbot/default.nix { inherit stdenv texlive pandoc revealjs; };
}
