{
  emacs,
  emacsPackagesFor,
  symlinkJoin,
  makeWrapper,
  texliveMedium,
  emacs-lsp-booster,
  alejandra,
  nixd,
  clang-tools,
  basedpyright,
  jdt-language-server,
  yaml-language-server,
  typescript-language-server,
  biome,
  unzip,
  gzip,
  bzip2,
  xz,
  zstd,
  p7zip,
  gnutar,
  pandoc,
  plantuml,
  _0xproto,
  nerd-fonts,
  glibcInfo,
  texinfo,
}: let
  emacsWithPackages =
    (emacsPackagesFor emacs).emacsWithPackages
    (
      epkgs:
        with epkgs; [
          diminish
          catppuccin-theme
          corfu
          envrc
          exec-path-from-shell
          ultra-scroll
          org-appear
          org-modern
          ox-pandoc
          magit
          eldoc-box
          kind-icon
          cape
          eglot-booster
          marginalia
          vertico
          orderless
          eat
          engrave-faces
          gcmh

          # modes
          php-mode
          nix-ts-mode
          web-mode
          json-mode
          plantuml-mode
          (epkgs.treesit-grammars.with-grammars (grammars:
            with grammars; [
              tree-sitter-nix
              tree-sitter-c
              tree-sitter-cpp
              tree-sitter-python
              tree-sitter-java
              tree-sitter-yaml
              tree-sitter-typescript
              tree-sitter-tsx
            ]))
        ]
    );

  # This is here so that instead of having symlinked info pages from the emacs package, we have a derivation with the files directly copied.
  # This is necessary because we will be using `symlinkJoin` to put all the info pages together
  emacsWithPackages' = symlinkJoin {
    inherit (emacsWithPackages) name;
    paths = [emacsWithPackages];
    postBuild = ''
      original_info=$(realpath $out/share/info)
      rm $out/share/info
      cp -rs "$original_info" $out/share/info
    '';
  };

  # https://wiki.nixos.org/wiki/TexLive#Combine_Sets
  tex = texliveMedium.withPackages (
    ps:
      with ps; [
        xetex
        dejavu
        fontspec
        dvisvgm
        dvipng
        wrapfig
        amsmath
        ulem
        hyperref
        capt-of
        tcolorbox
        fvextra
        babel-french
        upquote
        pdfcol
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

      typescript-language-server
      biome

      unzip
      gzip
      bzip2
      xz
      zstd
      p7zip
      gnutar
      plantuml

      tex
      pandoc
      glibcInfo
    ];
    extraOutputsToInstall = ["man" "doc" "info"];
  };

  emacsWrapped = symlinkJoin {
    name = "emacs-wrapped";
    paths = [emacsWithPackages' emacsDeps];

    nativeBuildInputs = [makeWrapper texinfo];

    postBuild = ''
      shopt -s nullglob
      for i in $out/share/info/*.info $out/share/info/*.info.gz; do
              install-info $i $out/share/info/dir
      done

      wrapProgram $out/bin/emacs \
        --prefix INFOPATH : $out/share/info \
        --add-flags --init-directory="${../config}"
    '';
  };
in
  emacsWrapped
