let
  pkgs = import ./nix/nixpkgs-pinned.nix {};
in with pkgs; let
  custom_texlive = texlive.combine {
    inherit (texlive)
    scheme-small
    noto
    mweights
    cm-super
    cmbright
    fontaxes
    listings
    hfbright
    beamer;
  };
  revealjs = callPackage ./nix/revealjs.nix {};
in buildEnv {
  name = "presentations";

  paths = let
    slackbot = callPackage ./talks/slackbot/default.nix { inherit revealjs; texlive = custom_texlive; };
    dbextensions = callPackage ./talks/dbextensions/default.nix { texlive = custom_texlive; };
  in [ slackbot dbextensions ];
}
