;;;; djula-locale.asd

(asdf:defsystem #:djula-locale
  :description "Djula-locale is a utility library for maintaining cl-locale dictionary files for the djula templates"
  :author "andy peterson"
  :license "MIT"
  :serial t
  :depends-on (:djula
               :cl-csv
               :serapeum
               :alexandria
               )
  :components ((:file "package")
               (:file "djula-locale")))

