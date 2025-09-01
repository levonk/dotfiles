;; emacs major mode for Yahoo YICF package file format.
;; based on http://two-wugs.net/emacs/mode-tutorial.html
;; version 1.4 cbueno@yahoo-inc.com 18 Aug 2005
;;
;; HOW TO INSTALL
;; ---------------------------------------------------
;; 1. Traditionally you put this file in the system site-lisp or your
;; personal site-lisp directory.
;;
;;    /usr/local/share/emacs/site-lisp/yicf-mode.el
;;           - or -
;;    ~/.emacs.d/site-lisp/yicf-mode.el
;;
;; 2. Then add this to your ~/.emacs file:
;;
;;      ;; YICF a-la mode
;;      (require 'yicf-mode)
;;
;;
;; YINST MENU:
;; ----------------------------------------------------
;; The YINST menu for this mode is very cool but *experimental*.
;; the function names & vars are *not* guarranteed stable
;; across versions. There is little error-checking.
;;
;; It assumes you are running a Unix-like OS with
;;     * xterm
;;     * firefox
;;     * yinst (& perl)
;;     * dist_install
;;     * ls
;;     * head
;;
;; you can substitute the browser and terminal programs. see
;; yinst-browser-cmd and yinst-term-command.
;;
;; NB: It also assumes you use the 'US' dist, cvs and pkgdb servers.


(defvar yinst-browser-cmd "firefox") ;;opera, netscape, etc.
;; todo: there is a browse-url function in Emacs since at least v20.
;; we /should/ use this rather than (shell-command), but the
;; configure looks kind of wonky:
;; http://www.emacswiki.org/cgi-bin/wiki/BrowseUrl


(provide 'yicf-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; syntax & color setup
(defvar yicf-mode-hook nil)

;; make a custom keymap for setting mode-specific shortcuts and menus
(defvar yicf-mode-map
  (let ((yicf-mode-map (make-keymap)))
    (define-key yicf-mode-map "\C-cr" 'yinst-create-release)
    (define-key yicf-mode-map "\C-ct" 'yinst-create-test)
    (define-key yicf-mode-map "\C-cl" 'yinst-create-link)
    yicf-mode-map)
  "Here is where you put your YICF-specific key combos")

;; register the .yicf extension with this mode
(add-to-list 'auto-mode-alist '("\\.yicf\\'" . yicf-mode))

;;regexps for keywords, variables, bultins, strings, etc.
(defconst yicf-font-lock-keywords
  (list
    ;; quotes & quotes
    '("`[^`]+`" . 'font-lock-type-face)
    '("\"[^\"]+\"" . 'font-lock-string-face)
    '("'[^']+'" . 'font-lock-string-face)

    ;; required vars & commands
   '("\\<\\(CUSTODIAN\\|GROUP\\|LONG_DESC\\|OWNER\\|P\\(?:ACKAGE_OS_SPECIFIC\\|ERM\\|RODUCT_NAME\\)\\|REQUIRES\\|SHORT_DESC\\|VERSION\\|YINST\\)\\>" . font-lock-builtin-face)

   ;;oft-used env variables
   '("\\<\\(MAILTO\\|PROVIDER\\|LOCKFILE\\|RANDOMIZE\\)\\>" . font-lock-type-face)

   '("\\<[0-9.]+\\>" . font-lock-variable-name-face)

    ;; secondary keywords
    '("\\<\\(requires\\|pkg\\|nomerge\\|overwrite\\|norootchanged\\)\\>" . 'font-lock-function-name-face)

    ;; users & groups
    '("\\<\\(yahoo\\|root\\|wheel\\)\\>" . 'font-lock-constant-face)

    ;; actions
    '("\\<\\(file\\|configfile\\|patchfile\\|glob\\|dir\\|symlink\\|binfile\\|binlink\\|crontab\\|fifo\\|noop\\|find\\)\\>" . 'font-lock-function-name-face)

    ;; variables. I have to say that I do NOT understand elisp's quoting
    ;; rules for regexp strings.
    '("$(?\\w+)?" . 'font-lock-variable-name-face)

  )
  "syntax highlights for Yahoo yicf package files")



