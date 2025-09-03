;;; lsl-mode.el --- A LSL mode with font lock support

;;; Copyright (C) 1998 Gary T. Leavens

;;; Author: Gary T. Leavens <leavens@cs.iastate.edu>
;;; Keywords: LSL, Larch Shared Language, faces, files
;;; Version: $Revision: 1.3 $ of $Date: 1998/01/31 18:18:47 $

;;; lsl-mode.el is free software distributed under the terms of the GNU
;;; General Public License, version 2.  However, note that this license
;;; does not require specifications, or the code specified by such
;;; specfications, to be made freely available.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Emacs; see the file COPYING.  If not, write to the Free
;;; Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
;;; 02111-1307, USA.

;;; lsl-mode.el is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.

;;; This file is not (yet) a part of GNU Emacs.

;;; This file was probably obtained from the following URL:
;;;   ftp://ftp.cs.iastate.edu/pub/larch/lsl-mode.el

;;; Commentary:

;; Purpose:
;;
;; To provide a helpful emacs mode to browse and edit LSL files, with
;; support for fontification of standard LSL keywords, symbols,
;; functions, etc.
;;
;; Installation:
;;
;; Put in your ~/.emacs:
;;
;;    (setq auto-mode-alist
;;          (append auto-mode-alist
;;                  '(("\\.lsl$"  . lsl-mode))))
;;    (autoload 'lsl-mode "lsl-mode"
;;       "Major mode for editing LSL traits." t)
;;
;; with `lsl-mode.el' accessible somewhere on the load-path.
;; To add a directory `~/emacs' (for example) to the load-path,
;; add the following to .emacs:
;;
;;    (setq load-path (cons "~/emacs" load-path))
;;
;; To turn font locking on for all LSL buffers, add this to .emacs:
;;
;; (add-hook 'lsl-mode-hook (lambda () (if window-system (turn-on-font-lock))))
;;
;;
;; Customization:
;;
;; The following faces color the LSL traits:
;;
;;   lsl-keyword-face      for reserved keywords and syntax,
;;   lsl-operator-face     for symbolic and alphanumeric operators,
;;   lsl-comment-face      for comments, and
;;   lsl-default-face      for ordinary specs.
;;
;; The faces are initialised to the following font lock defaults:
;;
;;   lsl-keyword-face      font-lock-keyword-face
;;   lsl-operator-face     font-lock-function-name-face
;;   lsl-comment-face      font-lock-comment-face
;;   lsl-default-face      <default face>
;;
;; To alter an attribute of a face, add a hook, for example: to change
;; the foreground color of operators to black, add the following line
;; to .emacs:
;;
;;   (add-hook 'lsl-mode-hook
;;       (lambda ()
;;           (set-face-foreground 'lsl-operator-face "black")))
;;
;; Note that the colors available vary from system to system.  To see
;; what colors are available on your system, call
;; `list-colors-display' from emacs.
;;
;;
;; History:
;;
;; Based on Graeme E. Moss and Tommy Thorn's Haskell mode
;; (haskell-mode.el).
;;
;; If you have any problems or suggestions, after consulting the list of
;; limitations/future work below, email leavens@cs.iastate.edu.  If you
;; have a problem, please quote the version of the mode you are using, and
;; give a small example of it.  Note that font locking requires a
;; reasonably recent version of Emacs.
;;
;; Present Limitations/Future Work:
;;
;; . Simple indentation cycling through previous levels of indentation
;;   would be helpful.  Currently, indentation is only possible to the
;;   previous line's first non-whitespace character.
;;
;; . Nothing special is done for the tupling operator ([]),
;;   since it's also used in sort parameters (Foo[T]).  It's possible to
;;   change the definitions in lsl-font-lock-defaults-create below
;;   to make square brackets either be considered an operator or
;;   a reserved symbol, but neither seems right all the time...
;;
;; . This supports ISO characters, which isn't currently right for LSL...

;;; Firstly, the simple LSL mode that will call lsl-font-lock.

;; Mode map.
(defvar lsl-mode-map ()
  "Keymap used in LSL mode.")

(if (not lsl-mode-map)
    (progn
      (setq lsl-mode-map (make-sparse-keymap))
      (define-key lsl-mode-map "\C-c\C-c" 'font-lock-fontify-buffer)))

;; Various mode variables.
(defun lsl-vars ()
  (kill-all-local-variables)
  (make-local-variable 'paragraph-start)
  (setq paragraph-start (concat "^$\\|" page-delimiter))
  (make-local-variable 'paragraph-separate)
  (setq paragraph-separate paragraph-start)
  (make-local-variable 'comment-start)
  (setq comment-start "%")
  (make-local-variable 'comment-column)
  (setq comment-column 40)
  (make-local-variable 'comment-indent-function)
  (setq comment-indent-function 'lsl-comment-indent)
  (make-local-variable 'comment-end)
  (setq comment-end "")
  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'lsl-indent-line)
  )


;;; The main mode functions
(defun lsl-mode ()
  "Major mode for editing LSL programs.  Last adapted for LSL 3.1.
Blank lines separate paragraphs, comments start with '%'.
M-; will place a comment at an appropriate place on the current line.
Use Linefeed to do a newline and indent to the level of the previous line.
Tab will place the cursor or the first non-whitespace character of the
current line to the level of indentation of the previous line.
C-c C-c re-colors the buffer if font lock is enabled.

Entry to this mode calls the value of lsl-mode-hook if non-nil.

Uses `lsl-font-lock' for font locking.  See documentation on this
command for information about font locking."
  (interactive)
  (lsl-vars)
  (setq major-mode 'lsl-mode)
  (setq mode-name "LSL")
  (use-local-map lsl-mode-map)
  (if window-system (lsl-font-lock))
  (run-hooks 'lsl-mode-hook))

;; Find the indentation level for a comment..
(defun lsl-comment-indent ()
  (skip-chars-backward " \t")
  ;; if the line is blank, put the comment at the beginning,
  ;; else at comment-column
  (if (bolp) 0 (max (1+ (current-column)) comment-column)))

;; Indent according to the previous line's indentation.
;; Don't forget to use 'indent-tabs-mode' if you require tabs to be used
;; for indentation.
(defun lsl-indent-line ()
  (interactive)
  (let ((c 0))
    (save-excursion
      (forward-line -1)
      (back-to-indentation)
      (setq c (if (eolp) 0 (current-column))))
    (indent-line-to c))         ;ident line to this level
  )



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Support for font-lock-mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar lsl-font-lock-keywords ()
  "Patterns used in font locking for LSL mode.")

;;; The font lock regular expressions.
(defun lsl-font-lock-defaults-create ()
  "Makes local variable `font-lock-defaults' suitable for LSL font locking.

See `lsl-font-lock'."
  (let* (;; Some of these definitions have been superseded by using the
         ;; syntax table instead.

         (ISOlarge   "\300-\326\330-\337")
         (ISOsmall   "\340-\366\370-\377")
         (small      (concat "a-z" ISOsmall))
         (large      (concat "A-Z" ISOlarge))
         (alphabetic (concat small large))

         (idChars    (concat "[" alphabetic "0-9'_]+"))
         (varid      (concat "\\b\\([" idChars "\\)\\b"))

         (opChar     "-~=+*/|<>#$&!@?")
         ;; Put the minus sign above first to make it work in ranges.
         (lsl_op
          (concat "\\("
                  "\\([" opChar "]+\\)"
                  "\\|\\(\\\\[" idChars "\\)" ; for \foo
                  "\\|\\(\\\\[<>/]\\)"        ; for \<, \>, and \/
                  "\\|[{}\\\\]"               ; for {,} and the \ in /\
                  "\\)"
                  ))

         ;; The following two could perhaps be optimized to run faster...
         (reservedsym
          (concat "\\b\\("
                  "\\\\A\\|\\\\E\\|\\\\eq\\|\\\\neq\\|\\\\equals"
                  "\\|\\\\forall\\|\\\\arrow\\|->\\|\\\\marker"
                  "\\|[~=]?="
                  "\\)\\b"))
         (reservedid
          (concat "\\b\\("
                  "asserts\\|assumes\\|by\\|converts\\|else"
                  "\\|enumeration\\|equations\\|exempting\\|for\\|forall"
                  "\\|formulas\\|freely\\|generated\\|if\\|implies\\|includes"
                  "\\|introduces\\|of\\|partitioned\\|sort\\|then\\|trait"
                  "\\|tuple\\|union\\|with"
                  "\\)\\b"))
         )

    (progn
      (make-local-variable 'lsl-font-lock-keywords)
      (setq lsl-font-lock-keywords
            `(
              ;; NOTICE that the ordering below is significant!
              ;; Also, this is in a backquoted list, so you have to use
              ;; ,x to insert the value of a variable x.
              ("%.*$" 0 'lsl-comment-face t)
              (,lsl_op 0 (cond
                          ((string-match ,reservedsym (match-string 0))
                           'lsl-keyword-face)
                          (t 'lsl-operator-face)))
              (,reservedid 1 'lsl-keyword-face)
              ))
      (make-local-variable 'font-lock-defaults)
      (setq font-lock-defaults '(lsl-font-lock-keywords nil nil))
      )
    )
  )

;; Faces required for font locking.
(defun lsl-faces ()
  "Defines faces required for LSL font locking.

See `lsl-font-lock'."

  ;; XEmacs does not have a simple function for making the faces but
  ;; makes them when `require'd which was done by lsl-font-lock,
  ;; so we don't need to explicitly make them for XEmacs, and in fact
  ;; we shouldn't as an error will be produced.
  (if (fboundp 'font-lock-make-faces) (font-lock-make-faces))
  (copy-face 'font-lock-keyword-face 'lsl-keyword-face)
  (copy-face 'font-lock-comment-face 'lsl-operator-face)
  (copy-face 'font-lock-comment-face 'lsl-comment-face)
  (copy-face 'default 'lsl-default-face)
  )

;; Syntax required for font locking.
(defun lsl-syntax ()
  "Changes the current buffer's syntax table to suit LSL font locking.

See `lsl-font-lock'."
  (progn
    (set-syntax-table (make-syntax-table))
    (modify-syntax-entry ?   " ")    ; whitespace
    (modify-syntax-entry ?\t " ")
    (modify-syntax-entry ?\r " ")
    (modify-syntax-entry ?\" " ")
    (modify-syntax-entry ?\' "w")    ; word constitutents
    (modify-syntax-entry ?_  "w")
    (modify-syntax-entry ?\( "()")   ; open-parentheses, with end matching
    (modify-syntax-entry ?\) ")(")   ; close-parentheses, with start matching
    (modify-syntax-entry ?[  "(]")
    (modify-syntax-entry ?]  ")[")
    (modify-syntax-entry ?{  "(}")
    (modify-syntax-entry ?}  "){")
    (modify-syntax-entry ?%  "){")   ; comment start
    (modify-syntax-entry ?\n ">")    ; comment end
    (mapcar (lambda (x)
              (modify-syntax-entry x "_")) ; symbol constitutent
            "-~=+*/|<>#$&!@?\\")
    )
  )

(defun lsl-font-lock ()
  "Allows font-lock-mode to support font locking of LSL traits on
current buffer.

Changes the current buffer's `font-lock-defaults' and syntax table, and
adds the following faces:

   lsl-keyword-face      for reserved keywords and syntax,
   lsl-operator-face     for symbolic and alphanumeric operators,
   lsl-comment-face      for comments, and
   lsl-default-face      for ordinary code.

The faces are initialised to the following font lock defaults:

   lsl-keyword-face      font-lock-keyword-face
   lsl-operator-face     font-lock-function-name-face
   lsl-comment-face      font-lock-comment-face
   lsl-default-face      <default face>

To alter an attribute of a face, add a hook, for example: to change
the foreground color of operators to black, add the following lines
to .emacs:

  (add-hook 'lsl-mode-hook
      (lambda ()
          (set-face-foreground 'lsl-operator-face \"black\")))

Note that the colors available vary from system to system.  To see
what colors are available on your system, call
`list-colors-display' from emacs.

To turn font locking on for all LSL buffers, add this to .emacs:

  (add-hook 'lsl-mode-hook (lambda () (if window-system (turn-on-font-lock))))

To turn font locking on or off for the current buffer, call `font-lock-mode'.
"

  (interactive)
  (require 'font-lock)
  (lsl-syntax)
  (lsl-faces)
  (lsl-font-lock-defaults-create)
  )


;;; Provide ourselves:

(provide 'lsl-mode)

;;; lsl-mode.el ends here
