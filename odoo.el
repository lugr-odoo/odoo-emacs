;;; odoo.el --- Major modes for editing Odoo files -*- lexical-binding: t -*-
;;; Time-stamp: <2026-06-10 11:57:16 odoo>

;; Author: 2026 Lulu Cathrinus Grimalkin <lugr@odoo.com>
;; Package-Version: 0.1

;; This file is NOT part of GNU Emacs.
;;
;; This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
;; If a copy of the MPL was not distributed with this file, You can obtain one at
;; https://mozilla.org/MPL/2.0/.
;;
;; Keywords: odoo, python, javascript, xml, tools

(require 'imenu)
(require 'ansi-color)


(defgroup odoo nil
  "Support for the Odoo codebase"
  :group 'tools
  :prefix "odoo-"
  :version "0.1")


(defcustom odoo-python-mode-hook nil
  "Hook run by `odoo-python-mode'."
  :type 'hook :group 'odoo)

(defcustom odoo-test-mode-hook nil
  "Hook run by `odoo-test-mode'."
  :type 'hook :group 'odoo)

(defcustom odoo-js-mode-hook nil
  "Hook run by `odoo-js-mode'."
  :type 'hook :group 'odoo)

(defcustom odoo-xml-mode-hook nil
  "Hook run by `odoo-xml-mode'."
  :type 'hook :group 'odoo)

(defcustom odoo-tour-mode-hook nil
  "Hook run by `odoo-tour-mode'."
  :type 'hook :group 'odoo)

(defcustom odoo-buffer-mode-hook nil
  "Hook run by `odoo-tour-mode'."
  :type 'hook :group 'odoo)

(defcustom odoo-tour-imenu-generic-expression
  '(("Tours" "^\\s-*registry\\s-*\\.\\s-*category\\s-*\
(\\s-*['\"]web_tour\\.tours['\"]\\s-*)\\s-*\\.\\s-*add\\s-*\
(\\s-*['\"]\\([A-Za-z0-9_]+\\)['\"]\\s-*\\s-*," 1))
  "imenu regexp for Odoo tour files."
  :type 'string :group 'odoo)


(defvar odoo-database-name nil
  "Name of the current Odoo database.")

(defvar odoo--current-process nil
  "Currently running Odoo process. Don't touch it.")

(defcustom odoo-executable-path nil
  "Path to the Odoo executable."
  :type 'string :group 'odoo)

(defcustom odoo-executable-args nil
  "List of arguments to pass to the Odoo executable."
  :type '(repeat string) :group 'odoo)

(defcustom odoo-process-start-hook nil
  "Hook run following `odoo-start'."
  :type 'hook :group 'odoo)


(defun odoo--make-database-name ()
  "TODO"
  (setq odoo-database-name "rd-test")
  odoo-database-name)

(defun odoo-process-launch (database-name)
  "Start Odoo from `odoo-executable-path' with `odoo-executable-args'
on the given database `database-name'. Not intended to be called directly.
Use `odoo-start'."
  (message "Starting Odoo with database `%s'." database-name)
  (let ((buffer (get-buffer-create (format "*Odoo:%s*" odoo-database-name))))
    (switch-to-buffer-other-window buffer)
    (odoo-buffer-mode)
    (setq odoo--current-process
          (apply #'start-process (format "Odoo:%s" odoo-database-name)
                 buffer (expand-file-name odoo-executable-path)
                 "-d" odoo-database-name odoo-executable-args))
    (set-process-query-on-exit-flag odoo--current-process t)
    (run-hooks #'odoo-process-start-hook)))

(defun odoo-start ()
  "Launch Odoo, or switch to the buffer if there's an existing process."
  (interactive)
  (cond ((not odoo-executable-path)
         (display-warning
          'odoo
          "`odoo-executable-path' needs to be set before `odoo-start' is called." 
          :error))
        (odoo--current-process
         (message "There's an existing Odoo process. Switching to its buffer.")
         (switch-to-buffer-other-window (process-buffer odoo--current-process)))
        ((not odoo-database-name) (odoo-process-launch (odoo--make-database-name)))
        (t (odoo-process-launch odoo-database-name))))

(defun odoo-stop ()
  "Shut down the currently running Odoo process."
  (interactive)
  (cond (odoo--current-process
         (message "Shutting down Odoo process...")
         (interrupt-process odoo--current-process)
         (setq odoo--current-process nil))
        (t
         (message "There's no currently running Odoo process."))))

;;;###autoload
(define-derived-mode odoo-python-mode python-mode "Python (Odoo)"
  "Major mode for editing Odoo Python files."
  :group 'odoo)

;;;###autoload
(define-derived-mode odoo-test-mode odoo-python-mode "Python (Odoo Test)"
  "Major mode for editing Odoo test files."
  :group 'odoo)

;;;###autoload
(define-derived-mode odoo-migration-mode odoo-python-mode "Python (Odoo Migration)"
  "Major mode for editing Odoo migration scripts."
  :group 'odoo)

;;;###autoload
(define-derived-mode odoo-js-mode js-mode "JavaScript (Odoo)"
  "Major mode for editing Odoo JavaScript files."
  :group 'odoo)

;;;###autoload
(define-derived-mode odoo-xml-mode nxml-mode "XML (Odoo)"
  "Major mode for editing Odoo XML files."
  :group 'odoo)

;;;###autoload
(define-derived-mode odoo-tour-mode odoo-js-mode "JavaScript (Odoo Tour)"
  "Major mode for editing Odoo tour files."
  :group 'odoo
  (setq-local imenu-create-index-function #'imenu-default-create-index-function
              imenu-generic-expression odoo-tour-imenu-generic-expression
              ;; which-func-imenu-joiner-function (lambda (x) (car (last x)))
              ))

(define-derived-mode odoo-buffer-mode compilation-mode "Odoo"
  "Major mode used in the Odoo buffer."
  :group 'odoo
  (setq-local ;; window-point-insertion-type t
              ;; kill-buffer-query-functions nil
              ;; buffer-read-only t
              compilation-scroll-output t
              compilation-auto-jump-to-first-error t
              ansi-color-for-compilation-mode t)
  ;; (buffer-disable-undo)
  (add-hook 'compilation-filter-hook #'ansi-color-compilation-filter nil t))


;;;###autoload
(add-to-list
 'magic-mode-alist
 '("\\(.\\|\n\\)*(['\"]web_tour\\.tours['\"]\\s-*)\\s-*\\.\\s-*add"
   . odoo-tour-mode))


(provide 'odoo)

;;; odoo.el ends here
