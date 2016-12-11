;;;; package.lisp

(defpackage #:djula-locale
  (:use #:cl
        #:alexandria)
  (:export :update-project
           :caveman-update-project
           :locale-list
           :update-locale-list
           :directory-translate-strings
           :file-template-translate-strings))

