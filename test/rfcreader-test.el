;;; rfcreader-test.el --- tests for RFC reader -*- lexical-binding: t -*-

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

;; commentary

;;; Code:

(require 'rfcreader)

(defconst rfcreader-test--index-xml "fixtures/rfc-index.xml"
  "Location of the HTML index.")

(defun rfcreader-test--parse-index ()
  "Open the index html fixture."
  (rfcreader--parse-index-xml rfcreader-test--index-xml))

(ert-deftest extract-rfc-index ()
  (let* ((root (rfcreader-test--parse-index))
         (rfcs (dom-by-tag root 'rfc-entry)))
    (should (> (length rfcs) 9500))))

(ert-deftest rfc-descriptor-class ()
  (let ((desc (make-instance 'rfcreader-rfc-descriptor
                             :title "The Title"
                             :doc-id "RFC0000")))
    (should (string-equal (oref desc title) "The Title"))
    (should (string-equal (oref desc doc-id) "RFC0000"))))

(provide 'rfcreader-test)

;;; rfcreader-test.el ends here
