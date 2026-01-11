;; Update user-emacs-directory to use a non store location, so that packages may write there
;; thanks https://github.com/jordanisaacs/emacs-config/blob/3854525333a886c53a1dc966e0b4bb09a088e9fb/init.org?plain=1#L39-L48
(setq user-emacs-directory (expand-file-name "emacs/" (getenv "XDG_STATE_HOME")))
(setq custom-file (locate-user-emacs-file "custom.el"))


(use-package use-package-core
  :custom
  (use-package-verbose t)
  (use-package-enable-imenu-support t)
  (use-package-compute-statistics t)
  (use-package-always-defer t))

(use-package which-key
  :hook (after-init . which-key-mode))

(let ((remaps '((c-mode . c-ts-mode)
                (c++-mode . c++-ts-mode)
                (c-or-c++-mode . c-or-c++-ts-mode)
                (java-mode . java-ts-mode)
                (python-mode . python-ts-mode))))  
  (dolist (remap remaps)
    (add-to-list 'major-mode-remap-alist remap)))

(use-package display-line-numbers
  :custom
  (display-line-numbers-width 3)
  :hook prog-mode)

(use-package elec-pair
  :init (setq electric-pair-inhibit-predicate 'electric-pair-conservative-inhibit)
  :hook (prog-mode . electric-pair-mode)
  (prog-mode . (lambda ()
		 (add-hook 'before-save-hook 'eglot-format nil t))))

(use-package which-func
  :hook (prog-mode . which-function-mode))

(use-package eglot
  :bind 
  (:map eglot-mode-map
	("C-c l a" . eglot-code-actions)
	("C-c l r" . eglot-rename)
	("C-c l h" . eldoc)
	("C-c l f" . eglot-format)
	("C-c l F" . eglot-format-buffer)
	("C-c l R" . eglot-reconnect))
  :hook
  ((python-mode python-ts-mode) . eglot-ensure)
  ((java-mode java-ts-mode) . eglot-ensure)
  (nix-ts-mode . eglot-ensure)
  (c-ts-mode . eglot-ensure)
  (yaml-ts-mode . eglot-ensure)
  :custom
  (eglot-report-progress nil)
  :config
  ;; seems to not work in :custom for some reason
  (setq-default eglot-workspace-configuration 
		'(:nixd ( :nixpkgs (:expr "import <nixpkgs> { }")
			  :formatting (:command ["alejandra"]))))
  (add-to-list 'eglot-server-programs
	       '(c-ts-mode . ("clangd"
			      "--all-scopes-completion"
                              "--background-index"
                              "--clang-tidy"
                              "--cross-file-rename"
                              "--header-insertion=iwyu"
                              "--enable-config"
                              "-j=5"
                              "--pch-storage=memory"
			      :initializationOptions
			      (:formatting (:command ["clang-format"])))))
  (add-to-list 'eglot-server-programs
	       '((python-mode python-ts-mode) . ("basedpyright-langserver" "--stdio")))
  (add-to-list 'eglot-server-programs
	       '((java-mode java-ts-mode) . ("jdtls")))
  (add-to-list 'eglot-server-programs
	       '(yaml-ts-mode . ("yaml-language-server" "--stdio")))
  (add-to-list 'eglot-server-programs '((php-mode) . ("intelephense" "--stdio"))))

(use-package php-mode
  :config
  (php-mode-coding-style 'psr2))
  
(use-package eglot-booster
  :after eglot
  :hook (after-init . eglot-booster-mode))

(use-package flymake
  :bind (:map flymake-mode-map
              ("C-c e b" . flymake-show-buffer-diagnostics)
              ("C-c e p" . flymake-show-project-diagnostics)
              ("C-c e n" . flymake-goto-next-error)
              ("C-c e p" . flymake-goto-prev-error)
              ("C-c e v" . flymake-running-backends)))

(use-package corfu
  :init
  (defun my/eglot-capf ()
    (setq-local completion-at-point-functions
                (cons (cape-capf-super
                       #'cape-file
                       #'eglot-completion-at-point)
                      completion-at-point-functions)))
  :custom
  (corfu-auto t)          ;; Enable auto completion
  (corfu-auto-prefix 2)
  (corfu-cycle t)           ;; Enable cycling for `corfu-next/previous'
  (corfu-preselect 'prompt) ;; Always preselect the prompt
  (corfu-popupinfo-delay '(0.5 . 0.5))

  ;; Use TAB for cycling, default is `corfu-complete'.

  :hook
  (eglot-managed-mode . my/eglot-capf)
  (after-init . global-corfu-mode)
  (after-init . corfu-history-mode)
  (after-init . corfu-popupinfo-mode))
  
(use-package completion-preview
  :bind (:map completion-preview-active-mode-map
              ("M-f" . #'completion-preview-insert))
  :custom
  (completion-preview-minimum-symbol-length 2)
  :hook (after-init . global-completion-preview-mode))


(use-package cape
  :bind ("C-c p" . cape-prefix-map))

(defvar-keymap my/windows-prefix-map
  :doc "Keymap for common window operations.")
(keymap-global-set "C-c w" my/windows-prefix-map)

(use-package catppuccin-theme
  :demand t
  :config
  (load-theme 'catppuccin :no-confirm))

(use-package pixel-scroll
  ;; scroll settings stolen from https://github.com/SophieBosio/.emacs.d?tab=readme-ov-file#scrolling
  :custom
  (scroll-conservatively 101)
  (mouse-wheel-follow-mouse 't)
  (mouse-wheel-progressive-speed nil)
  :hook
  (after-init . pixel-scroll-mode)
  (after-init . pixel-scroll-precision-mode))

(use-package emacs
  :bind
  (:map my/windows-prefix-map
	("m" . 'minimize-window)
	("M" . 'maximize-window))
  :custom
  (tab-always-indent 'complete)
  (kill-buffer-delete-auto-save-files t)

  ;; Emacs 30 and newer: Disable Ispell completion function.
  ;; Try `cape-dict' as an alternative.
  (text-mode-ispell-word-completion nil)
  
  ;; Hide commands in M-x which do not apply to the current mode. 
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Enable context menu. `vertico-multiform-mode' adds a menu in the minibuffer
  ;; to switch display modes.
  (context-menu-mode t)
  ;; Support opening new minibuffers from inside existing minibuffers.
  (enable-recursive-minibuffers t)
  ;; Do not allow the cursor in the minibuffer prompt
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt))
  :config
  (tool-bar-mode -1)
  (menu-bar-mode -1))



(use-package faces
  :demand t
  :custom-face
  (default ((t :family "0xProto" :height 130)))
  (variable-pitch ((t :family "Inter" :height 1.2))))

(use-package exec-path-from-shell
  :config
  (exec-path-from-shell-initialize))

(use-package org
  :hook
  (org-mode . variable-pitch-mode)
  :custom
  (org-hide-emphasis-markers t)
  :config
  (add-to-list 'org-export-backends 'md)
  :custom-face
  (org-table ((t :inherit 'fixed-pitch)))
  (org-code ((t :inherit 'fixed-pitch)))
  (org-indent ((t (:inherit (org-hide fixed-pitch)))))
  (org-block ((t :inherit 'fixed-pitch)))
  (org-checkbox ((t :inherit 'fixed-pitch)))
  (org-latex-and-related ((t (:inherit 'fixed-pitch)))))

(use-package kind-icon :after corfu
    :defines corfu-margin-formatters
    :functions kind-icon-margin-formatter
    :custom (kind-icon-default-face 'corfu-default)
    :config (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

(use-package org-modern
  :hook (org-mode . org-modern-mode))

(use-package ox-pandoc
  :after ox
  :init
  (add-to-list 'org-export-backends 'pandoc))

(use-package engrave-faces
  :after ox-latex
  :config
  (setq org-latex-src-block-backend 'engraved))

(use-package magit)

(use-package dired
  :custom
  (dired-dwim-target t)
  (dired-listing-switches "-AGhlv --group-directories-first --time-style=long-iso")
  (dired-kill-when-opening-new-dired-buffer t))

(use-package nix-ts-mode
  :mode (("\\.nix\\'" . nix-ts-mode)))

(use-package eldoc-box
  :hook (eglot-managed-mode . eldoc-box-hover-mode)
  :custom-face
  (eldoc-box-body ((t (:family "Sans Serif")))))



(use-package ox-latex
  :custom
  (org-latex-compiler "lualatex")
  (org-preview-latex-default-process 'luasvg)
  :config
  (let ((luasvg
	 '(luasvg
           :programs ("lualatex" "dvisvgm")
           :description "dvi > svg"
           :message "you need to install lualatex and dvisvgm."
           :image-input-type "dvi"
           :image-output-type "svg"
           :image-size-adjust (1.0 . 1.0)
           :latex-compiler ("lualatex --interaction=nonstopmode --shell-escape --output-format=dvi --output-directory=%o %f")
           :image-converter ("dvisvgm %f -n -b min -c %S -o %O"))))
    (add-to-list 'org-preview-latex-process-alist luasvg)))

(use-package files
  :custom
  (backup-directory-alist `(("." . ,(concat user-emacs-directory "backups"))))
  (delete-old-versions t)
  (kept-new-versions 6)
  (kept-old-versions 2))

(use-package envrc
  :hook (after-init . envrc-global-mode))

(use-package marginalia
  :hook (after-init . marginalia-mode))

;; Enable Vertico.
(use-package vertico
  ;; :custom
  ;; (vertico-scroll-margin 0) ;; Different scroll margin
  ;; (vertico-count 20) ;; Show more candidates
  ;; (vertico-resize t) ;; Grow and shrink the Vertico minibuffer
  ;; (vertico-cycle t) ;; Enable cycling for `vertico-next/previous'
  :init
  :hook
  (after-init . vertico-mode))

(use-package orderless
  :custom
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (orderless-style-dispatchers '(+orderless-consult-dispatch orderless-affix-dispatch))
  ;; (orderless-component-separator #'orderless-escapable-split-on-space)
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-category-defaults nil) ;; Disable defaults, use our settings
  (completion-pcm-leading-wildcard t)) ;; Emacs 31: partial-completion behaves like substring

;; Persist history over Emacs restarts. 
(use-package savehist
  :hook
  (after-init . savehist-mode))

(use-package em-term
  :config
  (dolist (el '("nix"
		"nix-build"
		"nixos-rebuild"
		"rbld"
		"deploy"))
    (add-to-list 'eshell-visual-commands el)))

(use-package org-appear
  :hook
  (org-mode . org-appear-mode)
  :custom
  (org-appear-autoemphasis t)
  (org-appear-autolinks t)
  (org-appear-autosubmarkers t)
  (org-appear-inside-latex t))


(use-package eat
  :hook
  (eshell-load . eat-eshell-mode)
  (eshell-load . eat-eshell-visual-command-mode))
