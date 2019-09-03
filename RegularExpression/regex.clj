;; RegEx-like parser using parser combinators, written in Clojure.
;;
;; Based on "Regular expression engine in 14 lines of Python"
;; (http://paste.lisp.org/display/24849)

(ns regular-expression)

;; # Parser combinator
;;
;; - Input: StringSeq
;; - Output: a sequence of StringSeq

(def rgx-nil list)

(defn rgx-seq [l r]
  #(for [sl (l %) sr (r sl)] sr))

(defn rgx-| [l r]
  #(concat (l %) (r %)))

(defn rgx-* [e]
  #(concat
    (rgx-nil %)
    ((rgx-seq e (rgx-* e)) %)))

(defn rgx-+ [e]
  (rgx-seq e (rgx-* e)))

(defn rgx-char [c]
  #(let [[h & t] %]
    (if (and (some? h) (= h c)) (list t))))


;===== Smoke Tests =====

(defn match [pattern string]
  (= (pattern string) '(nil)))

; #"c(a|d)+r"
(def p1
  (rgx-seq
    (rgx-char \c)
    (rgx-seq
      (rgx-+
        (rgx-|
          (rgx-char \a)
          (rgx-char \d)))
      (rgx-char \r))))

(assert (match p1 "car"))
(assert (match p1 "cdr"))
(assert (match p1 "cadddr"))
(assert (match p1 "cdadadr"))
(assert (not (match p1 "cr")))
(assert (not (match p1 "csr")))
(assert (not (match p1 "cars")))

; #"a(bc)*d"
(def p2
  (rgx-seq
    (rgx-char \a)
    (rgx-seq
      (rgx-*
        (rgx-seq
          (rgx-char \b)
          (rgx-char \c)))
      (rgx-char \d))))

(assert (match p2 "abcd"))
(assert (match p2 "ad"))
(assert (match p2 "abcbcbcd"))
(assert (not (match p2 "abc")))
(assert (not (match p2 "abd")))
