;; -*- mode: wisp; fill-column: 64; -*-
;;
;; SPDX-License-Identifier: AGPL-3.0-or-later


;;; * Basic binding to Incremental DOM

(defun make-callback (symbol)
  (dom-make-callback
   (package-name (symbol-package symbol))
   (symbol-name symbol)))

(defmacro tag (tag-symbol attrs &rest body)
  (let ((tag-name (symbol-name tag-symbol)))
    `(progn
       (idom-open-start! ,tag-name)
       (for-each ,attrs
         (fn (attr)
           (idom-attr! (symbol-name (head attr))
                      (second attr))))
       (idom-open-end!)
       ,@body
       (idom-close! ,tag-name))))

(defun text (text)
  (idom-text! text))


;;; * D-expressions

(defun render-sexp (sexp)
  (cond
    ((symbol? sexp)
     (tag :div `((:class "symbol")
                 (:data-package-name
                  ,(package-name
                    (symbol-package sexp)))
                 (:data-symbol-name
                  ,(symbol-name sexp))
                 (:data-function-kind
                  ,(if (symbol-function sexp)
                       (if (jet? (symbol-function sexp))
                           "jet" "fun")
                     "")))
       (text (symbol-name sexp))))
    ((pair? sexp)
     (tag :div '((:class "list"))
       (render-list-contents sexp)))
    ((eq? 'string (type-of sexp))
     (tag :div '((:class "string"))
       (text sexp)))
    ((eq? 'vector (type-of sexp))
     (tag :div '((:class "vector"))
       (render-vector-contents sexp 0)))))

(defun render-list-contents (sexp)
  (unless (nil? sexp)
    (render-sexp (head sexp))
    (let ((tail (tail sexp)))
      (if (list? tail)
          (render-list-contents tail)
        (progn
          (tag :span '((:class "dot"))
            (text "·"))
          (render-sexp tail))))))

(defun vector-each (vector function)
  (vector-each-loop vector function 0))

(defun vector-each-loop (vector function i)
  (when (< i (vector-length vector))
    (call function (vector-get vector i))
    (vector-each-loop vector function (+ i 1))))

(defun render-vector-contents (vector i)
  (vector-each vector #'render-sexp))

(defun draw-app ()
  (tag :style () (text "
    #wisp-app { margin: 10px; }

    .symbol { text-transform: lowercase; }

    .string { font-family: 'DM Mono', monospace; }
    .string:before { content: '“'; }
    .string:after { content: '”'; }

    [data-function-kind=jet] { color: goldenrod; }
    [data-function-kind=fun] { color: lightsalmon; }

    .vector, .list {
      display: flex; flex-wrap: wrap; align-items: center;
      gap: 5px; margin: 0 5px; padding: 0 5px;
      max-width: 60ch;
      min-height: 1em;
    }

    .list { border-color: #555; border-width: 0 2px; border-radius: 10px; }
    .vector { border-color: #558; border-width: 1px; }
  "))
  (render-sexp `(defun render-list-contents (sexp)
                  ,@(code #'render-list-contents)))
  (render-sexp `(notes ,(reverse *buffer*))))

(defvar *buffer* ())
(defvar *root-element* (query-selector "#wisp-app"))
(defvar *key-callback* (make-callback 'on-keydown))
(defvar *render-callback* (make-callback 'draw-app))

(print (list 'root *root-element*
             'key-callback *key-callback*
             'render-callback *render-callback*))

(defun render-app ()
  (with-simple-error-handler ()
    (idom-patch! *root-element* *render-callback* nil)))

(defun on-keydown (key)
  (with-simple-error-handler ()
    (print (list 'keydown key))
    (when (string-equal? key "Enter")
      (progn
        (set! *buffer*
              (cons (dom-prompt "Enter a line.") *buffer*))))
    (render-app)))

(with-simple-error-handler ()
  (dom-on-keydown! *key-callback*)
  (render-app))



;;; * Structural cursors as delimited continuations

(defun cursor-handler (value continuation)
  (fn (command)
      (case (head command)
        (render
         (make-cursor (fn () (call continuation value))))
        (change
         (make-cursor (fn () (call continuation (second command)))))
        (forward
         ))
      )
    )

(defun make-cursor (maker)
  (call-with-prompt :cursor maker cursor-handler))

(defun cursor! (value) (send! :cursor value))

(defun cursor-demo ()
  (make-cursor
   (fn ()
     (map (fn (x)
            (cursor! x))
          (list 'foo 'bar 'baz)))))
