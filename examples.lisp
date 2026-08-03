;; -------------------------------------------------------------------
;; Test cl-who & split-sequence
;;
;; the purpose of all this if to use htm macro
;; to easly colorate cells (more easily than in shell)
;;
;; (C) 2026 Stephane Perrot
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
;; - DONE periodic call of table;
;; - *default-bgcolor* should handle dark-theme and light-theme
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
  (:use :cl :cl-who :split-sequence :mp :pathname-utils))

(in-package :TEST-WHO)

(defparameter *data-dir*		#P"/var/tmp/zbxtop/")
(defparameter *data-file-name*		#P"zbxtop.tsv")

(defparameter *output-dir*		#P"/tmp/")
(defparameter *output-file-name*	#P"zbxtop.html")
(defparameter *output-pathname*		(load-time-value (merge-pathnames *output-dir* *output-file-name*)))

(defparameter *delay*			10) ;; must match the one defined in zbxtop.sh
(defparameter *timer-name*		'parse-and-gen-timer) ;; timer-name 
(defvar       *timer*			nil) ;; object used by mp:schedule-timer ...

(defparameter *recent-file-limit*	#.(* 2 60 60)) ;; object used by mp:schedule-timer ...

;; don't forget to call as-=keyword to build method discriminant...
(defparameter *criterion*	 	"pmem") ;; This is default value
(defparameter *default-bgcolor*   	"black")

(defparameter *http-stream*       	*standard-output*)

(defparameter *main-ip*       		"127.0.0.1") ;; TO BE VERBESSERT

(defconstant +header-format-string-bold+ "Getting process data from <b>~a</b>, sorting by <b>~a</b><br>Total memory: <b>~a</b>, #of cpus: <b>~a</b> (data time: ~a)</b>")



;; same using <span> instead of <b>   <span style='color:orange;'>~a</span>
(defconstant +header-format-string-colored+ "Getting process data from <span style='color:red;'>~a</span>, sorting by <span style='color:orange;'>~a</span><br>Total memory: <span style='color:green;'>~a</span>, #of cpus: <span style='color:blue;'>~a</span> (data collected ~a ago)</b>")

;; from PCL
(defparameter *list-etc* "~#[NONE~;~a~;~a and ~a~:;~a, ~a~]~#[~; and ~a~:;, ~a, etc~].")

;;; and then use it like this:

;;; (format nil *list-etc*)                ==> "NONE." ZERO ARGS
;;; (format nil *list-etc* 'a)             ==> "A."
;;; (format nil *list-etc* 'a 'b)          ==> "A and B."
;;; (format nil *list-etc* 'a 'b 'c)       ==> "A, B and C."
;;; (format nil *list-etc* 'a 'b 'c 'd)    ==> "A, B, C, etc."
;;; (format nil *list-etc* 'a 'b 'c 'd 'e) ==> "A, B, C, etc."

;; does a switch case on number of args
;(format nil "~#[NADA~;FOO~;BAR~;BAZ~]" 1 2 3 4)

;; UNDEF should never be called
;; let's suppose we start whith seconds ...
(defparameter *elapsed-time-format-string* "~#[UNDEF~;~d seconds~;~a and ~a~:;~a, ~a~]~#[~; and ~a~:;, ~a, etc~].")

;; -------------------------------------------------------------------
(defun my-time-stamp (universal-time)
  (multiple-value-bind (sec min hour day month year)
      (decode-universal-time universal-time)
    (declare (ignorable sec min hour))
    (format nil "~2,'0d-~2,'0d-~d" day month year)))

;; set to t to get additional debug messages
(defparameter *debug*             nil)

(eval-when (:COMPILE-TOPLEVEL :LOAD-TOPLEVEL :EXECUTE)
  (defparameter *version*           (format nil "0.5g (~a)" (my-time-stamp (get-universal-time)))))

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
                   (let ((field-positions
                          (loop :for field :in elements
                                :for idx :upfrom 0 :collect (cons field (setq *field-positions* field-positions)
                     (format t "~&~{~a ~}~%" field-positions)))))))))))))

;; object: read a table data 2 level list like below

;; a typed read would be in order...
;; is the subjkect not a typed-read
(defun read-table-data-from-tsv (&optional (fname "zbxtop.tsv"))
  (with-open-file      (in fname :direction :input)
       (loop :for line = (read-line in nil nil)
             :while line
             :collect  (split-sequence #\Tab line))))

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

;; -----------------------------------------------------------------------
(defconstant +seconds-in-one-minute+	60)
(defconstant +seconds-in-one-hour+	(* 60 60))
(defconstant +seconds-in-a-day+		(* +seconds-in-one-hour+ 24))

;; FIXME: avoid repeating the pattern 4 times ...
(defun time-diff-as-days-hours-minutes (time-diff)
  (let* ((rem time-diff)
        (ndays (floor (/ rem +seconds-in-a-day+))))

    (let* ((rem (- rem (* ndays +seconds-in-a-day+)))
          (nhours (floor (/ rem +seconds-in-one-hour+))))

      (let* ((rem (- rem (* nhours +seconds-in-one-hour+)))
            (nminutes (floor (/ rem +seconds-in-one-minute+))))

        (let* ((nseconds (- rem (* nminutes +seconds-in-one-minute+))))

          (values ndays nhours nminutes nseconds))))))

;; pour faire ca sous forme de loop 
;; td-ini siad => d
;; rem  siah => h

;; SOMething along these lines ??
(defun time-diff-as-days-hours-minutes-as-loop (time-diff)
  (let ((accu (list))
        (tmp nil))
    (declare (ignorable accu tmp))
    (loop :for seconds-in-unit :in '(86400 3600 60 1)
          :for seconds-left = time-diff then (- seconds-left (* seconds-in-unit))
          collect (floor (/ seconds-left seconds-in-unit)))))

; HERE we have to define a fancy format string to express time-diff
;; not displaying days or seconds when 
;; WORK IN PPROGRESS
;; HANDLE plural
(defparameter +time-diff-as-days-hours-minutes-format-string+ "~r day~:p, ~r hour~:p, ~r minute~:p and ~r second~:p")

;; SEEMS TO BE OK
(defun time-diff-as-fancy-string (time-diff) ;; in seconds
  (multiple-value-bind (ndays nhours nminutes nseconds) (time-diff-as-days-hours-minutes time-diff)
    (format nil +time-diff-as-days-hours-minutes-format-string+ 
            ndays nhours nminutes nseconds)))

;;(probe-file nil)

;;(time-diff-as-fancy-string 50000)
;; FIXME: when filename is nil!!
(defun recent-file-exists-p (filename &optional (max-recent-time-diff *recent-file-limit*))
  (when filename
    (and (probe-file filename)
         (let ((now (get-universal-time))
               (file-modif-time (cl:file-write-date filename)))
           (let ((diff (- now file-modif-time)))
             (when (< diff max-recent-time-diff)
               diff))))))

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

;; to boring for my level of tiredness...
(defun write-html-table (&key (outfn "test.html") (table *table*) (ip "127.0.0.1") (criterion *criterion*) (memory "16_GB") (ncores 4) (timestamp "undefined"))
  (let ((header-line (nth 0 table)))
    (with-open-file (out outfn :direction :output :if-exists :supersede)
      (with-html-output (out)
        (htm
         (:header (:meta :http-equiv "refresh" :content 10)
          (fmt +header-format-string-colored+
               ip criterion memory ncores timestamp))
 
-         (:body
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
                                     ;; ignore-errors? => nil when errors

                                     (value (with-input-from-string (in item)
                                              (ignore-errors (read in nil nil)))))
                                 (when *debug*
                                   (format t "~& i,j=~d,~d current-field='~a' value='~a' (type ~a)~%" 
                                           i j current-field value (type-of value)))
                                 (htm ;; FIXME do better
                                      (:td :bgcolor (if (and (> i 0)
                                                             value
                                                             (floatp value))
                                                        (field-value-bgcolor (as-keyword current-field) value)
                                                      ;; else
                                                      *default-bgcolor*)
                                       (if (zerop i)
                                           (fmt "<b>~a</b>" item) ;; FIXME: more elegant
                                         (fmt "~a" item)))) ))))))))))))

