;;; rfcreader-test.el --- tests for RFC reader -*- lexical-binding: t -*-

;; Author: Laurent Stacul
;; Maintainer: Laurent Stacul
;; Version: 0.1
;; Package-Requires: (dependencies)
;; Homepage: homepage
;; Keywords: rfc


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

;; Tests for rfcreader package.

;;; Code:

(require 'rfcreader)

(defun rfcreader-test-fixture-absolute-path ()
  "Return the absolute path of the fixtures directory."
  (if-let (current-file load-file-name)
      (file-name-concat (file-name-directory current-file) "fixtures")
    (file-name-concat default-directory "fixtures")))

(defconst rfcreader-test--index-xml
  (file-name-concat (rfcreader-test-fixture-absolute-path) "rfc-index.xml")
  "Location of the HTML index.")

(defun rfcreader-test--parse-index ()
  "Open the index html fixture."
  (rfcreader--parse-index-xml rfcreader-test--index-xml))

(defconst rfcreader-test-index-root (rfcreader-test--parse-index)
  "Index XML root node.")

(ert-deftest build-rfc-descriptors ()
  (let ((rfcs (rfcreader--build-rfc-descriptors rfcreader-test-index-root)))
    (should (equal (length rfcs) 3))
    (should (equal (oref (car rfcs) id) 1))))

(ert-deftest rfc-descriptor-class ()
  (let ((desc (make-instance 'rfcreader-rfc-descriptor
                             :title "The Title"
                             :id 42)))
    (should (equal (oref desc title) "The Title"))
    (should (equal (oref desc id) 42))))

(ert-deftest doc-id-format ()
  (should (equal 47 (rfcreader--parse-doc-id "RFC0047")))
  (should (equal 9990 (rfcreader--parse-doc-id "RFC9990"))))

(provide 'rfcreader-test)

;;; rfcreader-test.el ends here
