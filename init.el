; initialize straight.el
(defvar bootstrap-version)
(let ((bootstrap-file
	       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
            (bootstrap-version 6))
    (unless (file-exists-p bootstrap-file)
          (with-current-buffer
	            (url-retrieve-synchronously
		               "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
			                'silent 'inhibit-cookies)
		          (goto-char (point-max))
			        (eval-print-last-sexp)))
      (load bootstrap-file nil 'nomessage))

; install use-package 
(straight-use-package 'use-package)

; integrate straight.el with use-package
(use-package straight
	       :custom (straight-use-package-by-default t))

; https://debbugs.gnu.org/cgi/bugreport.cgi?bug=62762
(use-package org)

; follow symlinks in order for version control to work
(setq vc-follow-symlinks t)

; load literate config
(org-babel-load-file (expand-file-name (concat user-emacs-directory "README.org")))


