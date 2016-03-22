(package-initialize) 

(setq inhibit-startup-message t)

(require 'package)
(add-to-list 'package-archives
            '("melpa" . "http://melpa.org/packages/") t)
(add-to-list 'package-archives
	     '("marmalade". "http://marmalade-repo.org/packages/") t)
(add-to-list 'package-archives
	     '("gnu" . "http://elpa.gnu.org/packages/") t)
(package-initialize)

(defun my-enable-minor-modes (&optional programming)
   "Enables the following minor modes."
   (interactive "")
   (scroll-bar-mode 0)
   (tool-bar-mode 0)
;   (flyspell-mode (not programming))
   (visual-line-mode t)
   (column-number-mode t)
   (linum-mode t))

(defun my-enable-minor-prog-modes ()
  "enables minor modes for programming"
  (my-enable-minor-modes 1))

(add-hook 'prog-mode-hook 'my-enable-minor-prog-modes)
(add-hook 'org-mode-hook 'my-enable-minor-modes)
(add-hook 'text-mode-hook 'my-enable-minor-modes)
(add-hook 'xml-mode 'my-enable-minor-modes)
(add-hook 'ttl-mode 'my-enable-minor-modes)
(add-hook 'sparql-mode 'my-enable-minor-modes)

;; fancy buffer switching
;; ido-mode
(require 'ido)
(ido-mode 1)
(ido-everywhere 1)
(setq ido-enable-flex-matching t)
(add-hook 'ido-setup-hook 
          (lambda () 
            (define-key ido-completion-map [tab] 'ido-complete)))

(add-hook 'ido-setup-hook 
    (lambda () 
      (define-key ido-completion-map "\r" 'ido-exit-minibuffer)))

(defun ido-smart-select-text ()
    "Select the current completed item.  Do NOT descend into directories."
    (interactive)
    (when (and (or (not ido-require-match)
                   (if (memq ido-require-match
                             '(confirm confirm-after-completion))
                       (if (or (eq ido-cur-item 'dir)
                               (eq last-command this-command))
                           t
                         (setq ido-show-confirm-message t)
                         nil))
                   (ido-existing-item-p))
               (not ido-incomplete-regexp))
      (when ido-current-directory
        (setq ido-exit 'takeprompt)
        (unless (and ido-text (= 0 (length ido-text)))
          (let ((match (ido-name (car ido-matches))))
            (throw 'ido
                   (setq ido-selected
                         (if match
                             (replace-regexp-in-string "/\\'" "" match)
                           ido-text)
                         ido-text ido-selected
                         ido-final-text ido-text)))))
      (exit-minibuffer)))
  
  (eval-after-load "ido"
    '(define-key ido-common-completion-map "\C-m" 'ido-smart-select-text))

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
 '(custom-enabled-themes (quote (suscolors)))
 '(custom-safe-themes
   (quote
    ("0a5e87ac98b0adfe4e12356fff24d49ffbbe5ef0aa8290752c184e6857d70558" "98a619757483dc6614c266107ab6b19d315f93267e535ec89b7af3d62fb83cad" "357d5abe6f693f2875bb3113f5c031b7031f21717e8078f90d9d9bc3a14bcbd8" "40664277ccd962bc373bff67affb4efa7c9bf3dabd81787e6e08fe080ba9645f" default)))
 '(ember-keymap-prefix "c"))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; ido-mode
(require 'ido)
(ido-mode 1)
(ido-everywhere 1)
(setq ido-enable-flex-matching t)

;; smex
(require 'smex)
(smex-initialize)
(global-set-key (kbd "M-x") 'smex)
(global-set-key (kbd "M-X") 'smex-major-mode-commands)

;; ember-mode
;(add-to-list  'auto-mode-alist '("\\.coffee\\'" . ember-mode))
;(add-to-list  'auto-mode-alist '("\\.coffee\\'" . coffee-mode))

(global-set-key (kbd "C-c s") 'magit-status)
