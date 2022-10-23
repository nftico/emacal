;;; pkg-tests.el --- tests for src/pkg.c  -*- lexical-binding:t -*-

;; Copyright (C) 2022 Free Software Foundation, Inc.

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'ert)
(require 'ert-x)
(require 'cl-lib)

(defmacro with-packages (packages &rest body)
  (declare (indent 1))
  (let (vars shoulds makes deletions)
    (dolist (p packages)
      (let ((name (if (consp p) (cl-first p) p))
            (options (if (consp p) (cl-rest p))))
        (push `(,name nil) vars)
        (push `(should (not (find-package ',name))) shoulds)
        (push `(setq ,name (make-package ',name ,@options)) makes)
        (push `(when (packagep ,name) (delete-package ,name)) deletions)))
    `(let (,@vars)
       ,@(nreverse shoulds)
       (unwind-protect
	   (progn ,@(nreverse makes) ,@body)
	 ,@(nreverse deletions)))))

(ert-deftest pkg-tests-make-package-invalid ()
  (should-error (make-package))
  (should-error (make-package 1.0))
  (should-error (make-package "x" :hansi 1))
  ;; Comment out because of bug#58714 in calls to cl-defun.
  ;; (should-error (make-package "x" :nicknames))
  ;; (should-error (make-package "x" :use))
  (should-error (make-package "x" :nicknames 1))
  (should-error (make-package "x" :use 1)))

(ert-deftest pkg-tests-packagep ()
  (packagep (make-package "x")))

(ert-deftest pkg-tests-standard-packages ()
  (should (packagep (find-package "emacs")))
  (should (packagep (find-package "keyword")))
  (should (packagep (find-package "")))
  (should (eq (find-package "keyword") (find-package ""))))

(ert-deftest pkg-tests-make-package-nicknames ()
  (with-packages ((x :nicknames '(x z)))
    ;; Package name allowed in nicknames.
    (should (equal (package-nicknames x) '("x" "z"))))
  (with-packages ((x :nicknames '(y y z)))
    ;; Duplicates removed, order-preserving.
    (should (equal (package-nicknames x) '("y" "z")))))

;; (ert-deftest pkg-tests-package-use-list ()
;;   (should nil))

;; (ert-deftest pkg-tests-package-used-by-list ()
;;   (should nil))

;; (ert-deftest pkg-tests-package-shadowing-symbols ()
;;   (should nil))

(ert-deftest pkg-tests-list-all-packages ()
  (let ((all (list-all-packages)))
    (should (seq-every-p #'packagep all))
    (should (memq (find-package "emacs") all))
    (should (memq (find-package "keyword") all))
    (should (memq (find-package "") all))))

(ert-deftest pkg-tests-package-find-package ()
  (with-packages (x)
    (package-%register x)
    (should-error (find-package 1.0))
    (should (eq (find-package 'x) x))
    (should (eq (find-package "x") x))
    (should (eq (find-package ?x) x))
    (should (not (find-package "X"))))
  (with-packages ((x :nicknames '("y" "z")))
    (package-%register x)
    (should (eq (find-package 'y) (find-package 'x)))
    (should (eq (find-package 'z) (find-package 'x)))))

(ert-deftest pkg-tests-delete-package ()
  (with-packages (x)
    (package-%register x)
    (should (find-package "x"))
    (should (delete-package x))
    (should (null (delete-package x)))
    (should (null (package-name x)))
    (should (not (find-package 'x)))))

;;   (with-packages (x)
;;     (package-%register x)
;;     (should (delete-package "x"))
;;     (should-error (delete-package "x")))
;;   (let ((original (list-all-packages)))
;;     (with-packages ((x :nicknames '(y)))
;;       (should (delete-package x))
;;       (should (null (delete-package x)))
;;       (should (not (find-package 'x)))
;;       (should (not (find-package 'y))))))

;; (ert-deftest pkg-tests-rename-package ()
;;   (with-packages (x y)
;;     (should (eq x (rename-package x 'a '(b))))
;;     (should (not (find-package 'x)))
;;     (should (eq (find-package 'a) x))
;;     (should (eq (find-package 'b) x))
;;     ;; Can't rename to an existing name or nickname.
;;     (should-error (rename-package y 'a))
;;     (should-error (rename-package y 'c :nicknames '("b")))
;;     ;; Original package name and nicknames are unchanged.
;;     (should (equal (package-name x) "a"))
;;     (should (equal (package-nicknames x) '("b")))
;;     ;; Can't rename deleted package.
;;     (should (delete-package x))
;;     (should-error (rename-package x 'd))))

;; (ert-deftest pkg-tests-find-symbol ()
;;   (should nil))

;; (ert-deftest pkg-tests-cl-intern ()
;;   (cl-assert (not (find-symbol "foo")))
;;   (unwind-protect
;;       (progn
;;         (cl-intern "foo")
;;         (should (find-symbol "foo")))
;;     (cl-unintern 'foo)))

;; (ert-deftest pkg-tests-cl-unintern ()
;;   (cl-assert (not (find-symbol "foo")))
;;   (unwind-protect
;;       (progn
;;         (cl-intern "foo")
;;         (cl-unintern 'foo)
;;         (should-not (find-symbol "foo")))
;;     (cl-unintern 'foo)))

;; (ert-deftest pkg-tests-package-name ()
;;   (should (equal (package-name "emacs") "emacs")))

;; (ert-deftest pkg-tests-export ()
;;   (should nil))

;; (ert-deftest pkg-tests-unexport ()
;;   (should nil))

;; (ert-deftest pkg-tests-import ()
;;   (should nil))

;; (ert-deftest pkg-tests-shadow ()
;;   (should nil))

;; (ert-deftest pkg-tests-shadowing-import ()
;;   (should nil))

;; (ert-deftest pkg-tests-shadowing-use-package ()
;;   (should nil))

;; (ert-deftest pkg-tests-shadowing-unuse-package ()
;;   (should nil))