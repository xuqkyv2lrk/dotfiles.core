;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 22 :weight 'regular))

(setq doom-theme 'catppuccin)
(setq catppuccin-flavor 'mocha)

(setq display-line-numbers-type nil)
(setq confirm-kill-emacs nil)

(setq auto-save-default t
      make-backup-files t)

(setq org-directory "~/notes/tome")

(after! doom-dashboard
  (setq +doom-dashboard-menu-sections (cl-subseq +doom-dashboard-menu-sections 0 2)))

(after! markdown-mode
  (setq markdown-hide-markup t))

(after! org (load! "org-config.el"))

(when (and (file-exists-p "~/custom-org-citeproc-export.csl")
           (file-exists-p "~/csl-locales/"))
  (use-package! org-ref
    :after org
    :config
    (setq org-ref-csl-default-style (expand-file-name "~/custom-org-citeproc-export.csl")
          org-cite-csl-locales-dir  (expand-file-name "~/csl-locales/"))))
