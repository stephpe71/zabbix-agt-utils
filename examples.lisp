;; -------------------------------------------------------------------
;; Test cl-who & split-sequence

;; the purpose of all this if to use htm macro
;; to easly colorate cells (more easily than in shell)
;;
;; June 2026 Stephane Perrot
;; -------------------------------------------------------------------

(in-package :CL-USER)

(defpackage :TEST-WHO
  (:use :cl :cl-who :split-sequence))

(in-package :TEST-WHO)

;; -------------------------------------------------------------------

;; Test basic table WHO => OK
(defun test-alternated-colors-table ()
  (with-html-output (*standard-output*)
    (:table :border 0 :cellpadding 4
     (loop for i below 25 by 5
           do (htm
               (:tr :align "right"
                (loop for j from i below (+ i 5)
                      do (htm
                          (:td :bgcolor (if (oddp j)
                                            "pink"
                                          "green")
                           (fmt "~@R" (1+ j)))))))))) )

;; -------------------------------------------------------------------

;; don't forget to call as-=keyword to build method discriminant
(defparameter *default-criterion* "pmem")

(defparameter *default-bgcolor* "black")

(defparameter *http-stream* *standard-output*)

;; set to t to get additional debug messages
(defparameter *debug*   nil)
(defparameter *version* "0.1 (10-06-2026)")

(defun test-read-tsv (&optional (fname "zbxtop.tsv"))
  (with-open-file      (in fname :direction :input)
    (loop :for line = (read-line in nil nil)
          :for line-index :upfrom 0
          :while line
          :do 
            (let* ((elements (split-sequence #\Tab line)))
              (format t "~&line ~d (~d elements) = '~a' ~%" line-index (length elements) line)
              (when (= line-index 0)
                (let ((field-positions (loop for field in elements for idx upfrom 0 collect (cons field idx))))
                  (setq *field-positions* field-positions)
                  (format t "~&~{~a ~}~%" field-positions)))))))

;; split-sequence #\Tab works (tested)

;;(test-read-tsv "zbxtop.tsv")

;; quick conclusion : not awaken enough 
(defun gen-html-from-tsv (&optional (fname "zbxtop.tsv"))
  (with-open-file      (in fname :direction :input)
    ;; here we will add a wof for output
    (with-html-output (*standard-output*)
      (:table :border 0 :cellpadding 4
       (loop :for line = (read-line in nil nil)
             :for line-index :upfrom 0 :while line
             :do 
               (let* ((elements (split-sequence #\Tab line)))
                 (when (= line-index 0)
                   (let ((field-positions (loop for field in elements for idx upfrom 0 collect (cons field idx))))
                     (setq *field-positions* field-positions)
                     (format t "~&~{~a ~}~%" field-positions)
                     ))))))))

;; object: read a table data 2 level list like below

;; a typed read would be in order...
;; is the subjkect not a typed-read
(defun read-table-data-from-tsv (&optional (fname "zbxtop.tsv"))
  (with-open-file      (in fname :direction :input)
       (loop :for line = (read-line in nil nil)
             :while line
             :collect  (split-sequence #\Tab line))))


(defparameter *small-table* '(("pid" "name" "pmem")
                              (1 "init" 0.9)
                              (2 "foo" 3.7)
                              (4 "bar" 4.7)
                              (5 "baz" 1.7)))

(defparameter *table* (read-table-data-from-tsv "zbxtop.tsv"))

;; -----------------------------------------------------------------------
(defgeneric as-keyword (value)
  (:documentation "return value as a keyword"))

(defmethod as-keyword ((value string))
  (intern (string-upcase value) :keyword))

(defmethod as-keyword ((value symbol))
  (intern (string value) :keyword))

;(as-keyword 'foo)

;; field = pmem, threads, ...
;; level = :warning, :high :critical
(defgeneric field-severity-threshold (field level)
  (:documentation "returns the threshold value for given filed (eg 'pmem') and severity level"))

(defmethod field-severity-threshold ((field t) (level (eql :warning)))      999999999.0)
(defmethod field-severity-threshold ((field t) (level (eql :average)))      999999998.0)
(defmethod field-severity-threshold ((field t) (level (eql :high)))         999999997.0)

(defmethod field-severity-threshold ((field (eql :pmem)) (level (eql :warning)))      1.0)
(defmethod field-severity-threshold ((field (eql :pmem)) (level (eql :average)))      2.0)
(defmethod field-severity-threshold ((field (eql :pmem)) (level (eql :high)))         4.0)

;; to be replaced by a macro expanded one
(defun field-value-bgcolor (field value)
  (cond
   ((> value (field-severity-threshold field :high))         "red")
   ((> value (field-severity-threshold field :average))      "orange")
   ((> value (field-severity-threshold field :warning))      "yellow")
   (t                                                        *default-bgcolor*)))

;; works, sort of, sauf que ca colorise 
;; and here we are, we have to figure again which field we are processing

;; to boring for my level of tiredness...
(defun test-html-table (&key (outfn "test.html") (table *table*))
  (let ((header-line (nth 0 table)))
    (with-open-file (out outfn :direction :output :if-exists :supersede)
      (with-html-output (out) ;;*standard-output*)
        (:table :border 0 :cellpadding 4
         (loop :for line-data :in table
               :for i         :upfrom 0
               :do (htm
                    (:tr :align "left"
                     (loop :for item :in line-data
                           :for j :upfrom 0
                           :do
                             (let ((current-field (nth j header-line))
                                   (value (with-input-from-string (in item)
                                            (read in nil))))
                               (when *debug*
                                 (format t "~& i,j=~d,~d current-field='~a' value='~a' (type ~a) ~%" 
                                         i j current-field value (type-of value)))
                               (htm ;; FIXME do better
                                    (:td :bgcolor (if (and (> i 0)
                                                           (floatp value))
                                                      (field-value-bgcolor (as-keyword current-field) value)
                                                    ;; else
                                                    *default-bgcolor*)
                                     (if (zerop i)
                                         (fmt "<b>~a</b>" item) ;; FIXME: more elegant
                                       (fmt "~a" item)))) ))))))))))

;(with-input-from-string (in "   ")  (read in nil))

;(test-html-table :outfn "out.html" :table *small-table*)
;(test-html-table :outfn "out.html" :table *table*)

;(field-value-bgcolor :pmem 9.4)
;(field-severity-threshold :pmem :high)

