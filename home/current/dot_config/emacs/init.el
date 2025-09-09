;cperl-electric-backspace           cperl-electric-brace
;cperl-electric-lbrace              cperl-electric-paren
;cperl-electric-rparen              cperl-electric-semi
;cperl-electric-terminator

;(local-set-key ";" 'self-insert-command)
;(local-set-key "{" 'self-insert-command)
;(local-set-key "}" 'self-insert-command)
;;(local-set-key "(" 'self-insert-command)
;;(local-set-key ")" 'self-insert-command)

;;(load "/afs/andrew/scs/cs/15-212/data/emacs-15-212")
;; Ensure site-lisp is added relative to this init.el location
(let* ((this-file-dir (file-name-directory (or load-file-name buffer-file-name)))
       (site-lisp-dir (expand-file-name "site-lisp" this-file-dir)))
  (when (file-directory-p site-lisp-dir)
    (add-to-list 'load-path site-lisp-dir)))
;; Needed for `loop` macro used below
(eval-when-compile (require 'cl))

(defun restart-servers () "Restart gnuserv & emacsserver"
  (interactive)
  (if (fboundp 'gnuserv-start) (gnuserv-start) (message "no gnuserv-start"))
  (setq gnuserv-frame t)        ; don't open a new frame, use the main one
  (if (fboundp 'server-start) (server-start) (message "no server-start"))
  )

;(message "test %s" "zot")
(restart-servers)

(auto-compression-mode t)               ; let me open .gz files
(font-lock-mode t)
(column-number-mode t)

(when (display-graphic-p)
  (set-background-color "black")
  (set-foreground-color "white")
  (set-cursor-color "green"))

(setq backup-by-copying t)
;; (setq backup-by-copying-when-linked t)
;; (setq backup-by-copying-when-mismatch t)
;; (setq backup-by-copying-when-privileged-mismatch 200)
(flyspell-mode t)

(require 'uniquify)
(setq
  uniquify-buffer-name-style 'post-forward
  uniquify-separator ":")

(defun light-bg () "dark text on light background"
  (interactive)
  (set-background-color "white")
  (set-foreground-color "black")
  (set-cursor-color "green")
  )

(defun dark-bg () "light text on dark background"
  (interactive)
  (set-background-color "black")
  (set-foreground-color "white")
  (set-cursor-color "green")
  )

;; Stroustrup-style coding standard
(defun my-c-mode-common-hook ()
  ;; use Stroustrup style for all C, C++, and Objective-C code
  (c-set-style "stroustrup")
  (setq c-label-minimum-indentation 1)  ; get rid of space before labels
  (setq c-block-comments-indent-p 4)    ; commenting style
  )
(add-hook 'c-mode-common-hook 'my-c-mode-common-hook)

;; Displays the name of the file being edited in the title bar.
;; (setq frame-title-format "%b")
; %b - buffer name
; %c - column number
; %f - filename (full path)
; %l - line number
; %m - mode
; %p - "Top"
; %s - "no process"
; %t - "T"
; %F - "Emacs"
; %P - "Top25%" or "Bottom"
; %Z - "-:"
(setq frame-title-format
      (concat "%b - " (getenv "USER") "@" (getenv "HOST")
              " ::--::  Escape-Meta-Alt-Control-Shift  ::--:: "
              (getenv "USER") "@" (getenv "HOST") " - %b"))

(setq-default fill-column 74)           ; set line length
(if (fboundp 'blink-cursor-mode) (blink-cursor-mode nil)) ; no cursor blink
(show-paren-mode t)                     ; auto show matching parens
(setq-default tab-width 4 indent-tabs-mode nil) ; use spaces not tabs
(setq-default x-stretch-cursor t)       ; reveal tab when under the cursor

;; Whitespace cleanup
;;(load-library "whitespace.el")
;;(setq whitespace-check-buffer-indent nil)

(defun my-cleanup-buffer ()
  "reindent buffer and clean up trailing whitespace"
  (interactive)
  (mark-whole-buffer)
  ;; (whitespace-cleanup)
  (indent-region)
  )

;; keyboard shortcuts
(global-set-key "\M-%" 'query-replace-regexp) ;default is 'query-replace
(global-set-key "\M-g" 'goto-line)
(global-set-key "\C-m" 'newline-and-indent)
(global-set-key "\C-x\C-e" 'eval-current-buffer)

(global-set-key "\C-l" 'recenter)
(global-set-key "\C-y" 'yank)

;;(global-set-key "\E 'left" 'backward-word)
;;(global-set-key "\E 'right" 'forward-word)

; make the keypad arrows work just like the regular arrows
(global-set-key [C-kp-right] 'forward-word)
(global-set-key [C-kp-left]  'backward-word)
(global-set-key [C-kp-up]    'backward-paragraph)
(global-set-key [C-kp-down]  'forward-paragraph)
(global-set-key [C-kp-home]  'beginning-of-buffer)
(global-set-key [C-kp-end]   'end-of-buffer)

; disable overwrite mode and disable the key that might turn it back on
(overwrite-mode 0)
(global-unset-key [insert])

;;(global-set-key "delete" 'delete-char)
(global-set-key [f1] 'help-for-help)             ; F1
(global-set-key [f2] 'execute-extended-command)  ; F2
(global-set-key [f3] 'isearch-forward)           ; F3
(global-set-key [S-f3] 'isearch-backward)        ; Shift-F3
(global-set-key [f4] 'undo)                      ; F4
;;(global-set-key [f5] 'revert-buffer)             ; F5
;;(global-set-key [f6] 'query-replace)             ; F6
;;(global-set-key [f7] 'overwrite-mode)            ; F7
;;(global-set-key [f8] 'sd-edit)                   ; F8
;;(global-set-key [S-f8] 'sd-unedit)               ; Shift-F8
;;(global-set-key [f9] 'sd-get)                    ; F9
;;(global-set-key [S-f9] 'sd-get-latest)           ; Shift-F9
;;(global-set-key [f10] 'compare-windows)          ; F10
;;(global-set-key [f11] 'font-lock-mode)           ; F11
;;(global-set-key [f12] 'hilit-rehighlight-buffer) ; F12
(global-set-key [S-f12] 'my-cleanup-buffer) ; Shift-F12

;; normally C-x C-q would be set to vc-toggle-read-only
(global-set-key "\C-x\C-q" 'toggle-read-only)

;; don't let me accidentally exit out of emacs
;; use "M-x kill-emacs" instead
(global-unset-key "\C-x\C-c")

;; from: http://www.emacswiki.org/emacs/HideShow
(defun toggle-selective-display (column)
  (interactive "P")
  (set-selective-display
   (or column
       (unless selective-display
         (1+ (current-column)))))
  )

(defun toggle-hiding (column)
  (interactive "P")
  (if hs-minor-mode
      (if (condition-case nil
              (hs-toggle-hiding)
            (error t))
          (hs-show-all))
    (toggle-selective-display column))
  )


(defun ajy-hs-keys ()
  (interactive)
  (local-set-key (kbd "C-c <right>") 'hs-show-block)
  (local-set-key (kbd "C-c <left>")  'hs-hide-block)
  (local-set-key (kbd "C-c <up>")    'hs-hide-all)
  (local-set-key (kbd "C-c <down>")  'hs-show-all)
  )

(global-set-key (kbd "C-+") 'toggle-hiding)
(global-set-key (kbd "C-\\") 'toggle-selective-display)
(add-hook 'c-mode-common-hook   'hs-minor-mode)
(add-hook 'c-mode-common-hook   'hide-ifdef-mode)
(add-hook 'emacs-lisp-mode-hook 'hs-minor-mode)
(add-hook 'java-mode-hook       'hs-minor-mode)
(add-hook 'lisp-mode-hook       'hs-minor-mode)
(add-hook 'perl-mode-hook       'hs-minor-mode)
(add-hook 'cperl-mode-hook      'hs-minor-mode)
(add-hook 'sh-mode-hook         'hs-minor-mode)

(add-hook 'hs-minor-mode-hook      'ajy-hs-keys)

;(global-set-key "\C-{" 'hs-hide-block)
;(global-set-key "\C-}" 'hs-show-block)
;(global-set-key "\C-<" 'hs-hide-all)
;(global-set-key "\C->" 'hs-show-all)

;(require 'org-install) ; not sure this is needed...
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))
(add-to-list 'auto-mode-alist '("/todo.txt\\'" . org-mode))
(define-key global-map "\C-cl" 'org-store-link)
(define-key global-map "\C-ca" 'org-agenda)
(setq org-log-done t)

;; untabify helpers
(defun untabify-buffer ()
  (interactive)
  (untabify 1 (buffer-size)))

(defun untabify-and-save-buffer ()
  (interactive)
  (untabify 1 (buffer-size))
  (save-buffer))

;; at Overture, I want to invoke gcp on pretty much every file I edit
(defun save-and-copy-buffer ()
  (interactive)
  (save-buffer)
  (shell-command (concat "~/bin/gcp -q -q \""
                         (buffer-file-name (current-buffer)) "\""))
  (kill-buffer "*Shell Command Output*")
  )

(defun overture-save-buffer ()
  (interactive)
  (global-set-key "\C-x\C-s" 'save-and-copy-buffer)
  )

;; download a url and open it in a buffer
(defun web-open ()
  (interactive)
  ;; ensure that our shell-command buffer is empty
  (shell-command "cat")
  (kill-buffer "*Shell Command Output*")

  (setq url (read-from-minibuffer "URL to open: "))
  (shell-command (concat "wget " url " -O - 2> /dev/null"))

  (switch-to-buffer "*Shell Command Output*")
  (rename-buffer url)
  (delete-other-windows)
  )

;; Bindings for tty sessions of arrow keys.
(if (not window-system) ;; Only use in tty-sessions.
    (progn
      (defvar arrow-keys-map (make-sparse-keymap) "Keymap for arrow keys")
      (define-key esc-map "O" arrow-keys-map)
      (define-key arrow-keys-map "A" 'previous-line)
      (define-key arrow-keys-map "B" 'next-line)
      (define-key arrow-keys-map "C" 'forward-char)
      (define-key arrow-keys-map "D" 'backward-char)))

;; (duplicate definitions removed; see helpers above)

(defun save-tabs ()
  (interactive)
  (global-set-key "\C-x\C-s" 'save-buffer)
  )

(defun dont-save-tabs ()
  (interactive)
  (global-set-key "\C-x\C-s" 'untabify-and-save-buffer)
  )

(defun goto-and-indent-line (l)
  (goto-line l)
  (indent-for-tab-command)
  )

(defun goto-and-indent-a-whole-bunch-of-lines (start end)
  (if (not (> start end))
      (loop for x from start to end
            do (goto-and-indent-line x)
            )
;;      (progn
;;        (goto-and-indent-line start)
;;        (goto-and-indent-a-whole-bunch-of-lines (+ start 1) end)
;;        )
    )
  )

;; re-indent the entire buffer using c++-indent-command
;;
;; TO DO: (buffer-size) actually returns the number of bytes (characters?)
;; in the buffer.  What I want is the number of lines in the buffer.  How
;; can I get that?  Possibly something with (mark-whole-buffer) and
;; (count-lines-region)?  Or possibly just querying the current line after
;; I've moved to a line, and seeing if I'm where I think I've moved to
;; (i.e. if I'm at the end of the buffer, moving forward won't actually
;; move me).
(defun indent-whole-buffer-command ()
  (interactive)
  (save-excursion
    (mark-whole-buffer)
    (goto-and-indent-a-whole-bunch-of-lines 1 (buffer-size))
    )
  )

(when (ignore-errors (require 'xcscope))
  (setq cscope-do-not-update-database nil)

  (defun my-find-tag(&optional prefix)
    "union of `find-tag' alternatives. decides upon major-mode"
    (interactive "P")
    (if (and (boundp 'cscope-minor-mode)
             cscope-minor-mode)
        (progn
          (ring-insert find-tag-marker-ring (point-marker))
          (call-interactively 'cscope-find-this-symbol))
      (call-interactively 'find-tag)))
  ;;(substitute-key-definition 'find-tag 'my-find-tag  global-map)
  (substitute-key-definition 'find-tag 'cscope-find-this-symbol global-map)

  ;; From Dima:
  ;; different in that I bury the default buffer.  Specifying it didn't work
  ;; for some reason
  (defun cscope-bury-buffer-hacked ()
    "Clean up cscope, if necessary, and bury the buffer"
    (interactive)
    (let ()
      (when overlay-arrow-position
        (set-marker overlay-arrow-position nil))
      (setq overlay-arrow-position nil
            overlay-arrow-string nil)
      (bury-buffer)))
  (with-eval-after-load 'xcscope
    (define-key cscope-list-entry-keymap (kbd "q")
      'cscope-bury-buffer-hacked))

  ;; From Dima:
  ;; cscope: extra key mapping. opens entry in the window the cscope buffer
  ;; is in
  (defun cscope-select-entry-and-bury ()
    "Display the entry, switching cscope's window to that buffer if necessary"
    (interactive)
    (let ((file (get-text-property (point) 'cscope-file))
          (line-number (get-text-property (point) 'cscope-line-number)))
      (cscope-show-entry-internal file line-number t (selected-window))))
  (with-eval-after-load 'xcscope
    (define-key cscope-list-entry-keymap (kbd "<C-return>")
      'cscope-select-entry-and-bury)))


;; Ensure C/C++ mode available
(require 'cc-mode)
; for zigbee.def files
(setq auto-mode-alist
      (append '(("\\.def\\'" . c++-mode)) auto-mode-alist))

(setq auto-mode-alist
      (append '(("\\.c\\'" . c++-mode) ("\\.C\\'" . c++-mode)
                ("\\.h\\'" . c++-mode) ("\\.inl\\'" . c++-mode)
                ("\\.v\\'" . verilog-mode))
              auto-mode-alist))

(setq auto-mode-alist
      (append '(("\\.pl\\'" . cperl-mode) ("\\.pm\\'" . cperl-mode)
                ("\\.tdy\\'" . cperl-mode) ("\\.data\\'" . cperl-mode))
              auto-mode-alist))

(setq auto-mode-alist
      (append '(("\\.xsd\\'" . nxml-mode))
              auto-mode-alist))

(setq cperl-brace-offset 0)

(require 'yicf-mode)
(setq auto-mode-alist
      (append '(("\\.yicf\\'" . yicf-mode) ("\\.yicf\\.in\\'" . yicf-mode))
              auto-mode-alist))

(require 'graphviz-dot-mode)
(setq auto-mode-alist
      (append '(("\\.gv\\'" . graphviz-dot-mode))
              auto-mode-alist))

(setq auto-mode-alist
      (append '(("\\.m\\'" . octave-mode))
              auto-mode-alist))


;; Options Menu Settings
;; =====================
(cond
 ((and (string-match "XEmacs" emacs-version)
       (boundp 'emacs-major-version)
       (or (and
            (= emacs-major-version 19)
            (>= emacs-minor-version 14))
           (= emacs-major-version 20))
       (fboundp 'load-options-file))
  (load-options-file "~/.xemacs-options")))
;; ============================
;; End of Options Menu Settings


(custom-set-variables
  ;; custom-set-variables was added by Custom -- don't edit or cut/paste it!
  ;; Your init file should contain only one such instance.
 '(c++-font-lock-extra-types (quote ("\\sw+_t" "\\([iof]\\|str\\)+stream\\(buf\\)?" "ios" "string" "rope" "list" "slist" "deque" "vector" "bit_vector" "set" "multiset" "map" "multimap" "hash\\(_\\(m\\(ap\\|ulti\\(map\\|set\\)\\)\\|set\\)\\)?" "stack" "queue" "priority_queue" "type_info" "iterator" "const_iterator" "reverse_iterator" "const_reverse_iterator" "reference" "const_reference" "HRESULT" "POTOKEN" "[PUL]*\\([QD]\\)?WORD\\(_PTR\\)?\\([\\&\\*]\\)*" "GUID\\(_PTR\\)?\\([\\&\\*]\\)*" "[PUL]*LONG\\(LONG\\)?\\([\\&\\*]\\)*" "\\(W\\|OLE\\|L\\|LP\\|LPC\\)*\\(CHAR\\|STR\\)\\([\\&\\*]\\)*" "DATE\\([\\&\\*]\\)*" "\\(DATE\\|FILE\\|SYSTEM\\)?\\(TIME\\)?\\([\\&\\*]\\)*" "SID\\([\\&\\*]\\)*" "BOOL\\([\\&\\*]\\)*" "LONG\\([\\&\\*]\\)*" "OWS[A-Z_\\-]+\\([\\&\\*]\\)*" "[C\\|I][A-Z]+[a-z]+[a-zA-Z0-9]*\\([\\&\\*]\\)*" "[V][a-z]+[a-zA-Z_0-9]*\\([\\&\\*]\\)*" "[C\\|I][A-Z]+[a-z]+[a-zA-Z0-9]*\\([\\&\\*]\\)*\\(\\<[A-Za-z0-9]+\\>\\([\\&\\*]\\)*\\)?" "[V][a-z]+[a-zA-Z_0-9]*\\([\\&\\*]\\)*\\(\\<[A-Za-z_0-9]+\\>\\)\\([\\&\\*]\\)*")))
;; '(case-fold-search t)
;; '(current-language-environment "Latin-1")
;; '(default-input-method "latin-1-prefix")
 '(font-lock-maximum-size 1048576)
 '(global-font-lock-mode t nil (font-lock))
 '(show-trailing-whitespace t)
 )
