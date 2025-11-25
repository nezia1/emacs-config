{
  emacs,
  emacsPackagesFor,
  symlinkJoin,
  makeWrapper,
  texliveBasic,
  emacs-lsp-booster,
  alejandra,
  nixd,
  clang-tools,
  basedpyright,
  jdt-language-server,
  yaml-language-server,
  unzip,
  gzip,
  bzip2,
  xz,
  zstd,
  p7zip,
  gnutar,
  _0xproto,
  nerd-fonts,
}: let
  emacsWithPackages = (emacsPackagesFor emacs).emacsWithPackages (
    epkgs:
      with epkgs; [
        catppuccin-theme
        corfu
        envrc
        exec-path-from-shell
        ultra-scroll
        org-appear
        org-modern
        magit
        eldoc-box
        kind-icon
        cape
        eglot-booster
        marginalia

        # modes
        nix-ts-mode
        (epkgs.treesit-grammars.with-grammars (grammars:
          with grammars; [
            tree-sitter-nix
            tree-sitter-c
            tree-sitter-cpp
            tree-sitter-python
            tree-sitter-java
            tree-sitter-yaml
          ]))
      ]
  );

  # https://wiki.nixos.org/wiki/TexLive#Combine_Sets
  tex = texliveBasic.withPackages (
    ps:
      with ps; [
        xetex
        dejavu
        fontspec
        dvisvgm
        dvipng # for preview and export as html
        wrapfig
        amsmath
        ulem
        hyperref
        capt-of
      ]
  );

  emacsDeps = symlinkJoin {
    name = "emacs-deps";
    paths = [
      _0xproto
      nerd-fonts.symbols-only

      emacs-lsp-booster
      alejandra
      nixd
      clang-tools
      basedpyright
      jdt-language-server
      yaml-language-server

      unzip
      gzip
      bzip2
      xz
      zstd
      p7zip
      gnutar

      tex
    ];
  };

  emacsWrapped = symlinkJoin {
    name = "emacs-wrapped";
    paths = [emacsWithPackages];
    nativeBuildInputs = [makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/emacs \
        --prefix PATH : ${emacsDeps}/bin \
        --prefix INFOPATH : $out/share/info
    '';
  };
in
  emacsWrapped
