;;; anything-sage.el --- An anything extension for sage-shell.

;; Copyright (C) 2012-2014 Sho Takemori.
;; Author: Sho Takemori <stakemorii@gmail.com>
;; URL: https://github.com/stakemori/anything-sage
;; Keywords: Sage, math, anything
;; Created: 2012
;; Version: 0.0.1
;; Package-Requires: ((anything "20130605.1746") (sage-shell "0.0.1"))

;;; License
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.


;;; Installation
;; 1. Install sage-shell.el. See the comment of sage-shell.el for the installation.
;; 2. Ensure that anything.el and anything-match-plugin.el are in your load-path.
;; 3. Put this file to your load-path and bytecompile it.
;; 4. Put the following lines to ~/.emacs or ~/.emacs.d/init.el.
;; (setq sage-shell:completion-function
;;       'anything-sage-shell
;;       sage-shell:help-completion-function
;;       'anything-sage-shell-describe-object-at-point)

;;; Code:
(eval-when-compile (require 'cl))
(require 'anything)
(require 'anything-match-plugin)
(require 'sage-shell-mode)

(defvar anything-sage-action-alist
  '(("Insert" . anything-sage-objcts-insert-action)
    ("View Docstring" . anything-sage-show-doc)))

(defvar anything-sage-common-alist
  '((init . anything-sage-init)
    (candidates-in-buffer)))

(defvar anything-sage-additional-action-alist
  '(("View Source File" . (lambda (can)
                            (sage-shell:find-source-in-view-mode
                             (sage-shell-cpl:to-objname-to-send can))))))

(defvar anything-c-source-sage-objects
  `(,@anything-sage-common-alist
    (name . "Sage Objects")
    (action . ,(append anything-sage-action-alist
                       anything-sage-additional-action-alist))))

(defvar anything-c-source-sage-help
  `(,@anything-sage-common-alist
    (name . "Sage Documents")
    (action . ,(append (reverse anything-sage-action-alist)
                       anything-sage-additional-action-alist))))

(defcustom anything-sage-candidate-regexp (rx alnum (zero-or-more (or alnum "_")))
  "Regexp used for collecting Sage attributes and functions."
  :group 'sage-shell
  :type 'regexp)

(defconst anything-sage-cands-buf-name " *anything Sage*")

(defun anything-sage-init ()
  (let ((cands (sage-shell-cpl:candidates-sync anything-sage-candidate-regexp)))
    (with-current-buffer (get-buffer-create anything-sage-cands-buf-name)
      (erase-buffer)
      (dolist (can cands)
        (insert (format "%s\n" can)))
      (anything-candidate-buffer (current-buffer)))))

(defun anything-sage-objcts-insert-action (can)
  (with-current-buffer anything-current-buffer
    (sage-shell:insert-action can)))

;;;###autoload
(defun anything-sage-shell ()
  (interactive)
  (anything
   :sources '(anything-c-source-sage-objects)
   :input (sage-shell:word-at-point)
   :buffer "*anything Sage*"))

;;;###autoload
(defun anything-sage-shell-describe-object-at-point ()
  (interactive)
  (anything
   :sources '(anything-c-source-sage-help)
   :input (sage-shell:word-at-point)
   :buffer "*anything Sage*"))

(defun anything-sage-show-doc (can)
  (if (sage-shell:at-top-level-p)
      (sage-shell-help:describe-symbol
       (sage-shell-cpl:to-objname-to-send can))
    (message "Document help is not available here.")))



(defvar anything-sage-commnd-list-cached nil)

(defvar anything-sage-candidates-number-limit 100)

(defvar anything-c-source-sage-command-history
  `((name . "Sage Command History")
    (init . anything-sage-make-command-list)
    (action . (("Insert" . anything-sage-objcts-insert-action)))
    (candidates . (lambda () anything-sage-commnd-list-cached))
    (candidate-number-limit . ,anything-sage-candidates-number-limit)))

(defun anything-sage-make-command-list ()
  (setq anything-sage-commnd-list-cached
        (loop for i from 0 to (ring-size comint-input-ring)
              collect (ring-ref comint-input-ring i))))

;;;###autoload
(defun anything-sage-command-history ()
  (interactive)
  (anything
   :sources '(anything-c-source-sage-command-history)
   :buffer "*anything Sage*"))


(provide 'anything-sage)
;;; anything-sage.el ends here
