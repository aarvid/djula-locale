;;;; djula-locale.lisp

(in-package #:djula-locale)

;;; "djula-locale" goes here. Hacks and glory await!




(defun parse-template-string (string)
  (djula::parse-template-string string))

(defun string-string-p (s)
  (and (eq #\" (first-elt s))
       (eq #\" (last-elt s))))

(defun string-translate-strings (string)
  "given a djula html template string, find all the substrings to be translated"
  (remove-duplicates
   (loop for l in (parse-template-string string)
         for x = (first l)
         for y = (serapeum:trim-whitespace (second l))
         when (and (eq x :unparsed-translation-variable)
                   (string-string-p y))
           collect (read-from-string y))
   :test #'string=))

(defun file-template-translate-strings (file)
  "given a djula html template file, find all the strings to be translated"
  (string-translate-strings (read-file-into-string file)))


(defun directory-translate-strings (dir &key (recurse nil))
  "given a directory of djula html template files find all the strings to be translated"
  (sort
   (remove-duplicates
    (append (mapcan #'file-template-translate-strings
                    (uiop:directory-files  dir "*.html"))
            (when recurse
              (mapcan #'directory-translate-strings
                      (uiop:subdirectories dir))))
    :test #'string=)
   #'string-lessp))




(defun locale-list (message-file translate-strings)
  "return an augmented dictionary of a cl-locale message file with the translate strings.
 Does not update the file."
  (let ((dictionary
          (with-open-file (s message-file :direction :input)
            (read s))))
    (sort (dolist (s translate-strings dictionary)
            (unless (assoc s dictionary :test #'string=)
              (push (cons s "") dictionary)))
          #'string-lessp
          :key #'car)))




(defun alter-pathname (pathname &rest options)
  " alter pathname as specified in the options "
  (apply 'make-pathname :defaults (pathname  pathname) options))

(defun backup-file (file)
  "backup the file by copying it from filename.ext to filename-n.ext
 where n is the next available number."
  (when (uiop:file-exists-p file)
   (let ((name (pathname-name file))
         (n 0)
         (bfile nil))
     (loop while (or (null bfile)
                     (uiop:file-exists-p bfile))
           do (setf bfile
                    (alter-pathname file :name (format nil "~a-~a" name n)))
              (incf n))
     (uiop:copy-file file bfile)
     bfile)))

(defun update-locale-list (message-file translate-strings)
  "update a cl-locale message file with the list of translate strings"
  (backup-file message-file)
  (let ((dict (locale-list message-file translate-strings)))
    (with-open-file (o message-file :direction :output
                                    :if-exists :supersede
                                    :if-does-not-exist :create)
      (format o "(~%~{ ~s~%~})~%" dict))
    dict))
;;(format t "(~%~{ ~s~%~})~%" ll)



(defun csv-locale-list (file template-dir csv-file)
  (backup-file csv-file)
  (let ((dict (locale-list file (directory-translate-strings template-dir :recurse t))))
    (with-open-file (o csv-file :direction :output
                                :if-exists :supersede
                                :if-does-not-exist :create)
      (cl-csv:write-csv-row '("Original" "Translation") :stream o)
      (dolist (s dict)
        (cl-csv:write-csv-row (list (car s) (cdr s)) :stream o :always-quote t)))
    dict))



(defun update-project (template-dir locale-dir)
  " update a djula project informing the template directory and the directory
holding the cl-locale dictionary files"
  (let ((strings (directory-translate-strings template-dir :recurse t)))
    (dolist (dir (uiop:subdirectories locale-dir))
      (let ((message-file (merge-pathnames "message.lisp" dir)))
        (update-locale-list message-file strings)))))

(defun caveman-update-project (project)
  "update the cl-locale dictionary files with the djula translate strings.
Project should coincide with project (asdf) name of the caveman project. "
  (let* ((root-dir (asdf:system-source-directory project))
         (locale-dir (merge-pathnames #P"i18n/" root-dir) )
         (template-dir (merge-pathnames #P"templates/" root-dir)))
    (update-project template-dir locale-dir)))



