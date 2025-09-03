;;; lsl.el -- Major mode for editing lsl files

;; Author: Phoenix
;; Created: 2002.10.27

;; Copyright (c) 2002 Linden lab

;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation; either version 2 of the License, or (at your
;; option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License along
;; with this program; if not, write to the Free Software Foundation, Inc.,
;; 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA


;; To install lsl-mode, put lsl.el in your user elisp directory. I
;; recommend adding the following code to your ~/.emacs file.
;;
;;(add-to-list 'load-path "<path-user-elisp>")
;; (load "lsl.el")
;; (require 'lsl-mode)
;; (setq auto-mode-alist (append auto-mode-alist
;; (list
;; '("\\.lsl$" . lsl-mode)
;; )))
;;
;; In addition, here is a sample mode hook. You may want to do other
;; customizations or not even bother with a hook.
;;
;;(defun phoenix-lsl-mode-hook ()
;; (setq indent-tabs-mode nil)
;; (setq-default tab-width 4)
;; (font-lock-mode 1)
;; (font-lock-fontify-buffer)
;; (message "phoenix-lsl-style function executed"))
;;(add-hook 'lsl-mode-hook 'phoenix-lsl-mode-hook)


;; simple stuff for lsl mode. All modes should define this class of stuff.
;;

(defvar lsl-mode-hook nil)
(defvar lsl-mode-map nil "Keymap for lsl major mode")

(if lsl-mode-map nil
  (setq lsl-mode-map (make-keymap))
  (define-key lsl-mode-map "{" 'lsl-electric-brace)
  (define-key lsl-mode-map "}" 'lsl-electric-brace))

(defun lsl-electric-brace ()
  "insert a brace"
  (interactive)
  (insert last-command-char)
  (forward-char 1)
  (indent-according-to-mode)
  (and (eq last-command-char ?\})
       old-blink-paren
       (save-excursion
         (funcall old-blink-paren))))


;; provide good syntax highlighting
;;

;; minimal highlighting provided by:
;; (regexp-opt '("integer" "float" "string" "key" "vector" "rotation"
;; "list") t)
;; (regexp-opt '("for" "do" "while" "if" "else" "jump" "@.*") t)
;; (regexp-opt '("default" "state_entry" "state_exit" "touch_start"
;; "touch" "touch_end" "collision_start" "collision" "collision_end"
;; "land_collision_start" "land_collision" "land_collision_end" "timer"
;; "listen" "sensor" "no_sensor" "control" "at_target" "not_at_target"
;; "at_rot_target" "not_at_rot_target" "money" "email"
;; "run_time_permissions" "changed" "attach" "moving_start" "moving_end"
;; "on_rez" "link_message") t)
;; (regexp-opt '("TRUE" "FALSE") t)
(defconst lsl-font-lock-keywords-1
  (list
   '("\\(float\\|integer\\|key\\|list\\|rotation\\|strin g\\|vector\\)" . font-lock-type-face)
   '("\\(@.*\\|do\\|else\\|for\\|if\\|jump\\|while\\)" . font-lock-keyword-face)
   '("\\(at\\(?:_\\(?:\\(?:rot_\\)?target\\)\\|tach\\)\\ |c\\(?:hanged\\|o\\(?:llision\\(?:_\\(?:end\\|star t\\)\\)?\\|ntrol\\)\\)\\|default\\|email\\|l\\(?:a nd_collision\\(?:_\\(?:end\\|start\\)\\)?\\|i\\(?: nk_message\\|sten\\)\\)\\|mo\\(?:ney\\|ving_\\(?:e nd\\|start\\)\\)\\|no\\(?:_sensor\\|t_at_\\(?:\\(? :rot_\\)?target\\)\\)\\|on_rez\\|run_time_permissi ons\\|s\\(?:ensor\\|tate_e\\(?:ntry\\|xit\\)\\)\\| t\\(?:imer\\|ouch\\(?:_\\(?:end\\|start\\)\\)?\\)\ \)" . font-lock-builtin-face)
   '("\\(\\(?:FALS\\|TRU\\)E\\)" . font-lock-constant-face))
  "Minimal highlighting for lsl mode")

;; more highlighting provided by:
;; (regexp-opt '("PI" "TWO_PI" "PI_BY_TWO" "DEG_TO_RAD" "RAD_TO_DEG"
;; "SQRT2" "NULL_KEY") t)

(defconst lsl-font-lock-keywords-2
  (append lsl-font-lock-keywords-1
          (list
           '("\\(DEG_TO_RAD\\|NULL_KEY\\|PI\\(?:_BY_TWO\\)?\\|RA D_TO_DEG\\|SQRT2\\|TWO_PI\\)" . font-lock-constant-face)))
  "Additional highlighting in lsl mode")

;; max highlight provided by:
;; (regexp-opt '("STATUS_PHYSICS" "STATUS_PHANTOM" "STATUS_ROTATE_X"
;; "STATUS_ROTATE_Y" "STATUS_ROTATE_Z" "AGENT" "ACTIVE" "PASSIVE"
;; "SCRIPTED" "PERMISSION_DEBIT" "PERMISSION_TAKE_CONTROLS"
;; "PERMISSION_REMAP_CONTROLS" "PERMISSION_TRIGGER_ANIMATION"
;; "PERMISSION_ATTACH" "PERMISSION_RELEASE_OWNERSHIP"
;; "PERMISSION_CHANGE_LINKS" "PERMISSION_CHANGE_JOINTS"
;; "PERMISSION_CHANGE_PERMISSIONS" "INVENTORY_TEXTURE" "INVENTORY_SOUND"
;; "INVENTORY_OBJECT" "INVENTORY_SCRIPT" "ATTACH_CHEST" "ATTACH_HEAD"
;; "ATTACH_LSHOULDER" "ATTACH_RSHOULDER" "ATTACH_LHAND" "ATTACH_RHAND"
;; "ATTACH_LFOOT" "ATTACH_RFOOT" "ATTACH_BACK" "LAND_LEVEL" "LAND_RAISE"
;; "LAND_LOWER" "LAND_SMALL_BRUSH" "LAND_MEDIUM_BRUSH" "LAND_LARGE_BRUSH"
;; "LINK_SET" "LINK_ROOT" "LINK_ALL_OTHERS" "LINK_ALL_CHILDREN"
;; "CONTROL_FWD" "CONTROL_BACK" "CONTROL_LEFT" "CONTROL_RIGHT"
;; "CONTROL_ROT_LEFT" "CONTROL_ROT_RIGHT" "CONTROL_UP" "CONTROL_DOWN"
;; "CONTROL_LBUTTON" "CONTROL_ML_LBUTTON" "CHANGED_INVENTORY"
;; "CHANGED_COLOR" "CHANGED_SHAPE" "CHANGED_SCALE" "CHANGED_TEXTURE"
;; "CHANGED_LINK" "TYPE_INTEGER" "TYPE_FLOAT" "TYPE_STRING" "TYPE_KEY"
;; "TYPE_VECTOR" "TYPE_QUATERNION" "TYPE_INVALID") t)

(defconst lsl-font-lock-keywords-3
  (append lsl-font-lock-keywords-2
          (list
           '("\\(A\\(?:CTIVE\\|GENT\\|TTACH_\\(?:BACK\\|CHEST\\| HEAD\\|L\\(?:FOOT\\|HAND\\|SHOULDER\\)\\|R\\(?:FOO T\\|HAND\\|SHOULDER\\)\\)\\)\\|C\\(?:HANGED_\\(?:C OLOR\\|INVENTORY\\|LINK\\|\\(?:S\\(?:CAL\\|HAP\\)\ \|TEXTUR\\)E\\)\\|ONTROL_\\(?:BACK\\|DOWN\\|FWD\\| L\\(?:BUTTON\\|EFT\\)\\|ML_LBUTTON\\|R\\(?:\\(?:IG H\\|OT_\\(?:LEF\\|RIGH\\)\\)T\\)\\|UP\\)\\)\\|INVE NTORY_\\(?:OBJECT\\|S\\(?:CRIPT\\|OUND\\)\\|TEXTUR E\\)\\|L\\(?:AND_\\(?:L\\(?:ARGE_BRUSH\\|EVEL\\|OW ER\\)\\|MEDIUM_BRUSH\\|RAISE\\|SMALL_BRUSH\\)\\|IN K_\\(?:ALL_\\(?:CHILDREN\\|OTHERS\\)\\|\\(?:ROO\\| SE\\)T\\)\\)\\|P\\(?:ASSIVE\\|ERMISSION_\\(?:ATTAC H\\|CHANGE_\\(?:\\(?:JOINT\\|LINK\\|PERMISSION\\)S \\)\\|DEBIT\\|RE\\(?:LEASE_OWNERSHIP\\|MAP_CONTROL S\\)\\|T\\(?:AKE_CONTROLS\\|RIGGER_ANIMATION\\)\\) \\)\\|S\\(?:CRIPTED\\|TATUS_\\(?:PH\\(?:ANTOM\\|YS ICS\\)\\|ROTATE_[XYZ]\\)\\)\\|TYPE_\\(?:FLOAT\\|IN\\(?:TEGER\\|VALID\\) \\|KEY\\|QUATERNION\\|STRING\\|VECTOR\\)\\)" . font-lock-constant-face)))
  "Maximum highlighting in lsl mode")

;; set default font lock behavior
(defvar lsl-font-lock-keywords lsl-font-lock-keywords-3
  "Default lsl mode highlighting")

;; indentation
;;

(defun lsl-indent-line ()
  "Indent current line as best we can based on hints we can find"
  (interactive)
  (beginning-of-line)
  (if (bobp)
      (indent-line-to 0)
    (let ((not-indented t) cur-indent)
      (if (looking-at "^[ \t]*}")
          (progn
            (save-excursion
              (forward-line -1)
              (if(looking-at "^[ \t]*{")
                  (setq cur-inden (current-indentation))
                (setq cur-indent (- (current-indentation) default-tab-width)))))
        (while not-indented
          (save-excursion
            (forward-line -1)
            (if (looking-at "^[ \t]*{")
                (progn
                  (setq cur-indent (+ (current-indentation) default-tab-width))
                  (setq not-indented nil))
              (if (looking-at "^[ \t]*}")
                  (progn
                    (setq cur-indent (current-indentation))
                    (setq not-indented nil))
                (if (bobp)
                    (setq not-indented nil)))))))
      (if cur-indent
          (progn
            (if (< cur-indent 0)
                (setq cur-indent 0)))
        (setq cur-indent 0))
      (indent-line-to cur-indent))))


;; syntax table
;;

(defvar lsl-mode-syntax-table nil "Syntax table for lsl-mode")
(defun lsl-create-syntax-table ()
(if lsl-mode-syntax-table
()
(setq lsl-mode-syntax-table (make-syntax-table))
(set-syntax-table lsl-mode-syntax-table)

;; treat underscored words as words
(modify-syntax-entry ?_ "w" lsl-mode-syntax-table)

;; make c++ style comments
(modify-syntax-entry ?/ ". 12b" lsl-mode-syntax-table)
(modify-syntax-entry ?\n "> b" lsl-mode-syntax-table)))

;; entry function
;;

(defun lsl-mode ()
  "Major mode for editing lsl files for SecondLife"
  (interactive)
  (kill-all-local-variables)
  (lsl-create-syntax-table)
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(lsl-font-lock-keywords))
  (make-local-variable 'indent-line-function)
  ;;(setq indent-line-function 'lsl-indent-line)
  (setq major-mode 'lsl-mode)
  (setq mode-name "lsl-mode")
  (run-hooks 'lsl-mode-hook))


;; provide this mode. User will need to require this mode in their
;; environment
;;

(provide 'lsl-mode)

;;; lsl.el ends here
