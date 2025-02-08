;;; rfcreader.el --- Tools to read RFCs -*- lexical-binding: t -*-

;; Author: Laurent Stacul
;; Maintainer: Laurent Stacul
;; Version: 0.1
;; Package-Requires: (dependencies)
;; Homepage: homepage
;; Keywords: keywords


;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.


;;; Commentary:

;; This package provides somes tools to ease RFC reading.

;;; Code:

(defvar rfcreader--version "0.1.0"
  "Current version of the rfcreader package.")

(defcustom rfcreader-repository "/tmp/rfcreader"
  "Path to the directory that stores all the RFCs."
  :type '(string)
  :group 'rfcreader)

(defun rfcreader-version ()
  "Return the current version of the rfcreader package."
  (interactive)
  (message "%s" rfcreader--version))

(defun rfcreader--repository ()
  "Return the path to the RFCs repository ensuring the directory exists."
  (unless (file-directory-p rfcreader-repository)
    (make-directory rfcreader-repository))
  rfcreader-repository)

(defun rfcreader--rfc-filename(id)
  "Return the RFC filename identified with ID."
  (format "rfc%i.txt" id))

(defun rfcreader--download (id)
  "Download the RFC identified with the ID identifier as a text file."
  (let* ((filename (rfcreader--rfc-filename id))
        (src (concat "https://www.rfc-editor.org/rfc/" filename))
        (dst (concat (rfcreader--repository) "/" filename)))
    (condition-case nil
        (url-copy-file src dst)
      (file-already-exists (message "RFC already present")))))

(defun rfcreader-open (id)
  "Open an RFC identified with its ID in a new buffer.

If the RFC is not in the RFCs repository, it is downloaded."
  (interactive "nRFC to open: ")
  (let* ((filename (rfcreader--rfc-filename id))
         (target (concat (rfcreader--repository) "/" filename)))
    (unless (file-exists-p target)
      (rfcreader--download id))
    (find-file target))
  (rfcreader-mode))

(defface rfcreader-rfc-ref-face
  '((t . (:weight bold :underline t)))
  "Face for references to other RFCs.")

(defvar rfcreader-mode-font-lock-keywords
  '(("^.*\\(RFC[[:space:]]*#?[[:space:]]*[[:digit:]]+\\)"
     (1 'rfcreader-rfc-ref-face))))

(define-derived-mode rfcreader-mode special-mode "Rfc-Reader"
  "Rfcreader mode provides some facilities to read RFCs."
  (setq-local font-lock-defaults '(rfcreader-mode-font-lock-keywords t t)))

(provide 'rfcreader)

;;; rfcreader.el ends here
