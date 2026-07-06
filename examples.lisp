;; -------------------------------------------------------------------
;; Test cl-who & split-sequence
;;
;; the purpose of all this if to use htm macro
;; to easly colorate cells (more easily than in shell)
;;
;; (C) June 2026 Stephane Perrot
;; -------------------------------------------------------------------
;; The idea of this 'module' is to schedule a timer/function
;; that regularly checks/parse TSV data file produced by 
;; zbxtop.sh script (data collector)
;; then generate an auto-refreshing html table (out.html for now)
;; WHY 2 separate processes:
;;
;; data collection is much simpler in a shell (zabbix-get + mlr + jq 
;; + tabulate machinery)
;; the moment I looked at least, html colorization according to
;; field/value seemed simpler to code in CL (partly because of 
;; CL-WHO library, partly because of CLOS flexibility ...)
;; -------------------------------------------------------------------
;; TODO:
;; - *default-bgcolor* should handle dark-theme and light-theme
;; - periodic call of table
;; - RENAMING module
;; -------------------------------------------------------------------
;; BUGS:
;; Depending of loading, split-sequence as used here
;; is the one from SPLIT-SEQUENCE system (not LispWorks's)
;;
;; is it really interesting?
;; -------------------------------------------------------------------
(in-package :CL-USER)

(defpackage :TEST-WHO
  (:use :cl :cl-who :split-sequence :mp))

(in-package :TEST-WHO)

(defparameter *data-dir*		#P"/var/tmp/zbxtop/")
(defparameter *data-file-name*		#P"zbxtop.tsv")

(defparameter *output-dir*		#P"/tmp/")
(defparameter *output-file-name*	#P"out.html")
(defparameter *output-pathname*		#.(merge-pathnames *output-dir* *output-file-name*))

(defparameter *delay*			10) ;; must match the one defined in zbxtop.sh
(defparameter *timer*			nil) ;; object used by mp:schedule-timer ...

;; -------------------------------------------------------------------
;; don't forget to call as-=keyword to build method discriminant
(defparameter *default-criterion* "pmem")
(defparameter *default-bgcolor*   "black")

(defparameter *http-stream*       *standard-output*)

;; set to t to get additional debug messages
(defparameter *debug*             nil)
(defparameter *version*           "0.4 (06-07-2026)")

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
                  (format t "~&~{~a ~}~%" field-positions)))))))

;;(setq *line* "pid	name	user	pmem	vsize	rss	swap	threads	ctx_switches	cputime_user	cputime_system")
;;(test-read-tsv "zbxtop.tsv")

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
                     (format t "~&~{~a ~}~%" field-positions)))))))))

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

(defparameter *table*       (read-table-data-from-tsv "zbxtop.tsv"))

;; -----------------------------------------------------------------------
;; Utilities
(defgeneric as-keyword (value)
  (:documentation "return value as a keyword"))

(defmethod as-keyword ((value string))
  (intern (string-upcase value) :keyword))

(defmethod as-keyword ((value symbol))
  (intern (string value) :keyword))
;(as-keyword 'foo)

(defun recent-file-exists-p (filename &optional (max-recent-time-diff 7200))
  (and (probe-file filename)
       (let ((now (get-universal-time))
             (file-modif-time (cl:file-write-date filename)))
         (let ((diff (- now file-modif-time)))
           (when (< diff max-recent-time-diff)
             diff)))))

;; -----------------------------------------------------------------------
;; generic function machinery 

;; field = pmem, threads, ...
;; level = :warning, :high :critical
(defgeneric field-severity-threshold (field level)
  (:documentation "returns the threshold value for given filed (eg 'pmem') and severity level"))

(defmethod field-severity-threshold ((field t)		(level (eql :warning)))		999999999.0)
(defmethod field-severity-threshold ((field t)		(level (eql :average)))		999999998.0)
(defmethod field-severity-threshold ((field t)		(level (eql :high)))		999999997.0)

(defmethod field-severity-threshold ((field (eql :pmem)) (level (eql :warning)))	1.0)
(defmethod field-severity-threshold ((field (eql :pmem)) (level (eql :average)))	2.0)
(defmethod field-severity-threshold ((field (eql :pmem)) (level (eql :high)))		4.0)
;(field-severity-threshold :pmem :high)

;; FIXME: put a macro expanded ??
(defun field-value-bgcolor (field value)
  (cond
   ((> value (field-severity-threshold field :high))         "red")
   ((> value (field-severity-threshold field :average))      "orange")
   ((> value (field-severity-threshold field :warning))      "yellow")

   (t                                                        *default-bgcolor*)))

;(field-value-bgcolor :pmem 9.4)
;; patterns be '((:high . "red") (:average . "red") 
;(loop for x in '(a b c) for i upfrom 1 collect (cons x i) into res finally (return (cons (cons 'z 0) res)))

