(ns sudoku.core-test
  (:require [clojure.test :refer :all]
            [sudoku.core :refer :all]))

(def all-numbers (set (range 1 (inc 9))))

(defn all-numbers? [xs]
  (= (set xs) all-numbers))

(defn solved? [solution puzzle]
  (let [rows solution
        columns (apply map vector solution)
        boxes (for [rb (range L)
                    cb (range L)]
                (get-box solution rb cb))]
    (and (every? all-numbers? rows)
         (every? all-numbers? columns)
         (every? all-numbers? boxes))))

(def dummy
  [[0 0 0 0 0 0 0 0 0]
   [0 0 0 0 0 0 0 0 0]
   [0 0 0 0 0 0 0 0 0]
   [0 0 0 0 0 0 0 0 0]
   [0 0 0 0 0 0 0 0 0]
   [0 0 0 0 0 0 0 0 0]
   [0 0 0 0 0 0 0 0 0]
   [0 0 0 0 0 0 0 0 0]
   [0 0 0 0 0 0 0 0 0]])

; From http://norvig.com/sudoku.html
(def inkala-hardest-2010
  [[0 0 5 3 0 0 0 0 0]
   [8 0 0 0 0 0 0 2 0]
   [0 7 0 0 1 0 5 0 0]
   [4 0 0 0 0 5 3 0 0]
   [0 1 0 0 7 0 0 0 6]
   [0 0 3 2 0 0 0 8 0]
   [0 6 0 5 0 0 0 0 9]
   [0 0 4 0 0 0 0 3 0]
   [0 0 0 0 0 9 7 0 0]])

(def norvig-hardest
  [[0 0 0 0 0 6 0 0 0]
   [0 5 9 0 0 0 0 0 8]
   [2 0 0 0 0 8 0 0 0]
   [0 4 5 0 0 0 0 0 0]
   [0 0 3 0 0 0 0 0 0]
   [0 0 6 0 0 3 0 5 4]
   [0 0 0 3 2 5 0 0 6]
   [0 0 0 0 0 0 0 0 0]
   [0 0 0 0 0 0 0 0 0]])

(defn solved-one? [s]
  (solved? (first (solve s)) s))

(deftest smoke
  (is (solved-one? dummy))
  (is (solved-one? inkala-hardest-2010))
  (is (solved-one? norvig-hardest)))