;; We have to modify the generic syntax rules a little.
(defvar yicf-mode-syntax-table
  (let ((yicf-mode-syntax-table (make-syntax-table)))

    ;; underscores "_" are valid word-characters
  (modify-syntax-entry ?_ "w" yicf-mode-syntax-table)

  ;; pound/hashes "#" are comments, but stop at newlines
  (modify-syntax-entry ?\# "<"  yicf-mode-syntax-table)
  (modify-syntax-entry ?\n ">"  yicf-mode-syntax-table)

   yicf-mode-syntax-table)
  "Syntax table for yicf-mode")


;; the main show where we pull it all together. We clear out the local variables,
;; then set the syntax table, keymap and 'font-lock' (regexps & colors).
;; then run any 'hook' (plugin) functions
(defun yicf-mode ()
  "Major mode for Yahoo yicf package files"
  (interactive)
  (kill-all-local-variables)
  (set-syntax-table yicf-mode-syntax-table)
  (use-local-map yicf-mode-map)
  (set (make-local-variable 'font-lock-defaults) '(yicf-font-lock-keywords))
  (setq major-mode 'yicf-mode)
  (setq mode-name "YICF")
  (run-hooks 'yicf-mode-hook))




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; YINST things. ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; returns the 'yinst create' command string for the current file
(defun yinst-create-string (buildtype)
  (concat "yinst create --buildtype " buildtype " -clean " (buffer-file-name)))

(defun yinst-create (buildtype)
  (shell-command (yinst-create-string buildtype)))

;; convenience functions
;; todo: I'm sure there's a prettier lisp-y way to generate these
(defun yinst-create-test ()    (interactive) (yinst-create "test"))
(defun yinst-create-release () (interactive) (yinst-create "release"))
(defun yinst-create-link ()    (interactive) (yinst-create "link"))


;; the 'yinst*install' commands
;; ***LAUNCHES AN XTERM PROCESS*** for the love of... WHY???
;; passwords, baby, passwords. Can't script all the ssh madness easily,
;; so we go interactive. (you should see how yinst itself handles it!)
;;
;; global vars and xterm make the baby Jesus cry.
(defvar yinst-host nil)
(defvar yinst-host-history nil)


;; returns a small sh script that pops an xterm with the given title,
;; prints & runs the given command then waits for the user to close it.
;;   NB: 'cmd' MUST NOT contain semicolons or single-quotes!
(defun yinst-term-command (title cmd)
  (concat "xterm -geom 90x20 -title '" title "' -e ' echo " cmd ";" cmd "; echo; echo -----------------------------------; echo DONE. Press ENTER/RETURN to close; read;'"))


;; what is it with these -string funcs? well, we need to use the '&&' facility of the shell
;; because (shell-command) doesn't like to give us the return code. is there a way?
;;
;; hack: xxx: todo: a BIG kludge here is how we discover, given only the path of the
;; .yicf file, the name of the most-recently-created package for that file. We run
;; 'ls' sorted by date and pop the first entry, like this:
;;
;;    ls -t /yahoo/foo/bar/my_package-*.tgz | head -1
;;
;; We assume you are the only one making changes to this directory/package.
;; The danger comes when you have multiple packages in the same dir, perhaps with similar
;; names and ESPECIALLY if they contain dashes. You might end up installing the wrong one.
;; e.g.:
;;   my-project.yicf
;    my-project-misc.yicf
;;
(defun yinst-install-string ()
  (setq yinst-host (read-from-minibuffer "Y Install on which host?: " nil nil nil yinst-host-history))
  (yinst-term-command "YINST" (concat "yinst install -h " yinst-host " `ls -t " (yinst-package-name (buffer-file-name)) "-*.tgz | head -1`")))

(defun yinst-install ()
  (interactive)
  (shell-command (yinst-install-string)))

(defun yinst-create-test-and-install ()
  (interactive)
  (shell-command (concat (yinst-create-string "test") " && " (yinst-install-string))))

(defun yinst-create-release-and-install ()
  (interactive)
  (shell-command (concat (yinst-create-string "release") " && " (yinst-install-string))))

(defun yinst-dist-install ()
  (interactive)
  (shell-command (yinst-term-command "DIST INSTALL" (concat "dist_install `ls -t " (yinst-package-name (buffer-file-name)) "-*.tgz | head -1`"))))


;; open urls about this package (only works if the pkg is installed on dist)
(defun yinst-package-name (path)
  (file-name-nondirectory (file-name-sans-extension path)))

(defun yinst-open-url (url)
  (shell-command (concat yinst-browser-cmd " " url)))

(defun yinst-go-package-info ()
  (interactive)
  (yinst-open-url (concat "http://dist.corp.yahoo.com/by-package/" (yinst-package-name (buffer-file-name)))))

(defun yinst-go-package-active-installs ()
  (interactive)
  (yinst-open-url (concat "http://pkgdb.corp.yahoo.com/yinst/acti.php?pn=" (yinst-package-name (buffer-file-name)))))



;; Making the YINST menu
(require 'easymenu)

(easy-menu-define my-menu yicf-mode-map "Yinst/Yicf actions menu"
  '("YINST"
    ["Create (release)    " yinst-create-release t]
    ["Create (test)   " yinst-create-test t]
    ["Create (link)   " yinst-create-link t]
    ["Install" yinst-install t]
    ["Create Test & Install" yinst-create-test-and-install t]
    ["Create Release & Install" yinst-create-release-and-install t]

    ("Dist"
     ["Package info" yinst-go-package-info t]
     ["Active installs" yinst-go-package-active-installs t]
     ["Dist Install" yinst-dist-install t])

))

(easy-menu-add my-menu yicf-mode-map)