;; WORTH the effort???? (does not seem any clearer than the original)
(defmacro define-field-value-comparison-function (couples)
  `(defun field-value-bgcolor (field value)
     (cond
      ,@(loop :for (level . color) :in (reverse couples)
	      :collect 
                `((> value (field-severity-threshold field ,level)) ,color) :into result
              :finally (return (nreverse (cons `(t *default-bgcolor*) result)))))))

;; seems to 
;(pprint  (macroexpand-1  '(define-field-value-comparison-function ((:high . "red") (:average . "orange") (:warning . "yellow")) )) *terminal-io*)

;; -----------------------------------------------------------------------------------
;; works, sort of, sauf que ca colorise 
;; and here we are, we have to figure again which field we are processing

(defun fdf-cb (file-name fdf-handle)
  (declare (ignore fdf-handle))
  (format *terminal-io* "~& fdf-cb called file-name='~a' ~%" file-name))

;(time (hcl:fast-directory-files #P"/tmp/" 'fdf-cb))

;; to boring for my level of tiredness...
(defun write-html-table (&key (outfn "test.html") (table *table*) (ip "127.0.0.1") (criterion "pmem") (memory "16_GB") (ncores 4) (timestamp "<ts undefined>"))
  (let ((header-line (nth 0 table)))
    (with-open-file (out outfn :direction :output :if-exists :supersede)
      (with-html-output (out) ;;*standard-output*)
        (htm
         (:header (:meta :http-equiv "refresh" :content 10)
          (fmt "Getting process data from <b>~a</b>, sorting by <b>~a</b><br>Total memory: <b>~a</b>, #of cpus: <b>~a (~a)</b>" ip criterion memory ncores timestamp))
 
         (:body
          (:table :border 0 :cellpadding 4
           (loop :for line-data :in table
                 :for i         :upfrom 0
                 :do (htm
                      (:tr :align "left"
                       (loop :for item :in line-data
                             :for j :upfrom 0
                             :do
                               (let ((current-field (nth j header-line)) ;;
                                     ;; FIXME: a bug might arise from "file:// " value
                                     (value (with-input-from-string (in item)
                                              (read in nil nil))))
                                 (when *debug*
                                   (format t "~& i,j=~d,~d current-field='~a' value='~a' (type ~a)~%" 
                                           i j current-field value (type-of value)))
                                 (htm ;; FIXME do better
                                      (:td :bgcolor (if (and (> i 0)
                                                             (floatp value))
                                                        (field-value-bgcolor (as-keyword current-field) value)
                                                      ;; else
                                                      *default-bgcolor*)
                                       (if (zerop i)
                                           (fmt "<b>~a</b>" item) ;; FIXME: more elegant
                                         (fmt "~a" item)))) ))))))))))))

;(write-html-table :outfn "out.html"		:table *small-table*)
;(write-html-table :outfn "/tmp/out.html"	:table *table* :ip "10.23.8.10")

;; bug when data contains what resembles a package name!!
(defun parse-data-gen-html ()
  (let ((data-file-pathname (merge-pathnames *data-dir* *data-file-name*)))
    (if (recent-file-exists-p data-file-pathname)
      (let ((table (read-table-data-from-tsv  data-file-pathname)))
        (setq *table* table)
        (write-html-table :outfn *output-pathname* :table *table* :ip "10.23.8.10"))
      ;; else
      (format *terminal-io* "~&No sufficiently recent TSV data file found !~%"))))

;(read-table-data-from-tsv #P"/var/tmp/zbxtop/zbxtop.tsv")
;(write-html-table :outfn #P"/tmp/out.html" :table *table* :ip "10.23.8.10")
;(parse-data-gen-html)

(defun schedule-parsing-and-generation ()
  (let ((timer (mp:make-timer #'parse-data-gen-html))) ;; assoc between func and timer object
    (setq *timer* timer)
    (mp:schedule-timer-relative *timer* *delay* *delay*)))

(defun unschedule-parsing-and-generation ()
  (when *timer*
    (mp:unschedule-timer *timer*)
    (setq *timer* nil)))

;; ------------------------------------------------------------------------------
;; MAIN 

;(schedule-parsing-and-generation)
