;;;; postmodernity.lisp

;;; The MIT License (MIT)
;;;
;;; Copyright (c) 2016 Michael J. Forster
;;;
;;; Permission is hereby granted, free of charge, to any person obtaining a copy
;;; of this software and associated documentation files (the "Software"), to deal
;;; in the Software without restriction, including without limitation the rights
;;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;;; copies of the Software, and to permit persons to whom the Software is
;;; furnished to do so, subject to the following conditions:
;;;
;;; The above copyright notice and this permission notice shall be included in all
;;; copies or substantial portions of the Software.
;;;
;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;;; SOFTWARE.

(in-package "POSTMODERNITY")

(defun make-row-reader-name (structure-name)
  (alexandria:symbolicate structure-name (string-upcase "-row-reader")))

(defun make-all-rows-name (structure-name)
  (alexandria:make-keyword (concatenate 'string (symbol-name structure-name) "S")))

(defun make-single-row-name (structure-name)
  (alexandria:make-keyword structure-name))

(defun make-single-row!-name (structure-name)
  (alexandria:make-keyword (concatenate 'string (symbol-name structure-name) "!")))

(defun make-default-constructor-name (structure-name)
  (alexandria:symbolicate (string-upcase "make-") structure-name))

(defun slot-spec-name (slot-spec)
  (etypecase slot-spec
    (list
     (first slot-spec))
    (symbol
     slot-spec)))

(defun slot-spec-reader (slot-spec)
  (etypecase slot-spec
    (list
     (second slot-spec))
    (symbol
     #'identity)))

(defun make-slot-description (slot-spec)
  `(,(slot-spec-name slot-spec) nil :read-only t))

(defun make-constructor-argument-keyword (slot-spec)
  (alexandria:make-keyword (slot-spec-name slot-spec)))

(defun make-constructor-argument-form (slot-spec fields i)
  `(postmodern:coalesce (funcall ,(slot-spec-reader slot-spec)
                                 (cl-postgres:next-field (aref ,fields
                                                               ,i)))
                        nil))

(defmacro defpgstruct (structure-name &body slot-specs)
  "Defines a structured type, named /structure-type/, with named slots
as specified by /slot-specs/ and defines a Postmodern row reader named
/structure-name/-ROW-READER.

DEFPGSTRUCT creates and adds to POSTMODERN::*RESULT-STYLES* the
keywords named structure-name and by concatenating with S and !. Those
keywords can be used as result format arguments to POSTMODERN:QUERY,
POSTMODERN:PREPARE, POSTMODERN:DEFPREPARED, and
POSTMODERN:DEFPREPARED-WITH-NAMES. Note that in doing so, DEFPGSTRUCT
accesses unexported symbols from the POSTMODERN package.

/structure-name/ must be a symbol, like a Common Lisp structure
/structure-name/ rather than a Common Lisp structure /name-and-options/.

Each /slot-spec/ must be either a symbol specifying the slot name or a
list of a symbol specifying the slot name and a desginator for a
function to read and convert the PostgreSQL string value when
initializing the slot value. If /slot-spec/ is a symbol, the slot
value will be initialized to the PostgreSQL string value."
  (check-type structure-name symbol)
  (alexandria:with-unique-names (fields list row)
    (let ((row-reader-name (make-row-reader-name structure-name))
          (default-constructor-name (make-default-constructor-name structure-name))
          (i -1))
      (flet ((make-constructor-argument (slot-spec)
               `(,(make-constructor-argument-keyword slot-spec)
                  ,(make-constructor-argument-form slot-spec fields (incf i)))))
        `(prog1
           (defstruct ,structure-name
             ,@(mapcar #'make-slot-description slot-specs))
           (cl-postgres:def-row-reader ,row-reader-name (,fields)
             (let ((,list '()))
               (do ((,row (cl-postgres:next-row) (cl-postgres:next-row)))
                   ((null ,row))
                 (push (,default-constructor-name
                           ,@(alexandria:mappend #'make-constructor-argument slot-specs))
                       ,list))
               (nreverse ,list)))
           (flet ((add-result-style (style-name result-name)
                    (let ((styles (cons (list style-name ',row-reader-name result-name)
                                        ;; WARNING: Accessing unexported POSTMODERN symbols.
                                        (remove style-name postmodern::*result-styles* :key #'first))))
                      ;; WARNING: Accessing unexported POSTMODERN symbols.
                      (setf postmodern::*result-styles* styles))))
             ;; WARNING: Accessing unexported POSTMODERN symbols.
             (add-result-style ,(make-all-rows-name structure-name) 'postmodern::all-rows)
             (add-result-style ,(make-single-row-name structure-name) 'postmodern::single-row)
             (add-result-style ,(make-single-row!-name structure-name) 'postmodern::single-row!)))))))
