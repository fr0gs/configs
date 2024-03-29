;;; package --- Summary

;;; Commentary:

;;; Code:

;; remove all the initial blabla messages
(setq inhibit-startup-message t)

;; remove emacs beep
(setq visible-bell 1)

;; disable auto indenting
(setq-default indent-tabs-mode t)

;; set default tab width (will be overwritten by major modes)
(setq tab-width 2)

;; add ELPA package archive package
(require 'package)

(add-to-list 'package-archives
            '("melpa" . "http://melpa.org/packages/") t)
(add-to-list 'package-archives
	     '("marmalade". "http://marmalade-repo.org/packages/") t)
(add-to-list 'package-archives
	     '("gnu" . "http://elpa.gnu.org/packages/") t)


(when (>= emacs-major-version 24)
  (require 'package)
  (package-initialize)
  (add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t))


;; prompt for name of a package in 'available' status, downloads and installs it
;; curiously, if this call goes before
(package-initialize)

(defun ensure-package-installed (&rest packages)
  "Assure every package is installed, ask for installation if it’s not.  Return a list of installed PACKAGES or nil for every skipped package."
  (mapcar
   (lambda (package)
     ;; (package-installed-p 'evil)
     (if (package-installed-p package)
         nil
       (if (y-or-n-p (format "Package %s is missing.  Install it? " package))
           (package-install package)
         package)))
   packages))

;; make sure to have downloaded archive description.
;; Or use package-archive-contents as suggested by Nicolas Dudebout
(or (file-exists-p package-user-dir)
    (package-refresh-contents))

;; List of packages to be verified and installed
;; goes here automatically
(ensure-package-installed
 'popup
 'expand-region
 'auto-complete
 'magit
 'helm
 'smex
 'neotree
 'autumn-light-theme
 'avk-emacs-themes
 'docker-compose-mode
 'js2-mode
 'js2-refactor
 'xref-js2
 'markdown-mode
 'web-mode
 'nyan-mode
 'handlebars-mode
 'coffee-mode
 'lua-mode
 'clojure-mode
 'restart-emacs
 'slime
 'flymd
 'flycheck
 'highlight-parentheses
 'autopair)


;; Set your lisp system and, optionally, some contribs
(setq inferior-lisp-program "/usr/bin/sbcl")
(setq slime-contribs '(slime-fancy))


;; flymd (markdown live preview)
(require 'flymd)

;; flycheck support (on the fly syntax check)
(require 'flycheck)
(add-hook 'after-init-hook #'global-flycheck-mode)


;; helm (smart buffer & search)
(require 'helm-config)
(helm-mode 1)
(global-set-key (kbd "M-x") 'helm-M-x)
(global-set-key (kbd "C-x C-f") 'helm-find-files)

(with-eval-after-load 'helm
  (define-key helm-map (kbd "TAB") #'helm-maybe-exit-minibuffer))


(require 'helm-ag)
(global-set-key (kbd "C-x C-g") 'helm-do-ag)

;; smex builds on top of IDO, providing an interface to the most recently used commands.
(require 'smex)
(smex-initialize)
(global-set-key (kbd "M-x") 'smex)
(global-set-key (kbd "M-X") 'smex-major-mode-commands)


;; neotree (tree view)
;(add-to-list 'load-path "/some/path/neotree")
(require 'neotree)
(global-set-key [f8] 'neotree-toggle)


;; expand-region, expands regions semantically (selecting)
(require 'expand-region)
(global-set-key (kbd "C-=") 'er/expand-region)


;; js2-mode default for javascript files
(require 'js2-mode)
(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))


;; js2-refactor is a library to make fast refactors in .js files
(require 'js2-refactor)
(require 'xref-js2)

(add-hook 'js2-mode-hook #'js2-refactor-mode)
(js2r-add-keybindings-with-prefix "C-c C-r")
(define-key js2-mode-map (kbd "C-k") #'js2r-kill)

;; js-mode (which js2 is based on) binds "M-." which conflicts with xref, so unbind it.
(define-key js-mode-map (kbd "M-.") nil)

(add-hook 'js2-mode-hook (lambda ()
  (add-hook 'xref-backend-functions #'xref-js2-xref-backend nil t)))


;; autopair to automatically round with parentheses marked regions
;(add-to-list 'load-path "/path/to/autopair") ;; comment if autopair.el is in standard load path
(require 'autopair)
(autopair-global-mode) ;; enable autopair in all buffers

(add-hook 'emacs-lisp-mode-hook
          '(lambda ()
             (highlight-parentheses-mode)
             (setq autopair-handle-action-fns
                   (list 'autopair-default-handle-action
                         '(lambda (action pair pos-before)
                            (hl-paren-color-update))))))

(define-globalized-minor-mode global-highlight-parentheses-mode
  highlight-parentheses-mode
  (lambda ()
    (highlight-parentheses-mode t)))
(global-highlight-parentheses-mode t)

;; Source: http://www.emacswiki.org/emacs-en/download/misc-cmds.el
;; Reload buffer without confirmation
(defun revert-buffer-no-confirm ()
    "Revert buffer without confirmation."
    (interactive)
    (revert-buffer t t))


(defun my-enable-minor-modes (&optional programming)
   "Enables the following minor modes for PROGRAMMING."
   (interactive "")
   (scroll-bar-mode 0)
   (tool-bar-mode 0)
;   (flyspell-mode (not programming))
   (visual-line-mode t)
   (column-number-mode t)
   (linum-mode t))

(defun my-enable-minor-prog-modes ()
  "Enables minor modes for PROGRAMMING."
  (my-enable-minor-modes 1))

(add-hook 'prog-mode-hook 'my-enable-minor-prog-modes)
(add-hook 'org-mode-hook 'my-enable-minor-modes)
(add-hook 'text-mode-hook 'my-enable-minor-modes)
(add-hook 'xml-mode 'my-enable-minor-modes)
(add-hook 'ttl-mode 'my-enable-minor-modes)
(add-hook 'sparql-mode 'my-enable-minor-modes)


;; Goto-line short-cut key
(global-set-key (kbd "C-c l") 'goto-line)


;; (require 'web-mode)
;; (add-to-list 'auto-mode-alist '("\\.phtml\\'" . web-mode))
;; (add-to-list 'auto-mode-alist '("\\.tpl\\.php\\'" . web-mode))
;; (add-to-list 'auto-mode-alist '("\\.[gj]sp\\'" . web-mode))
;; (add-to-list 'auto-mode-alist '("\\.as[cp]x\\'" . web-mode))
;; (add-to-list 'auto-mode-alist '("\\.erb\\'" . web-mode))
;; (add-to-list 'auto-mode-alist '("\\.mustache\\'" . web-mode))
;; (add-to-list 'auto-mode-alist '("\\.djhtml\\'" . web-mode))
;; (add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))
;; (add-to-list 'auto-mode-alist '("\\.hbs\\'" . web-mode))


;; (set-face-attribute 'web-mode-html-tag-face nil :foreground "steel blue")
;; (set-face-attribute 'web-mode-html-attr-name-face nil :foreground "light blue")

(defun hide-dos-eol ()
  "Do not show ^M in files containing mixed UNIX and DOS line endings."
  (interactive)
  (setq buffer-display-table (make-display-table))
  (aset buffer-display-table ?\^M []))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(coffee-tab-width 2)
 '(custom-enabled-themes (quote (avk-darkblue-yellow)))
 '(custom-safe-themes
   (quote
    ("5d75f9080a171ccf5508ce033e31dbf5cc8aa19292a7e0ce8071f024c6bcad2a" "3e83abe75cebf5621e34ce1cbe6e12e4d80766bed0755033febed5794d0c69bf" "55d31108a7dc4a268a1432cd60a7558824223684afecefa6fae327212c40f8d3" "5cd0afd0ca01648e1fff95a7a7f8abec925bd654915153fb39ee8e72a8b56a1f" "c39ae5721fce3a07a27a685c08e4b856a13780dbc755a569bb4393c932f226d7" "6bb466c89b7e3eedc1f19f5a0cfa53be9baf6077f4d4a6f9b5d087f0231de9c8" "590759adc4a5bf7a183df81654cce13b96089e026af67d92b5eec658fb3fe22f" "ac5584b12254623419499c3a7a5388031a29be85a15fdef9b94df2292d3e2cbb" "12b7ed9b0e990f6d41827c343467d2a6c464094cbcc6d0844df32837b50655f9" "9a77026c04c2b191637239d0a2374b2cf019eb457a216f6ecc391a4a42f6ed08" "30ba590271e63571536bcded60eca30e0645011a860be1c987fc6476c1603f15" "28ec8ccf6190f6a73812df9bc91df54ce1d6132f18b4c8fcc85d45298569eb53" "0a5e87ac98b0adfe4e12356fff24d49ffbbe5ef0aa8290752c184e6857d70558" "98a619757483dc6614c266107ab6b19d315f93267e535ec89b7af3d62fb83cad" "357d5abe6f693f2875bb3113f5c031b7031f21717e8078f90d9d9bc3a14bcbd8" "40664277ccd962bc373bff67affb4efa7c9bf3dabd81787e6e08fe080ba9645f" default)))
 '(ember-keymap-prefix "c")
 '(js-indent-level 2)
 '(js2-bounce-indent-p t)
 '(package-selected-packages
   (quote
    (swap-regions helm-ag-r helm-ag dockerfile-mode fish-mode autopair highlight-parentheses flycheck flymd xref-js2 web-mode smex slime restart-emacs nyan-mode neotree markdown-mode magit lua-mode js2-refactor helm handlebars-mode expand-region docker-compose-mode coffee-mode clojure-mode avk-emacs-themes autumn-light-theme auto-complete))))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(global-set-key (kbd "C-c s") 'magit-status)

;; this is needed for something I cant remember. HEH
(setq shell-file-name "/bin/bash")

;; enable showing matching braces and parentheses when writing
;; functions for example
(setq show-paren-mode 1)
(setq show-paren-style 'mixed) ; for braces and parentheses both

;; activate nyan-mode by default
;; if it does not load, change the path to the new version.
(add-to-list 'load-path "~/.emacs.d/elpa/nyan-mode-20170423.40/")
(require 'nyan-mode)
(nyan-mode)

;; Avoid recentering on emacs when reaching end of the buffer
;; in order to have a smooth scrolling experience.
(setq scroll-step 1)
(setq scroll-conservatively 10000)
(setq auto-window-vscroll nil)


;;; .emacs ends here
