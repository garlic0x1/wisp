;; -*- mode: wisp; fill-column: 64; -*-
;;
;; This file is part of Wisp.
;;
;; Wisp is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License
;; as published by the Free Software Foundation, either version
;; 3 of the License, or (at your option) any later version.
;;
;; Wisp is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General
;; Public License along with Wisp. If not, see
;; <https://www.gnu.org/licenses/>.
;;

(defun base-test ()
  (assert (equal? 1 1))
  (assert (equal? '(1 2 3) '(1 2 3)))
  (assert (equal? '((1 2) (3 4)) '((1 2) (3 4))))
  (assert (not (equal? '(1) '(1 2))))

  (defvar *x* 1)
  (assert (eq? *x* 1))
  (set! *x* 2)
  (assert (eq? *x* 2))

  (assert (eq? 3
               (handle (+ 1 (/ 1 0))
                 (error (e k)
                  (call k 2))))))