;(write-html-table :outfn "/tmp/out.html" :table *table* :ip "10.23.8.10")

;(my-time-stamp (file-write-date "/tmp/out.html"))

;; FIXME: bother about TZ maybe
(defun my-time-stamp--full (universal-time)
  (multiple-value-bind (sec min hour day month year)
      (decode-universal-time universal-time)
    (format nil "~2,'0d-~2,'0d-~d ~2,'0d:~2,'0d:~2,'0d" day month year hour min sec)))



(defun my-time-diff (file-write-date-ut)
  (let ((time-diff (- (get-universal-time) file-write-date-ut)))
    (time-diff-as-fancy-string time-diff)))

;; FIXME
(defun find-recent-tsv-file (&optional (data-dir *data-dir*))
  (let ((pattern (lw:string-append (pathname-utils:unix-namestring data-dir) "*.tsv")))
    ;; FIXME: make sure the most recent one gets selected !!
    ;; apparently it does ! => no
    (lw:when-let (pathnames (sort (directory pattern)
                              #'(lambda (pn1 pn2)
                                  (> (file-write-date pn1)
                                     (file-write-date pn2)))))
      (first pathnames))))

(defun find-criterion-from-pn (tsv-file-pathname)
  (nth 1 (split-sequence #\_ (pathname-name tsv-file-pathname))))

;; bug when data contains what resembles a package name!!
(defun parse-data-gen-html ()
  (let ((data-file-pathname ;;(merge-pathnames *data-dir* *data-file-name*)
                            (find-recent-tsv-file *data-dir*)
                            ))
    (if (recent-file-exists-p data-file-pathname)
      (let ((table (read-table-data-from-tsv  data-file-pathname))
            ;; FIXME: could not be used again
            ;;(time-indication (my-time-stamp (file-write-date data-file-pathname)))
            (time-indication (my-time-diff (file-write-date data-file-pathname))))
        (setq *table* table)
        (setq *criterion* (find-criterion-from-pn data-file-pathname))
        (write-html-table :outfn *output-pathname* :table *table* :criterion *criterion* :ip "10.23.8.10" :timestamp time-indication))
      ;; else
      (format *terminal-io* "~&No sufficiently recent TSV data file found ~%"))))

;(read-table-data-from-tsv #P"/var/tmp/zbxtop/zbxtop.tsv")
;(write-html-table :outfn #P"/tmp/out.html" :table *table* :ip "10.23.8.10")
;(parse-data-gen-html)

(defun schedule-parsing-and-generation ()
  (let ((timer (mp:make-timer 'parse-data-gen-html))) ;; assoc between func and timer object
    (setq *timer* timer)
    (setf (mp:timer-name *timer*) *timer-name*)
    (mp:schedule-timer-relative *timer* *delay* *delay*)))

(defun unschedule-parsing-and-generation ()
  (when *timer*
    (mp:unschedule-timer *timer*)
    (setq *timer* nil)))

;; ------------------------------------------------------------------------------
;; TESTS

;;(mp:timer-name *timer*)
;;(sort (directory "/var/tmp/zbxtop/*.tsv") (lambda (pn1 pn2) (> (file-write-date pn1) (file-write-date pn2))))


;; ------------------------------------------------------------------------------
;; MAIN 
;(schedule-parsing-and-generation)
;(unschedule-parsing-and-generation)
;(mapcar #'file-write-date (directory "/var/tmp/zbxtop/*.tsv"))


