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

(require 'dom)
(require 'eieio)

(defconst rfcreader--version "0.1.0"
  "Current version of the rfcreader package.")

(defconst rfcreader--site-url "https://www.ietf.org"
  "Site URL where the RFCs are downloaded from.")

(defcustom rfcreader-repository (format "%srfcreader" user-emacs-directory)
  "Path to the directory that stores all the RFCs."
  :type '(string)
  :group 'rfcreader)

(defclass rfcreader-rfc-descriptor ()
  ((title
    :initarg :title)
   (author
    :initarg :author)
   (year
    :initarg :year)
   (id
    :initarg :id)))

(defun rfcreader-version ()
  "Return the current version of the rfcreader package."
  (interactive)
  (message "%s" rfcreader--version))

(defun rfcreader--repository ()
  "Return the path to the RFCs repository ensuring the directory exists."
  (unless (file-directory-p rfcreader-repository)
    (make-directory rfcreader-repository))
  rfcreader-repository)

(defun rfcreader--rfc-index-path ()
  "Return the path to the RFC index."
  (format "%s/rfc-index.xml" (rfcreader--repository)))

(defun rfcreader--rfc-filename(id)
  "Return the RFC filename identified with ID."
  (format "rfc%i.txt" id))

(defun rfcreader--download (id)
  "Download the RFC identified with the ID identifier as a text file."
  (let* ((filename (rfcreader--rfc-filename id))
         (src (format "%s/rfc/%s" rfcreader--site-url filename))
         (dst (format "%s/%s" (rfcreader--repository) filename)))
    (condition-case nil
        (url-copy-file src dst)
      (file-already-exists (message "RFC already present")))))

(defun rfcreader--download-index (force)
  "Download the index in HTML format if needed.

If FORCE is t, force the download."
  (let* ((src (format "%s/rfc/rfc-index.xml" rfcreader--site-url))
         (dst (rfcreader--rfc-index-path)))
    (when (and force (file-exists-p dst))
      (delete-file dst))
    (unless (file-exists-p dst)
      (url-copy-file src dst))
    dst))

(defun rfcreader--parse-index-xml (index-xml)
  "Parse the raw index XML file which filename is INDEX-XML."
  (with-temp-buffer
    (insert-file-contents index-xml)
    (libxml-parse-xml-region)))

(defun rfcreader--format-title (title)
  "Format the TITLE for the tabulated view."
  title)

(defun rfcreader--parse-doc-id (doc-id)
  "Format the DOC-ID for the tabulated view."
  (string-to-number (string-trim-left doc-id "RFC0*")))

(defun rfcreader--dom-first-text-at(node path)
  "Return the first text value at PATH in the given NODE."
  (let ((current-node node))
    (dolist (elt path)
      (setq current-node (dom-by-tag node elt)))
    (dom-text current-node)))

(defun rfcreader--rfc-entry-to-rfc-descriptor (node)
  "Build an \"rfcreader-rfc-descriptor\"from the DOM's NODE."
  (let ((doc-id (rfcreader--dom-first-text-at node '(doc-id)))
        (title (rfcreader--dom-first-text-at node '(title)))
        (year (rfcreader--dom-first-text-at node '(date year)))
        (author (rfcreader--dom-first-text-at node '(author name))))
    (make-instance 'rfcreader-rfc-descriptor
                   :title title
                   :id (rfcreader--parse-doc-id doc-id)
                   :year year
                   :author author)))

(defun rfcreader--build-rfc-descriptors (dom)
  "Build a list of \"rfcreader-rfc-descriptor\" from the XML DOM."
  (let* ((rfcs (dom-by-tag dom 'rfc-entry)))
    (mapcar #'rfcreader--rfc-entry-to-rfc-descriptor rfcs)))

(defun rfcreader--refresh-index (rfcs)
  "Prepare the list of RFCS for the tabulated view."
  (setq tabulated-list-entries nil)
  (dolist (rfc rfcs)
    (let ((doc-id (oref rfc id)))
      (push (list doc-id
                  (vector
                   (number-to-string doc-id)
                   (oref rfc title)
                   (oref rfc author)
                   (oref rfc year)))
            tabulated-list-entries))))

(defun rfcreader-index ()
  "Display the RFCs index."
  (interactive)
  (let* ((index-xml (rfcreader--download-index nil))
         (dom (rfcreader--parse-index-xml index-xml))
         (rfcs (rfcreader--build-rfc-descriptors dom))
         (buffer (get-buffer-create "*RFCs Index*")))
    (with-current-buffer buffer
      (rfcreader-index-mode)
      (rfcreader--refresh-index rfcs)
      (tabulated-list-init-header)
      (tabulated-list-print))
    (display-buffer buffer))
  nil)

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

(defun rfcreader--open-at-point ()
  "Open the RFC at point."
  (interactive)
  (save-excursion
    (beginning-of-line)
    (if (looking-at "^[[:space:]]*\\([[:digit:]]+\\)")
        (rfcreader-open (string-to-number (match-string 1))))))

(defvar-keymap rfcreader-index-mode-map
  :parent special-mode-map
  :doc "Keymap for rfcindex."
  "RET" #'rfcreader--open-at-point)

(define-derived-mode rfcreader-index-mode tabulated-list-mode "RFC Index"
  "Major mode for listing the published RFCs."
  (setq tabulated-list-format
        [("ID" 5 t)
         ("Title" 60 t)
         ("Author" 12 t)
         ("Year" 4 t)])
  (setq tabulated-list-sort-key nil))

(provide 'rfcreader)

;;; rfcreader.el ends here
