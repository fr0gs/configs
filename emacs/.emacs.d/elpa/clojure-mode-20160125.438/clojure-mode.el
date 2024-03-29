;;; clojure-mode.el --- Major mode for Clojure code -*- lexical-binding: t; -*-

;; Copyright © 2007-2016 Jeffrey Chu, Lennart Staflin, Phil Hagelberg
;; Copyright © 2013-2016 Bozhidar Batsov
;;
;; Authors: Jeffrey Chu <jochu0@gmail.com>
;;       Lennart Staflin <lenst@lysator.liu.se>
;;       Phil Hagelberg <technomancy@gmail.com>
;;       Bozhidar Batsov <bozhidar@batsov.com>
;; URL: http://github.com/clojure-emacs/clojure-mode
;; Package-Version: 20160125.438
;; Keywords: languages clojure clojurescript lisp
;; Version: 5.1.0
;; Package-Requires: ((emacs "24.3"))

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Provides font-lock, indentation, and navigation for the Clojure
;; programming language (http://clojure.org).

;; Using clojure-mode with paredit or smartparens is highly recommended.

;; Here are some example configurations:

;;   ;; require or autoload paredit-mode
;;   (add-hook 'clojure-mode-hook #'paredit-mode)

;;   ;; require or autoload smartparens
;;   (add-hook 'clojure-mode-hook #'smartparens-strict-mode)

;; See inf-clojure (http://github.com/clojure-emacs/inf-clojure) for
;; basic interaction with Clojure subprocesses.

;; See CIDER (http://github.com/clojure-emacs/cider) for
;; better interaction with subprocesses via nREPL.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:


(eval-when-compile
  (defvar calculate-lisp-indent-last-sexp)
  (defvar font-lock-beg)
  (defvar font-lock-end)
  (defvar paredit-space-for-delimiter-predicates)
  (defvar paredit-version)
  (defvar paredit-mode))

(require 'cl-lib)
(require 'imenu)
(require 'newcomment)
(require 'align)

(declare-function lisp-fill-paragraph  "lisp-mode" (&optional justify))

(defgroup clojure nil
  "Major mode for editing Clojure code."
  :prefix "clojure-"
  :group 'languages
  :link '(url-link :tag "Github" "https://github.com/clojure-emacs/clojure-mode")
  :link '(emacs-commentary-link :tag "Commentary" "clojure-mode"))

(defconst clojure-mode-version "5.1.0"
  "The current version of `clojure-mode'.")

(defface clojure-keyword-face
  '((t (:inherit font-lock-constant-face)))
  "Face used to font-lock Clojure keywords (:something)."
  :package-version '(clojure-mode . "3.0.0"))

(defface clojure-character-face
  '((t (:inherit font-lock-string-face)))
  "Face used to font-lock Clojure character literals."
  :package-version '(clojure-mode . "3.0.0"))

(defface clojure-interop-method-face
  '((t (:inherit font-lock-preprocessor-face)))
  "Face used to font-lock interop method names (camelCase)."
  :package-version '(clojure-mode . "3.0.0"))

(defcustom clojure-indent-style :always-align
  "Indentation style to use for function forms and macro forms.
There are two cases of interest configured by this variable.

- Case (A) is when at least one function argument is on the same
  line as the function name.
- Case (B) is the opposite (no arguments are on the same line as
  the function name).  Note that the body of macros is not
  affected by this variable, it is always indented by
  `lisp-body-indent' (default 2) spaces.

Note that this variable configures the indentation of function
forms (and function-like macros), it does not affect macros that
already use special indentation rules.

The possible values for this variable are keywords indicating how
to indent function forms.

    `:always-align' - Follow the same rules as `lisp-mode'.  All
    args are vertically aligned with the first arg in case (A),
    and vertically aligned with the function name in case (B).
    For instance:
        (reduce merge
                some-coll)
        (reduce
         merge
         some-coll)

    `:always-indent' - All args are indented like a macro body.
        (reduce merge
          some-coll)
        (reduce
          merge
          some-coll)

    `:align-arguments' - Case (A) is indented like `lisp', and
    case (B) is indented like a macro body.
        (reduce merge
                some-coll)
        (reduce
          merge
          some-coll)"
  :type '(choice (const :tag "Same as `lisp-mode'" lisp)
                 (const :tag "Indent like a macro body" always-body)
                 (const :tag "Indent like a macro body unless first arg is on the same line"
                        body-unless-same-line))
  :package-version '(clojure-mode . "5.2.0"))

(define-obsolete-variable-alias 'clojure-defun-style-default-indent
  'clojure-indent-style "5.2.0")

(defcustom clojure-use-backtracking-indent t
  "When non-nil, enable context sensitive indentation."
  :type 'boolean
  :safe 'booleanp)

(defcustom clojure-max-backtracking 3
  "Maximum amount to backtrack up a list to check for context."
  :type 'integer
  :safe 'integerp)

(defcustom clojure-docstring-fill-column fill-column
  "Value of `fill-column' to use when filling a docstring."
  :type 'integer
  :safe 'integerp)

(defcustom clojure-docstring-fill-prefix-width 2
  "Width of `fill-prefix' when filling a docstring.
The default value conforms with the de facto convention for
Clojure docstrings, aligning the second line with the opening
double quotes on the third column."
  :type 'integer
  :safe 'integerp)

(defcustom clojure-omit-space-between-tag-and-delimiters '(?\[ ?\{)
  "Allowed opening delimiter characters after a reader literal tag.
For example, \[ is allowed in :db/id[:db.part/user]."
  :type '(set (const :tag "[" ?\[)
              (const :tag "{" ?\{)
              (const :tag "(" ?\()
              (const :tag "\"" ?\"))
  :safe (lambda (value)
          (and (listp value)
               (cl-every 'characterp value))))

(defcustom clojure-build-tool-files '("project.clj" "build.boot" "build.gradle")
  "A list of files, which identify a Clojure project's root.
Out-of-the box clojure-mode understands lein, boot and gradle."
  :type '(repeat string)
  :package-version '(clojure-mode . "5.0.0")
  :safe (lambda (value)
          (and (listp value)
               (cl-every 'stringp value))))

(defvar clojure-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-:") #'clojure-toggle-keyword-string)
    (define-key map (kbd "C-c SPC") #'clojure-align)
    (easy-menu-define clojure-mode-menu map "Clojure Mode Menu"
      '("Clojure"
        ["Toggle between string & keyword" clojure-toggle-keyword-string]
        "--"
        ["Insert ns form at point" clojure-insert-ns-form-at-point]
        ["Insert ns form at beginning" clojure-insert-ns-form]
        ["Update ns form" clojure-update-ns]
        "--"
        ["Version" clojure-mode-display-version]))
    map)
  "Keymap for Clojure mode.")

(defvar clojure-mode-syntax-table
  (let ((table (copy-syntax-table emacs-lisp-mode-syntax-table)))
    (modify-syntax-entry ?~ "'   " table)
    (modify-syntax-entry ?\{ "(}" table)
    (modify-syntax-entry ?\} "){" table)
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    (modify-syntax-entry ?^ "'" table)
    (modify-syntax-entry ?@ "'" table)
    ;; Make hash a usual word character
    (modify-syntax-entry ?# "_ p" table)
    table)
  "Syntax table for Clojure mode.
Inherits from `emacs-lisp-mode-syntax-table'.")

(defconst clojure--prettify-symbols-alist
  '(("fn"  . ?λ)))

(defun clojure-mode-display-version ()
  "Display the current `clojure-mode-version' in the minibuffer."
  (interactive)
  (message "clojure-mode (version %s)" clojure-mode-version))

(defun clojure-space-for-delimiter-p (endp delim)
  "Prevent paredit from inserting useless spaces.
See `paredit-space-for-delimiter-predicates' for the meaning of
ENDP and DELIM."
  (or endp
      (not (memq delim '(?\" ?{ ?\( )))
      (not (or (derived-mode-p 'clojure-mode)
               (derived-mode-p 'cider-repl-mode)))
      (save-excursion
        (backward-char)
        (cond ((eq (char-after) ?#)
               (and (not (bobp))
                    (or (char-equal ?w (char-syntax (char-before)))
                        (char-equal ?_ (char-syntax (char-before))))))
              ((and (eq delim ?\()
                    (eq (char-after) ??)
                    (eq (char-before) ?#))
               nil)
              (t)))))

(defun clojure-no-space-after-tag (endp delimiter)
  "Prevent inserting a space after a reader-literal tag?

When a reader-literal tag is followed be an opening delimiter
listed in `clojure-omit-space-between-tag-and-delimiters', this
function returns t.

This allows you to write things like #db/id[:db.part/user]
without inserting a space between the tag and the opening
bracket.

See `paredit-space-for-delimiter-predicates' for the meaning of
ENDP and DELIMITER."
  (if endp
      t
    (or (not (member delimiter clojure-omit-space-between-tag-and-delimiters))
        (save-excursion
          (let ((orig-point (point)))
            (not (and (re-search-backward
                       "#\\([a-zA-Z0-9._-]+/\\)?[a-zA-Z0-9._-]+"
                       (line-beginning-position)
                       t)
                      (= orig-point (match-end 0)))))))))

(declare-function paredit-open-curly "ext:paredit")
(declare-function paredit-close-curly "ext:paredit")

(defun clojure-paredit-setup (&optional keymap)
  "Make \"paredit-mode\" play nice with `clojure-mode'.

If an optional KEYMAP is passed the changes are applied to it,
instead of to `clojure-mode-map'."
  (when (>= paredit-version 21)
    (let ((keymap (or keymap clojure-mode-map)))
      (define-key keymap "{" #'paredit-open-curly)
      (define-key keymap "}" #'paredit-close-curly))
    (add-to-list 'paredit-space-for-delimiter-predicates
                 #'clojure-space-for-delimiter-p)
    (add-to-list 'paredit-space-for-delimiter-predicates
                 #'clojure-no-space-after-tag)))

(defun clojure-mode-variables ()
  "Set up initial buffer-local variables for Clojure mode."
  (setq-local imenu-create-index-function
              (lambda ()
                (imenu--generic-function '((nil clojure-match-next-def 0)))))
  (setq-local indent-tabs-mode nil)
  (setq-local paragraph-ignore-fill-prefix t)
  (setq-local outline-regexp ";;;\\(;* [^ \t\n]\\)\\|(")
  (setq-local outline-level 'lisp-outline-level)
  (setq-local comment-start ";")
  (setq-local comment-start-skip ";+ *")
  (setq-local comment-add 1) ; default to `;;' in comment-region
  (setq-local comment-column 40)
  (setq-local comment-use-syntax t)
  (setq-local multibyte-syntax-as-symbol t)
  (setq-local electric-pair-skip-whitespace 'chomp)
  (setq-local electric-pair-open-newline-between-pairs nil)
  (setq-local fill-paragraph-function #'clojure-fill-paragraph)
  (setq-local adaptive-fill-function #'clojure-adaptive-fill-function)
  (setq-local normal-auto-fill-function #'clojure-auto-fill-function)
  (setq-local comment-start-skip
              "\\(\\(^\\|[^\\\\\n]\\)\\(\\\\\\\\\\)*\\)\\(;+\\|#|\\) *")
  (setq-local indent-line-function #'clojure-indent-line)
  (setq-local indent-region-function #'clojure-indent-region)
  (setq-local lisp-indent-function #'clojure-indent-function)
  (setq-local lisp-doc-string-elt-property 'clojure-doc-string-elt)
  (setq-local parse-sexp-ignore-comments t)
  (setq-local prettify-symbols-alist clojure--prettify-symbols-alist)
  (setq-local open-paren-in-column-0-is-defun-start nil))

;;;###autoload
(define-derived-mode clojure-mode prog-mode "Clojure"
  "Major mode for editing Clojure code.

\\{clojure-mode-map}"
  (clojure-mode-variables)
  (clojure-font-lock-setup)
  (add-hook 'paredit-mode-hook #'clojure-paredit-setup))

(defsubst clojure-in-docstring-p ()
  "Check whether point is in a docstring."
  (eq (get-text-property (point) 'face) 'font-lock-doc-face))

(defsubst clojure-docstring-fill-prefix ()
  "The prefix string used by `clojure-fill-paragraph'.

It is simply `clojure-docstring-fill-prefix-width' number of spaces."
  (make-string clojure-docstring-fill-prefix-width ? ))

(defun clojure-adaptive-fill-function ()
  "Clojure adaptive fill function.
This only takes care of filling docstring correctly."
  (when (clojure-in-docstring-p)
    (clojure-docstring-fill-prefix)))

(defun clojure-fill-paragraph (&optional justify)
  "Like `fill-paragraph', but can handle Clojure docstrings.

If JUSTIFY is non-nil, justify as well as fill the paragraph."
  (if (clojure-in-docstring-p)
      (let ((paragraph-start
             (concat paragraph-start
                     "\\|\\s-*\\([(;:\"[]\\|~@\\|`(\\|#'(\\)"))
            (paragraph-separate
             (concat paragraph-separate "\\|\\s-*\".*[,\\.]$"))
            (fill-column (or clojure-docstring-fill-column fill-column))
            (fill-prefix (clojure-docstring-fill-prefix)))
        (fill-paragraph justify))
    (let ((paragraph-start (concat paragraph-start
                                   "\\|\\s-*\\([(;:\"[]\\|`(\\|#'(\\)"))
          (paragraph-separate
           (concat paragraph-separate "\\|\\s-*\".*[,\\.[]$")))
      (or (fill-comment-paragraph justify)
          (fill-paragraph justify))
      ;; Always return `t'
      t)))

(defun clojure-auto-fill-function ()
  "Clojure auto-fill function."
  ;; Check if auto-filling is meaningful.
  (let ((fc (current-fill-column)))
    (when (and fc (> (current-column) fc))
      (let ((fill-column (if (clojure-in-docstring-p)
                             clojure-docstring-fill-column
                           fill-column))
            (fill-prefix (clojure-adaptive-fill-function)))
        (do-auto-fill)))))


;;; #_ comments font-locking
;; Code heavily borrowed from Slime.
;; https://github.com/slime/slime/blob/master/contrib/slime-fontifying-fu.el#L186
(defvar clojure--comment-macro-regexp
  (rx "#_" (* " ") (group-n 1 (not (any " "))))
  "Regexp matching the start of a comment sexp.
The beginning of match-group 1 should be before the sexp to be
marked as a comment.  The end of sexp is found with
`clojure-forward-logical-sexp'.

By default, this only applies to code after the `#_' reader
macro.  In order to also font-lock the `(comment ...)' macro as a
comment, you can set the value to:
    \"#_ *\\\\(?1:[^ ]\\\\)\\\\|\\\\(?1:(comment\\\\_>\\\\)\"")

(defun clojure--search-comment-macro-internal (limit)
  (when (search-forward-regexp clojure--comment-macro-regexp limit t)
    (let* ((md (match-data))
           (start (match-beginning 1))
           (state (syntax-ppss start)))
      ;; inside string or comment?
      (if (or (nth 3 state)
              (nth 4 state))
          (clojure--search-comment-macro-internal limit)
        (goto-char start)
        (clojure-forward-logical-sexp 1)
        ;; Data for (match-end 1).
        (setf (elt md 3) (point))
        (set-match-data md)
        t))))

(defun clojure--search-comment-macro (limit)
  "Find comment macros and set the match data.
Search from point up to LIMIT.  The region that should be
considered a comment is between `(match-beginning 1)'
and `(match-end 1)'."
  (let ((result 'retry))
    (while (and (eq result 'retry) (<= (point) limit))
      (condition-case nil
          (setq result (clojure--search-comment-macro-internal limit))
        (end-of-file (setq result nil))
        (scan-error  (setq result 'retry))))
    result))


;;; General font-locking
(defun clojure-match-next-def ()
  "Scans the buffer backwards for the next \"top-level\" definition.
Called by `imenu--generic-function'."
  ;; we have to take into account namespace-definition forms
  ;; e.g. s/defn
  (when (re-search-backward "^(\\([a-z0-9.-]+/\\)?def\\sw*" nil t)
    (save-excursion
      (let (found?
            (start (point)))
        (down-list)
        (forward-sexp)
        (while (not found?)
          (forward-sexp)
          (or (if (char-equal ?[ (char-after (point)))
                              (backward-sexp))
                  (if (char-equal ?) (char-after (point)))
                (backward-sexp)))
          (cl-destructuring-bind (def-beg . def-end) (bounds-of-thing-at-point 'sexp)
            (if (char-equal ?^ (char-after def-beg))
                (progn (forward-sexp) (backward-sexp))
              (setq found? t)
              (set-match-data (list def-beg def-end)))))
        (goto-char start)))))

(eval-and-compile
  (defconst clojure--sym-forbidden-rest-chars "][\";\'@\\^`~\(\)\{\}\\,\s\t\n\r"
    "A list of chars that a Clojure symbol cannot contain.
See definition of 'macros': URL `http://git.io/vRGLD'.")
  (defconst clojure--sym-forbidden-1st-chars (concat clojure--sym-forbidden-rest-chars "0-9")
    "A list of chars that a Clojure symbol cannot start with.
See the for-loop: URL `http://git.io/vRGTj' lines: URL
`http://git.io/vRGIh', URL `http://git.io/vRGLE' and value
definition of 'macros': URL `http://git.io/vRGLD'.")
  (defconst clojure--sym-regexp
    (concat "[^" clojure--sym-forbidden-1st-chars "][^" clojure--sym-forbidden-rest-chars "]*")
    "A regexp matching a Clojure symbol or namespace alias.
Matches the rule `clojure--sym-forbidden-1st-chars' followed by
any number of matches of `clojure--sym-forbidden-rest-chars'."))

(defconst clojure-font-lock-keywords
  (eval-when-compile
    `(;; Top-level variable definition
      (,(concat "(\\(?:clojure.core/\\)?\\("
                (regexp-opt '("def" "defonce"))
                ;; variable declarations
                "\\)\\>"
                ;; Any whitespace
                "[ \r\n\t]*"
                ;; Possibly type or metadata
                "\\(?:#?^\\(?:{[^}]*}\\|\\sw+\\)[ \r\n\t]*\\)*"
                "\\(\\sw+\\)?")
       (1 font-lock-keyword-face)
       (2 font-lock-variable-name-face nil t))
      ;; Type definition
      (,(concat "(\\(?:clojure.core/\\)?\\("
                (regexp-opt '("defstruct" "deftype" "defprotocol"
                              "defrecord"))
                ;; type declarations
                "\\)\\>"
                ;; Any whitespace
                "[ \r\n\t]*"
                ;; Possibly type or metadata
                "\\(?:#?^\\(?:{[^}]*}\\|\\sw+\\)[ \r\n\t]*\\)*"
                "\\(\\sw+\\)?")
       (1 font-lock-keyword-face)
       (2 font-lock-type-face nil t))
      ;; Function definition (anything that starts with def and is not
      ;; listed above)
      (,(concat "(\\(?:" clojure--sym-regexp "/\\)?"
                "\\(def[^ \r\n\t]*\\)"
                ;; Function declarations
                "\\>"
                ;; Any whitespace
                "[ \r\n\t]*"
                ;; Possibly type or metadata
                "\\(?:#?^\\(?:{[^}]*}\\|\\sw+\\)[ \r\n\t]*\\)*"
                "\\(\\sw+\\)?")
       (1 font-lock-keyword-face)
       (2 font-lock-function-name-face nil t))
      ;; (fn name? args ...)
      (,(concat "(\\(?:clojure.core/\\)?\\(fn\\)[ \t]+"
                ;; Possibly type
                "\\(?:#?^\\sw+[ \t]*\\)?"
                ;; Possibly name
                "\\(t\\sw+\\)?" )
       (1 font-lock-keyword-face)
       (2 font-lock-function-name-face nil t))
      ;; lambda arguments - %, %1, %2, etc
      ("\\<%[1-9]?" (0 font-lock-variable-name-face))
      ;; Special forms
      (,(concat
         "("
         (regexp-opt
          '("def" "do" "if" "let" "var" "fn" "loop"
            "recur" "throw" "try" "catch" "finally"
            "set!" "new" "."
            "monitor-enter" "monitor-exit" "quote") t)
         "\\>")
       1 font-lock-keyword-face)
      ;; Built-in binding and flow of control forms
      (,(concat
         "(\\(?:clojure.core/\\)?"
         (regexp-opt
          '("letfn" "case" "cond" "cond->" "cond->>" "condp"
            "for" "when" "when-not" "when-let" "when-first" "when-some"
            "if-let" "if-not" "if-some"
            ".." "->" "->>" "as->" "doto" "and" "or"
            "dosync" "doseq" "dotimes" "dorun" "doall"
            "ns" "in-ns"
            "with-open" "with-local-vars" "binding"
            "with-redefs" "with-redefs-fn"
            "declare") t)
         "\\>")
       1 font-lock-keyword-face)
      ;; Macros similar to let, when, and while
      (,(rx symbol-start
            (or "let" "when" "while") "-"
            (1+ (or (syntax word) (syntax symbol)))
            symbol-end)
       0 font-lock-keyword-face)
      (,(concat
         "\\<"
         (regexp-opt
          '("*1" "*2" "*3" "*agent*"
            "*allow-unresolved-vars*" "*assert*" "*clojure-version*"
            "*command-line-args*" "*compile-files*"
            "*compile-path*" "*data-readers*" "*default-data-reader-fn*"
            "*e" "*err*" "*file*" "*flush-on-newline*"
            "*in*" "*macro-meta*" "*math-context*" "*ns*" "*out*"
            "*print-dup*" "*print-length*" "*print-level*"
            "*print-meta*" "*print-readably*"
            "*read-eval*" "*source-path*"
            "*unchecked-math*"
            "*use-context-classloader*" "*warn-on-reflection*")
          t)
         "\\>")
       0 font-lock-builtin-face)
      ;; Dynamic variables - *something* or @*something*
      ("\\(?:\\<\\|/\\)@?\\(\\*[a-z-]*\\*\\)\\>" 1 font-lock-variable-name-face)
      ;; Global constants - nil, true, false
      (,(concat
         "\\<"
         (regexp-opt
          '("true" "false" "nil") t)
         "\\>")
       0 font-lock-constant-face)
      ;; Character literals - \1, \a, \newline, \u0000
      ("\\\\\\([[:punct:]]\\|[a-z0-9]+\\>\\)" 0 'clojure-character-face)
      ;; foo/ Foo/ @Foo/ /FooBar
      (,(concat "\\(?:\\<:?\\|\\.\\)@?\\(" clojure--sym-regexp "\\)\\(/\\)")
       (1 font-lock-type-face) (2 'default))
      ;; Constant values (keywords), including as metadata e.g. ^:static
      ("\\<^?\\(:\\(\\sw\\|\\s_\\)+\\(\\>\\|\\_>\\)\\)" 1 'clojure-keyword-face append)
      ;; Java interop highlighting
      ;; CONST SOME_CONST (optionally prefixed by /)
      ("\\(?:\\<\\|/\\)\\([A-Z]+\\|\\([A-Z]+_[A-Z1-9_]+\\)\\)\\>" 1 font-lock-constant-face)
      ;; .foo .barBaz .qux01 .-flibble .-flibbleWobble
      ("\\<\\.-?[a-z][a-zA-Z0-9]*\\>" 0 'clojure-interop-method-face)
      ;; Foo Bar$Baz Qux_ World_OpenUDP Foo. Babylon15.
      ("\\(?:\\<\\|\\.\\|/\\|#?^\\)\\([A-Z][a-zA-Z0-9_]*[a-zA-Z0-9$_]+\\.?\\>\\)" 1 font-lock-type-face)
      ;; foo.bar.baz
      ("\\<^?\\([a-z][a-z0-9_-]+\\.\\([a-z][a-z0-9_-]*\\.?\\)+\\)" 1 font-lock-type-face)
      ;; (ns namespace) - special handling for single segment namespaces
      (,(concat "(\\<ns\\>[ \r\n\t]*"
                ;; Possibly metadata
                "\\(?:\\^?{[^}]+}[ \r\n\t]*\\)*"
                ;; namespace
                "\\([a-z0-9-]+\\)")
       (1 font-lock-type-face nil t))
      ;; fooBar
      ("\\(?:\\<\\|/\\)\\([a-z]+[A-Z]+[a-zA-Z0-9$]*\\>\\)" 1 'clojure-interop-method-face)
      ;; #_ and (comment ...) macros.
      (clojure--search-comment-macro 1 font-lock-comment-face t)
      ;; Highlight `code` marks, just like `elisp'.
      (,(rx "`" (group-n 1 (optional "#'")
                         (+ (or (syntax symbol) (syntax word)))) "`")
       (1 'font-lock-constant-face prepend))
      ;; Highlight grouping constructs in regular expressions
      (clojure-font-lock-regexp-groups
       (1 'font-lock-regexp-grouping-construct prepend))))
  "Default expressions to highlight in Clojure mode.")

(defun clojure-font-lock-syntactic-face-function (state)
  "Find and highlight text with a Clojure-friendly syntax table.

This function is passed to `font-lock-syntactic-face-function',
which is called with a single parameter, STATE (which is, in
turn, returned by `parse-partial-sexp' at the beginning of the
highlighted region)."
  (if (nth 3 state)
      ;; This might be a (doc)string or a |...| symbol.
      (let ((startpos (nth 8 state)))
        (if (eq (char-after startpos) ?|)
            ;; This is not a string, but a |...| symbol.
            nil
          (let* ((listbeg (nth 1 state))
                 (firstsym (and listbeg
                                (save-excursion
                                  (goto-char listbeg)
                                  (and (looking-at "([ \t\n]*\\(\\(\\sw\\|\\s_\\)+\\)")
                                       (match-string 1)))))
                 (docelt (and firstsym
                              (function-get (intern-soft firstsym)
                                            lisp-doc-string-elt-property))))
            (if (and docelt
                     ;; It's a string in a form that can have a docstring.
                     ;; Check whether it's in docstring position.
                     (save-excursion
                       (when (functionp docelt)
                         (goto-char (match-end 1))
                         (setq docelt (funcall docelt)))
                       (goto-char listbeg)
                       (forward-char 1)
                       (condition-case nil
                           (while (and (> docelt 0) (< (point) startpos)
                                       (progn (forward-sexp 1) t))
                             ;; ignore metadata and type hints
                             (unless (looking-at "[ \n\t]*\\(\\^[A-Z:].+\\|\\^?{.+\\)")
                               (setq docelt (1- docelt))))
                         (error nil))
                       (and (zerop docelt) (<= (point) startpos)
                            (progn (forward-comment (point-max)) t)
                            (= (point) (nth 8 state)))))
                font-lock-doc-face
              font-lock-string-face))))
    font-lock-comment-face))

(defun clojure-font-lock-setup ()
  "Configures font-lock for editing Clojure code."
  (setq-local font-lock-multiline t)
  (add-to-list 'font-lock-extend-region-functions
               #'clojure-font-lock-extend-region-def t)
  (setq font-lock-defaults
        '(clojure-font-lock-keywords    ; keywords
          nil nil
          (("+-*/.<>=!?$%_&~^:@" . "w")) ; syntax alist
          nil
          (font-lock-mark-block-function . mark-defun)
          (font-lock-syntactic-face-function
           . clojure-font-lock-syntactic-face-function))))

(defun clojure-font-lock-def-at-point (point)
  "Range between the top-most def* and the fourth element after POINT.
Note that this means that there is no guarantee of proper font
locking in def* forms that are not at top level."
  (goto-char point)
  (condition-case nil
      (beginning-of-defun)
    (error nil))

  (let ((beg-def (point)))
    (when (and (not (= point beg-def))
               (looking-at "(def"))
      (condition-case nil
          (progn
            ;; move forward as much as possible until failure (or success)
            (forward-char)
            (dotimes (_ 4)
              (forward-sexp)))
        (error nil))
      (cons beg-def (point)))))

(defun clojure-font-lock-extend-region-def ()
  "Set region boundaries to include the first four elements of def* forms."
  (let ((changed nil))
    (let ((def (clojure-font-lock-def-at-point font-lock-beg)))
      (when def
        (cl-destructuring-bind (def-beg . def-end) def
          (when (and (< def-beg font-lock-beg)
                     (< font-lock-beg def-end))
            (setq font-lock-beg def-beg
                  changed t)))))
    (let ((def (clojure-font-lock-def-at-point font-lock-end)))
      (when def
        (cl-destructuring-bind (def-beg . def-end) def
          (when (and (< def-beg font-lock-end)
                     (< font-lock-end def-end))
            (setq font-lock-end def-end
                  changed t)))))
    changed))

(defun clojure-font-lock-regexp-groups (bound)
  "Highlight grouping constructs in regular expression.

BOUND denotes the maximum number of characters (relative to the
point) to check."
  (catch 'found
    (while (re-search-forward (concat
                               ;; A group may start using several alternatives:
                               "\\(\\(?:"
                               ;; 1. (? special groups
                               "(\\?\\(?:"
                               ;; a) non-capturing group (?:X)
                               ;; b) independent non-capturing group (?>X)
                               ;; c) zero-width positive lookahead (?=X)
                               ;; d) zero-width negative lookahead (?!X)
                               "[:=!>]\\|"
                               ;; e) zero-width positive lookbehind (?<=X)
                               ;; f) zero-width negative lookbehind (?<!X)
                               "<[=!]\\|"
                               ;; g) named capturing group (?<name>X)
                               "<[[:alnum:]]+>"
                               "\\)\\|" ;; end of special groups
                               ;; 2. normal capturing groups (
                               ;; 3. we also highlight alternative
                               ;; separarators |, and closing parens )
                               "[|()]"
                               "\\)\\)")
                              bound t)
      (let ((face (get-text-property (1- (point)) 'face)))
        (when (and (or (and (listp face)
                            (memq 'font-lock-string-face face))
                       (eq 'font-lock-string-face face))
                   (clojure-string-start t))
          (throw 'found t))))))

;; Docstring positions
(put 'ns 'clojure-doc-string-elt 2)
(put 'def 'clojure-doc-string-elt 2)
(put 'defn 'clojure-doc-string-elt 2)
(put 'defn- 'clojure-doc-string-elt 2)
(put 'defmulti 'clojure-doc-string-elt 2)
(put 'defmacro 'clojure-doc-string-elt 2)
(put 'definline 'clojure-doc-string-elt 2)
(put 'defprotocol 'clojure-doc-string-elt 2)

;;; Vertical alignment
(defcustom clojure-align-forms-automatically nil
  "If non-nil, vertically align some forms automatically.
Automatically means it is done as part of indenting code.  This
applies to binding forms (`clojure-align-binding-forms'), to cond
forms (`clojure-align-cond-forms') and to map literals.  For
instance, selecting a map a hitting \\<clojure-mode-map>`\\[indent-for-tab-command]'
will align the values like this:
    {:some-key 10
     :key2     20}"
  :package-version '(clojure-mode . "5.1")
  :type 'boolean)

(defcustom clojure-align-binding-forms
  '("let" "when-let" "when-some" "if-let" "if-some" "binding" "loop"
    "doseq" "for" "with-open" "with-local-vars" "with-redefs")
  "List of strings matching forms that have binding forms."
  :package-version '(clojure-mode . "5.1")
  :type '(repeat string))

(defcustom clojure-align-cond-forms '("condp" "cond" "cond->" "cond->>" "case")
  "List of strings identifying cond-like forms."
  :package-version '(clojure-mode . "5.1")
  :type '(repeat string))

(defun clojure--position-for-alignment ()
  "Non-nil if the sexp around point should be automatically aligned.
This function expects to be called immediately after an
open-brace or after the function symbol in a function call.

First check if the sexp around point is a map literal, or is a
call to one of the vars listed in `clojure-align-cond-forms'.  If
it isn't, return nil.  If it is, return non-nil and place point
immediately before the forms that should be aligned.

For instance, in a map literal point is left immediately before
the first key; while, in a let-binding, point is left inside the
binding vector and immediately before the first binding
construct."
  ;; Are we in a map?
  (or (and (eq (char-before) ?{)
           (not (eq (char-before (1- (point))) ?\#)))
      ;; Are we in a cond form?
      (let* ((fun    (car (member (thing-at-point 'symbol) clojure-align-cond-forms)))
             (method (and fun (clojure--get-indent-method fun)))
             ;; The number of special arguments in the cond form is
             ;; the number of sexps we skip before aligning.
             (skip   (cond ((numberp method) method)
                           ((sequencep method) (elt method 0)))))
        (when (numberp skip)
          (clojure-forward-logical-sexp skip)
          (comment-forward (point-max))
          fun)) ; Return non-nil (the var name).
      ;; Are we in a let-like form?
      (when (member (thing-at-point 'symbol)
                    clojure-align-binding-forms)
        ;; Position inside the binding vector.
        (clojure-forward-logical-sexp)
        (backward-sexp)
        (when (eq (char-after) ?\[)
          (forward-char 1)
          (comment-forward (point-max))
          ;; Return non-nil.
          t))))

(defun clojure--find-sexp-to-align (end)
  "Non-nil if there's a sexp ahead to be aligned before END.
Place point as in `clojure--position-for-alignment'."
  ;; Look for a relevant sexp.
  (let ((found))
    (while (and (not found)
                (search-forward-regexp
                 (concat "{\\|(" (regexp-opt
                                  (append clojure-align-binding-forms
                                          clojure-align-cond-forms)
                                  'symbols))
                 end 'noerror))

      (let ((ppss (syntax-ppss)))
        ;; If we're in a string or comment.
        (unless (or (elt ppss 3)
                    (elt ppss 4))
          ;; Only stop looking if we successfully position
          ;; the point.
          (setq found (clojure--position-for-alignment)))))
    found))

(defun clojure--search-whitespace-after-next-sexp (&optional bound _noerror)
  "Move point after all whitespace after the next sexp.
Set the match data group 1 to be this region of whitespace and
return point."
  (unwind-protect
      (ignore-errors
        (clojure-forward-logical-sexp 1)
        (search-forward-regexp "\\( *\\)" bound)
        (pcase (syntax-after (point))
          ;; End-of-line, try again on next line.
          (`(12) (clojure--search-whitespace-after-next-sexp bound))
          ;; Closing paren, stop here.
          (`(5 . ,_) nil)
          ;; Anything else is something to align.
          (_ (point))))
    (when (and bound (> (point) bound))
      (goto-char bound))))

(defun clojure-align (beg end)
  "Vertically align the contents of the sexp around point.
If region is active, align it. Otherwise, align everything in the
current top-level sexp.
When called from lisp code align everything between BEG and END."
  (interactive (if (use-region-p)
                   (list (region-beginning) (region-end))
                 (save-excursion
                   (let ((end (progn (end-of-defun)
                                     (point))))
                     (clojure-backward-logical-sexp)
                     (list (point) end)))))
  (setq end (copy-marker end))
  (save-excursion
    (goto-char beg)
    (while (clojure--find-sexp-to-align end)
      (let ((sexp-end (save-excursion
                        (backward-up-list)
                        (forward-sexp 1)
                        (point-marker)))
            (clojure-align-forms-automatically nil))
        (align-region (point) sexp-end nil
                      '((clojure-align (regexp . clojure--search-whitespace-after-next-sexp)
                                       (group . 1)
                                       (repeat . t)))
                      nil)
        ;; Reindent after aligning because of #360.
        (indent-region (point) sexp-end)))))

;;; Indentation
(defun clojure-indent-region (beg end)
  "Like `indent-region', but also maybe align forms.
Forms between BEG and END are aligned according to
`clojure-align-forms-automatically'."
  (prog1 (let ((indent-region-function nil))
           (indent-region beg end))
    (when clojure-align-forms-automatically
      (condition-case er
          (clojure-align beg end)
        (scan-error nil)))))

(defun clojure-indent-line ()
  "Indent current line as Clojure code."
  (if (clojure-in-docstring-p)
      (save-excursion
        (beginning-of-line)
        (when (and (looking-at "^\\s-*")
                   (<= (string-width (match-string-no-properties 0))
                       (string-width (clojure-docstring-fill-prefix))))
          (replace-match (clojure-docstring-fill-prefix))))
    (lisp-indent-line)))

(defvar clojure-get-indent-function nil
  "Function to get the indent spec of a symbol.
This function should take one argument, the name of the symbol as
a string.  This name will be exactly as it appears in the buffer,
so it might start with a namespace alias.

This function is analogous to the `clojure-indent-function'
symbol property, and its return value should match one of the
allowed values of this property.  See `clojure-indent-function'
for more information.")

(defun clojure--get-indent-method (function-name)
  "Return the indent spec for the symbol named FUNCTION-NAME.
FUNCTION-NAME is a string.  If it contains a `/', also try only
the part after the `/'.

Look for a spec using `clojure-get-indent-function', then try the
`clojure-indent-function' and `clojure-backtracking-indent'
symbol properties."
  (or (when (functionp clojure-get-indent-function)
        (funcall clojure-get-indent-function function-name))
      (get (intern-soft function-name) 'clojure-indent-function)
      (get (intern-soft function-name) 'clojure-backtracking-indent)
      (when (string-match "/\\([^/]+\\)\\'" function-name)
        (or (get (intern-soft (match-string 1 function-name))
                 'clojure-indent-function)
            (get (intern-soft (match-string 1 function-name))
                 'clojure-backtracking-indent)))
      (when (string-match (rx (or "let" "when" "while") (syntax symbol))
                          function-name)
        (clojure--get-indent-method (substring (match-string 0 function-name) 0 -1)))))

(defvar clojure--current-backtracking-depth 0)

(defun clojure--find-indent-spec-backtracking ()
  "Return the indent sexp that applies to the sexp at point.
Implementation function for `clojure--find-indent-spec'."
  (when (and (>= clojure-max-backtracking clojure--current-backtracking-depth)
             (not (looking-at "^")))
    (let ((clojure--current-backtracking-depth (1+ clojure--current-backtracking-depth))
          (pos 0))
      ;; Count how far we are from the start of the sexp.
      (while (ignore-errors (clojure-backward-logical-sexp 1)
                            (not (or (bobp)
                                     (eq (char-before) ?\n))))
        (cl-incf pos))
      (let* ((function (thing-at-point 'symbol))
             (method (or (when function ;; Is there a spec here?
                           (clojure--get-indent-method function))
                         (ignore-errors
                           ;; Otherwise look higher up.
                           (pcase (syntax-ppss)
                             (`(,(pred (< 0)) ,start . ,_)
                              (goto-char start)
                              (clojure--find-indent-spec-backtracking)))))))
        (when (numberp method)
          (setq method (list method)))
        (pcase method
          ((pred sequencep)
           (pcase (length method)
             (`0 nil)
             (`1 (let ((head (elt method 0)))
                   (when (or (= pos 0) (sequencep head))
                     head)))
             (l (if (>= pos l)
                    (elt method (1- l))
                  (elt method pos)))))
          ((or `defun `:defn)
           (when (= pos 0)
             :defn))
          ((pred functionp)
           (when (= pos 0)
             method))
          (_
           (message "Invalid indent spec for `%s': %s" function method)
           nil))))))

(defun clojure--find-indent-spec ()
  "Return the indent spec that applies to current sexp.
If `clojure-use-backtracking-indent' is non-nil, also do
backtracking up to a higher-level sexp in order to find the
spec."
  (if clojure-use-backtracking-indent
      (save-excursion
        (clojure--find-indent-spec-backtracking))
    (let ((function (thing-at-point 'symbol)))
      (clojure--get-indent-method function))))

(defun clojure--normal-indent (last-sexp indent-mode)
  "Return the normal indentation column for a sexp.
Point should be after the open paren of the _enclosing_ sexp, and
LAST-SEXP is the start of the previous sexp (immediately before
the sexp being indented).  INDENT-MODE is any of the values
accepted by `clojure-indent-style'."
  (goto-char last-sexp)
  (forward-sexp 1)
  (clojure-backward-logical-sexp 1)
  (let ((last-sexp-start nil))
    (if (ignore-errors
          ;; `backward-sexp' until we reach the start of a sexp that is the
          ;; first of its line (the start of the enclosing sexp).
          (while (string-match
                  "[^[:blank:]]"
                  (buffer-substring (line-beginning-position) (point)))
            (setq last-sexp-start (prog1 (point)
                                    (forward-sexp -1))))
          t)
        ;; Here we have found an arg before the arg we're indenting which is at
        ;; the start of a line. Every mode simply aligns on this case.
        (current-column)
      ;; Here we have reached the start of the enclosing sexp (point is now at
      ;; the function name), so the behaviour depends on INDENT-MODE and on
      ;; whether there's also an argument on this line (case A or B).
      (let ((case-a ; The meaning of case-a is explained in `clojure-indent-style'.
             (and last-sexp-start
                  (< last-sexp-start (line-end-position)))))
        (cond
         ;; For compatibility with the old `clojure-defun-style-default-indent', any
         ;; value other than these 3 is equivalent to `always-body'.
         ((not (memq indent-mode '(:always-align :align-arguments nil)))
          (+ (current-column) lisp-body-indent -1))
         ;; There's an arg after the function name, so align with it.
         (case-a (goto-char last-sexp-start)
                 (current-column))
         ;; Not same line.
         ((eq indent-mode :align-arguments)
          (+ (current-column) lisp-body-indent -1))
         ;; Finally, just align with the function name.
         (t (current-column)))))))

(defun clojure--not-function-form-p ()
  "Non-nil if form at point doesn't represent a function call."
  (or (member (char-after) '(?\[ ?\{))
      (save-excursion ;; Catch #?@ (:cljs ...)
        (skip-chars-backward "\r\n[:blank:]")
        (when (eq (char-before) ?@)
          (forward-char -1))
        (and (eq (char-before) ?\?)
             (eq (char-before (1- (point))) ?\#)))
      ;; Car of form is not a symbol.
      (not (looking-at ".\\(?:\\sw\\|\\s_\\)"))))

;; Check the general context, and provide indentation for data structures and
;; special macros. If current form is a function (or non-special macro),
;; delegate indentation to `clojure--normal-indent'.
(defun clojure-indent-function (indent-point state)
  "When indenting a line within a function call, indent properly.

INDENT-POINT is the position where the user typed TAB, or equivalent.
Point is located at the point to indent under (for default indentation);
STATE is the `parse-partial-sexp' state for that position.

If the current line is in a call to a Clojure function with a
non-nil property `clojure-indent-function', that specifies how to do
the indentation.

The property value can be

- `defun', meaning indent `defun'-style;
- an integer N, meaning indent the first N arguments specially
  like ordinary function arguments and then indent any further
  arguments like a body;
- a function to call just as this function was called.
  If that function returns nil, that means it doesn't specify
  the indentation.
- a list, which is used by `clojure-backtracking-indent'.

This function also returns nil meaning don't specify the indentation."
  ;; Goto to the open-paren.
  (goto-char (elt state 1))
  ;; Maps, sets, vectors and reader conditionals.
  (if (clojure--not-function-form-p)
      (1+ (current-column))
    ;; Function or macro call.
    (forward-char 1)
    (let ((method (clojure--find-indent-spec))
          (last-sexp calculate-lisp-indent-last-sexp)
          (containing-form-column (1- (current-column))))
      (pcase method
        ((or (pred integerp) `(,method))
         (let ((pos -1))
           (condition-case nil
               (while (and (<= (point) indent-point)
                           (not (eobp)))
                 (clojure-forward-logical-sexp 1)
                 (cl-incf pos))
             ;; If indent-point is _after_ the last sexp in the
             ;; current sexp, we detect that by catching the
             ;; `scan-error'. In that case, we should return the
             ;; indentation as if there were an extra sexp at point.
             (scan-error (cl-incf pos)))
           (cond
            ;; The first non-special arg. Rigidly reduce indentation.
            ((= pos (1+ method))
             (+ lisp-body-indent containing-form-column))
            ;; Further non-special args, align with the arg above.
            ((> pos (1+ method))
             (clojure--normal-indent last-sexp :always-align))
            ;; Special arg. Rigidly indent with a large indentation.
            (t
             (+ (* 2 lisp-body-indent) containing-form-column)))))
        (`:defn
         (+ lisp-body-indent containing-form-column))
        ((pred functionp)
         (funcall method indent-point state))
        ;; No indent spec, do the default.
        (`nil
         (let ((function (thing-at-point 'symbol)))
           (cond
            ;; Preserve useful alignment of :require (and friends) in `ns' forms.
            ((and function (string-match "^:" function))
             (clojure--normal-indent last-sexp :align-arguments))
            ;; This is should be identical to the :defn above.
            ((and function
                  (string-match "\\`\\(?:\\S +/\\)?\\(def[a-z]*\\|with-\\)"
                                function)
                  (not (string-match "\\`default" (match-string 1 function))))
             (+ lisp-body-indent containing-form-column))
            ;; Finally, nothing special here, just respect the user's
            ;; preference.
            (t (clojure--normal-indent last-sexp clojure-indent-style)))))))))

;;; Setting indentation
(defun put-clojure-indent (sym indent)
  "Instruct `clojure-indent-function' to indent the body of SYM by INDENT."
  (put sym 'clojure-indent-function indent))

(defmacro define-clojure-indent (&rest kvs)
  "Call `put-clojure-indent' on a series, KVS."
  `(progn
     ,@(mapcar (lambda (x) `(put-clojure-indent
                             (quote ,(car x)) ,(cadr x)))
               kvs)))

(defun add-custom-clojure-indents (name value)
  "Allow `clojure-defun-indents' to indent user-specified macros.

Requires the macro's NAME and a VALUE."
  (custom-set-default name value)
  (mapcar (lambda (x)
            (put-clojure-indent x 'defun))
          value))

(defcustom clojure-defun-indents nil
  "List of additional symbols with defun-style indentation in Clojure.

You can use this to let Emacs indent your own macros the same way
that it indents built-in macros like with-open.  To manually set
it from Lisp code, use (put-clojure-indent 'some-symbol :defn)."
  :type '(repeat symbol)
  :set 'add-custom-clojure-indents)

(define-clojure-indent
  ;; built-ins
  (ns 1)
  (fn :defn)
  (def :defn)
  (defn :defn)
  (bound-fn :defn)
  (if 1)
  (if-not 1)
  (case 1)
  (cond 0)
  (condp 2)
  (cond-> 1)
  (cond->> 1)
  (when 1)
  (while 1)
  (when-not 1)
  (when-first 1)
  (do 0)
  (future 0)
  (comment 0)
  (doto 1)
  (locking 1)
  (proxy '(2 nil nil (1)))
  (as-> 2)

  (reify '(:defn (1)))
  (deftype '(2 nil nil (1)))
  (defrecord '(2 nil nil (1)))
  (defprotocol '(1 (:defn)))
  (extend 1)
  (extend-protocol '(1 :defn))
  (extend-type '(1 :defn))
  ;; specify and specify! are from ClojureScript
  (specify '(1 :defn))
  (specify! '(1 :defn))
  (try 0)
  (catch 2)
  (finally 0)

  ;; binding forms
  (let 1)
  (letfn '(1 ((:defn)) nil))
  (binding 1)
  (loop 1)
  (for 1)
  (doseq 1)
  (dotimes 1)
  (when-let 1)
  (if-let 1)
  (when-some 1)
  (if-some 1)
  (this-as 1) ; ClojureScript

  (defmethod :defn)

  ;; clojure.test
  (testing 1)
  (deftest :defn)
  (are 2)
  (use-fixtures :defn)

  ;; core.logic
  (run :defn)
  (run* :defn)
  (fresh :defn)

  ;; core.async
  (alt! 0)
  (alt!! 0)
  (go 0)
  (go-loop 1)
  (thread 0))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Better docstring filling for clojure-mode
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun clojure-string-start (&optional regex)
  "Return the position of the \" that begins the string at point.
If REGEX is non-nil, return the position of the # that begins the
regex at point.  If point is not inside a string or regex, return
nil."
  (when (nth 3 (syntax-ppss)) ;; Are we really in a string?
    (save-excursion
      (save-match-data
        ;; Find a quote that appears immediately after whitespace,
        ;; beginning of line, hash, or an open paren, brace, or bracket
        (re-search-backward "\\(\\s-\\|^\\|#\\|(\\|\\[\\|{\\)\\(\"\\)")
        (let ((beg (match-beginning 2)))
          (when beg
            (if regex
                (and (char-before beg) (char-equal ?# (char-before beg)) (1- beg))
              (when (not (char-equal ?# (char-before beg)))
                beg))))))))

(defun clojure-char-at-point ()
  "Return the char at point or nil if at buffer end."
  (when (not (= (point) (point-max)))
    (buffer-substring-no-properties (point) (1+ (point)))))

(defun clojure-char-before-point ()
  "Return the char before point or nil if at buffer beginning."
  (when (not (= (point) (point-min)))
    (buffer-substring-no-properties (point) (1- (point)))))

(defun clojure-toggle-keyword-string ()
  "Convert the string or keyword at point to keyword or string."
  (interactive)
  (let ((original-point (point)))
    (while (and (> (point) 1)
                (not (equal "\"" (buffer-substring-no-properties (point) (+ 1 (point)))))
                (not (equal ":" (buffer-substring-no-properties (point) (+ 1 (point))))))
      (backward-char))
    (cond
     ((equal 1 (point))
      (error "Beginning of file reached, this was probably a mistake"))
     ((equal "\"" (buffer-substring-no-properties (point) (+ 1 (point))))
      (insert ":" (substring (clojure-delete-and-extract-sexp) 1 -1)))
     ((equal ":" (buffer-substring-no-properties (point) (+ 1 (point))))
      (insert "\"" (substring (clojure-delete-and-extract-sexp) 1) "\"")))
    (goto-char original-point)))

(defun clojure-delete-and-extract-sexp ()
  "Delete the sexp and return it."
  (interactive)
  (let ((begin (point)))
    (forward-sexp)
    (let ((result (buffer-substring-no-properties begin (point))))
      (delete-region begin (point))
      result)))



(defun clojure-project-dir (&optional dir-name)
  "Return the absolute path to the project's root directory.

Use `default-directory' if DIR-NAME is nil.
Return nil if not inside a project."
  (let* ((dir-name (or dir-name default-directory))
         (choices (delq nil
                        (mapcar (lambda (fname)
                                  (locate-dominating-file dir-name fname))
                                clojure-build-tool-files))))
    (when (> (length choices) 0)
      (car (sort choices #'file-in-directory-p)))))

(defun clojure-project-relative-path (path)
  "Denormalize PATH by making it relative to the project root."
  (file-relative-name path (clojure-project-dir)))

(defun clojure-expected-ns (&optional path)
  "Return the namespace matching PATH.

PATH is expected to be an absolute file path.

If PATH is nil, use the path to the file backing the current buffer."
  (let* ((path (or path (file-truename (buffer-file-name))))
         (relative (clojure-project-relative-path path))
         (sans-file-type (substring relative 0 (- (length (file-name-extension path t)))))
         (sans-file-sep (mapconcat 'identity (cdr (split-string sans-file-type "/")) "."))
         (sans-underscores (replace-regexp-in-string "_" "-" sans-file-sep)))
    ;; Drop prefix from ns for projects with structure src/{clj,cljs,cljc}
    (replace-regexp-in-string "\\`clj[scx]?\\." "" sans-underscores)))

(defun clojure-insert-ns-form-at-point ()
  "Insert a namespace form at point."
  (interactive)
  (insert (format "(ns %s)" (clojure-expected-ns))))

(defun clojure-insert-ns-form ()
  "Insert a namespace form at the beginning of the buffer."
  (interactive)
  (widen)
  (goto-char (point-min))
  (clojure-insert-ns-form-at-point))

(defun clojure-update-ns ()
  "Update the namespace of the current buffer.
Useful if a file has been renamed."
  (interactive)
  (let ((nsname (clojure-expected-ns)))
    (when nsname
      (save-excursion
        (save-match-data
          (if (clojure-find-ns)
              (replace-match nsname nil nil nil 4)
            (error "Namespace not found")))))))

(defconst clojure-namespace-name-regex
  (rx line-start
      "("
      (zero-or-one (group (regexp "clojure.core/")))
      (zero-or-one (submatch "in-"))
      "ns"
      (zero-or-one "+")
      (one-or-more (any whitespace "\n"))
      (zero-or-more (or (submatch (zero-or-one "#")
                                  "^{"
                                  (zero-or-more (not (any "}")))
                                  "}")
                        (zero-or-more "^:"
                                      (one-or-more (not (any whitespace)))))
                    (one-or-more (any whitespace "\n")))
      (zero-or-one (any ":'")) ;; (in-ns 'foo) or (ns+ :user)
      (group (one-or-more (not (any "()\"" whitespace))) symbol-end)))

(defun clojure-find-ns ()
  "Return the namespace of the current Clojure buffer.
Return the namespace closest to point and above it.  If there are
no namespaces above point, return the first one in the buffer."
  (save-excursion
    (save-restriction
      (widen)
      ;; The closest ns form above point.
      (when (or (re-search-backward clojure-namespace-name-regex nil t)
                ;; Or any form at all.
                (and (goto-char (point-min))
                     (re-search-forward clojure-namespace-name-regex nil t)))
        (match-string-no-properties 4)))))

(defconst clojure-def-type-and-name-regex
  (concat "(\\(?:\\(?:\\sw\\|\\s_\\)+/\\)?"
          ;; Declaration
          "\\(def\\(?:\\sw\\|\\s_\\)*\\)\\>"
          ;; Any whitespace
          "[ \r\n\t]*"
          ;; Possibly type or metadata
          "\\(?:#?^\\(?:{[^}]*}\\|\\(?:\\sw\\|\\s_\\)+\\)[ \r\n\t]*\\)*"
          ;; Symbol name
          "\\(\\(?:\\sw\\|\\s_\\)+\\)"))

(defun clojure-find-def ()
  "Find the var declaration macro and symbol name of the current form.
Returns a list pair, e.g. (\"defn\" \"abc\") or (\"deftest\" \"some-test\")."
  (save-excursion
    (unless (looking-at clojure-def-type-and-name-regex)
      (beginning-of-defun))
    (when (search-forward-regexp clojure-def-type-and-name-regex nil t)
      (list (match-string-no-properties 1)
            (match-string-no-properties 2)))))


;;; Sexp navigation
(defun clojure--looking-at-non-logical-sexp ()
  "Return non-nil if sexp after point represents code.
Sexps that don't represent code are ^metadata or #reader.macros."
  (comment-normalize-vars)
  (comment-forward (point-max))
  (looking-at-p "\\^\\|#[?[:alpha:]]"))

(defun clojure-forward-logical-sexp (&optional n)
  "Move forward N logical sexps.
This will skip over sexps that don't represent objects, so that ^hints and
#reader.macros are considered part of the following sexp."
  (interactive "p")
  (unless n (setq n 1))
  (if (< n 0)
      (clojure-backward-logical-sexp (- n))
    (let ((forward-sexp-function nil))
      (while (> n 0)
        (while (clojure--looking-at-non-logical-sexp)
          (forward-sexp 1))
        ;; The actual sexp
        (forward-sexp 1)
        (setq n (1- n))))))

(defun clojure-backward-logical-sexp (&optional n)
  "Move backward N logical sexps.
This will skip over sexps that don't represent objects, so that ^hints and
#reader.macros are considered part of the following sexp."
  (interactive "p")
  (unless n (setq n 1))
  (if (< n 0)
      (clojure-forward-logical-sexp (- n))
    (let ((forward-sexp-function nil))
      (while (> n 0)
        ;; The actual sexp
        (backward-sexp 1)
        ;; Non-logical sexps.
        (while (and (not (bobp))
                    (ignore-errors
                      (save-excursion
                        (backward-sexp 1)
                        (clojure--looking-at-non-logical-sexp))))
          (backward-sexp 1))
        (setq n (1- n))))))

(defconst clojurescript-font-lock-keywords
  (eval-when-compile
    `(;; ClojureScript built-ins
      (,(concat "(\\(?:\.*/\\)?"
                (regexp-opt '("js-obj" "js-delete" "clj->js" "js->clj"))
                "\\>")
       0 font-lock-builtin-face)))
  "Additional font-locking for `clojurescrip-mode'.")

;;;###autoload
(define-derived-mode clojurescript-mode clojure-mode "ClojureScript"
  "Major mode for editing ClojureScript code.

\\{clojurescript-mode-map}"
  (font-lock-add-keywords nil clojurescript-font-lock-keywords))

;;;###autoload
(define-derived-mode clojurec-mode clojure-mode "ClojureC"
  "Major mode for editing ClojureC code.

\\{clojurec-mode-map}")

(defconst clojurex-font-lock-keywords
  ;; cljx annotations (#+clj and #+cljs)
  '(("#\\+cljs?\\>" 0 font-lock-preprocessor-face))
  "Additional font-locking for `clojurex-mode'.")

;;;###autoload
(define-derived-mode clojurex-mode clojure-mode "ClojureX"
  "Major mode for editing ClojureX code.

\\{clojurex-mode-map}"
  (font-lock-add-keywords nil clojurex-font-lock-keywords))

;;;###autoload
(progn
  (add-to-list 'auto-mode-alist
               '("\\.\\(clj\\|dtm\\|edn\\)\\'" . clojure-mode))
  (add-to-list 'auto-mode-alist '("\\.cljc\\'" . clojurec-mode))
  (add-to-list 'auto-mode-alist '("\\.cljx\\'" . clojurex-mode))
  (add-to-list 'auto-mode-alist '("\\.cljs\\'" . clojurescript-mode))
  ;; boot build scripts are Clojure source files
  (add-to-list 'auto-mode-alist '("\\(?:build\\|profile\\)\\.boot\\'" . clojure-mode)))

(provide 'clojure-mode)

;; Local Variables:
;; coding: utf-8
;; End:

;;; clojure-mode.el ends here
