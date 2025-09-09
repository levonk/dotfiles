;;; early-init.el --- Early initialization -*- lexical-binding: t; -*-

;; This file runs before init.el (Emacs 27+). Keep it minimal and safe.

;; Disable package.el auto-init; prefer explicit init in init.el
(setq package-enable-at-startup nil)

;; Reduce GC during startup, restore afterwards in init.el if desired
(defvar early--gc-cons-threshold gc-cons-threshold)
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold early--gc-cons-threshold)))

;; UI tweaks earlier for less flicker
(setq frame-resize-pixelwise t)
(setq inhibit-startup-message t
      inhibit-startup-echo-area-message t)

;; Native compilation (Emacs 28+), be quiet when optional
(when (boundp 'native-comp-eln-load-path)
  (setq native-comp-async-report-warnings-errors 'silent))

(provide 'early-init)
;;; early-init.el ends here
