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

(map! :leader
      (:prefix ("n" . "notes")
       :desc "Find node"          "f" #'org-roam-node-find
       :desc "Insert link"        "i" #'org-roam-node-insert
       :desc "Daily note"         "j" #'org-roam-dailies-goto-today
       :desc "Capture (pick)"     "c" #'org-roam-capture
       :desc "New default note"   "d" (lambda () (interactive) (org-roam-capture nil "d"))
       :desc "New hugo note"      "n" (lambda () (interactive) (org-roam-capture nil "n"))
       :desc "Backlinks"          "l" #'org-roam-buffer-toggle))

(map! "C-c n f" #'org-roam-node-find
      "C-c n i" #'org-roam-node-insert
      "C-c n j" #'org-roam-dailies-goto-today
      "C-c n c" #'org-roam-capture
      "C-c n d" (lambda () (interactive) (org-roam-capture nil "d"))
      "C-c n n" (lambda () (interactive) (org-roam-capture nil "n"))
      "C-c n l" #'org-roam-buffer-toggle)

(when (and (file-exists-p "~/custom-org-citeproc-export.csl")
           (file-exists-p "~/csl-locales/"))
  (use-package! org-ref
    :after org
    :config
    (setq org-ref-csl-default-style (expand-file-name "~/custom-org-citeproc-export.csl")
          org-cite-csl-locales-dir  (expand-file-name "~/csl-locales/"))))
