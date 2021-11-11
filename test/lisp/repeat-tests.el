;;; repeat-tests.el --- Tests for repeat.el          -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Free Software Foundation, Inc.

;; Author: Juri Linkov <juri@linkov.net>

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

;;; Code:

(require 'ert)
(require 'repeat)

(defvar repeat-tests-calls nil)

(defun repeat-tests-call-a (&optional arg)
  (interactive "p")
  (push `(,arg a) repeat-tests-calls))

(defun repeat-tests-call-b (&optional arg)
  (interactive "p")
  (push `(,arg b) repeat-tests-calls))

(defvar repeat-tests-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-x w a") 'repeat-tests-call-a)
    map)
  "Keymap for keys that initiate repeating sequences.")

(defvar repeat-tests-repeat-map
  (let ((map (make-sparse-keymap)))
    (define-key map "a" 'repeat-tests-call-a)
    (define-key map "b" 'repeat-tests-call-b)
    map)
  "Keymap for repeating sequences.")
(put 'repeat-tests-call-a 'repeat-map 'repeat-tests-repeat-map)
(put 'repeat-tests-call-b 'repeat-map 'repeat-tests-repeat-map)

(defmacro with-repeat-mode (&rest body)
  "Create environment for testing `repeat-mode'."
  `(unwind-protect
      (progn
        (repeat-mode +1)
        (with-temp-buffer
          (save-window-excursion
            ;; `execute-kbd-macro' applied to window only
            (set-window-buffer nil (current-buffer))
            (use-local-map repeat-tests-map)
            ,@body)))
    (repeat-mode -1)))

(defun repeat-tests--check (keys calls inserted)
  (setq repeat-tests-calls nil)
  (delete-region (point-min) (point-max))
  (execute-kbd-macro (kbd keys))
  (should (equal (nreverse repeat-tests-calls) calls))
  ;; Check for self-inserting keys
  (should (equal (buffer-string) inserted)))

(ert-deftest repeat-tests-exit-key ()
  (with-repeat-mode
   (let ((repeat-echo-function 'ignore))
     (let ((repeat-exit-key nil))
       (repeat-tests--check
        "C-x w a b a b RET c"
        '((1 a) (1 b) (1 a) (1 b)) "\nc"))
     (let ((repeat-exit-key [return]))
       (repeat-tests--check
        "C-x w a b a b <return> c"
        '((1 a) (1 b) (1 a) (1 b)) "c")))))

(ert-deftest repeat-tests-keep-prefix ()
  (with-repeat-mode
   (let ((repeat-echo-function 'ignore))
     (repeat-tests--check
      "C-x w a b a b c"
      '((1 a) (1 b) (1 a) (1 b)) "c")
     (let ((repeat-keep-prefix nil))
       (repeat-tests--check
        "C-2 C-x w a b a b c"
        '((2 a) (1 b) (1 a) (1 b)) "c")
       (repeat-tests--check
        "C-2 C-x w a C-3 c"
        '((2 a)) "ccc"))
     ;; TODO: fix and uncomment
     ;; (let ((repeat-keep-prefix t))
     ;;   (repeat-tests--check
     ;;    "C-2 C-x w a b a b c"
     ;;    '((2 a) (2 b) (2 a) (2 b)) "c")
     ;;   (repeat-tests--check
     ;;    "C-2 C-x w a C-1 C-2 b a C-3 C-4 b c"
     ;;    '((2 a) (12 b) (12 a) (34 b)) "c"))
     )))

;; TODO: :tags '(:expensive-test)  for repeat-exit-timeout

(provide 'repeat-tests)
;;; repeat-tests.el ends here
