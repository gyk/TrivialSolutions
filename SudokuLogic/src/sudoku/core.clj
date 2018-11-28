;; Sudoku solver using core.logic.
;;
;; Based on @swannodette's implementation.

(ns sudoku.core
  (:refer-clojure :exclude [==])
  (:use clojure.core.logic)
  (:require [clojure.core.logic.fd :as fd]))

(def L 3)
(def N (* L L))

(defn get-box [s ^long rb ^long cb]
  (letfn [(indices [i] (->> (* L i) (iterate inc) (take L)))]
    (for [r (indices rb)
          c (indices cb)]
      (get-in s [r c]))))

(def sudomain
  (apply fd/domain (range 1 (inc N))))

(defn init-board [board completed]
  (matche [board completed]
          ([[] []]
            succeed)
          ([[_x . xs] [0 . ys]]
            (init-board xs ys))
          ([[x . xs] [y . ys]]
            (== x y)
            (init-board xs ys))))

(defn solve [sudoku]
  (assert (and (= (count sudoku) N)
               (= (count (sudoku 0)) N)))
  (let [board (vec (repeatedly N #(vec (repeatedly N lvar))))

        rows board
        columns (apply map vector board)
        boxes (for [rb (range L)
                    cb (range L)]
                (get-box board rb cb))]

    (run* [q]
        (== q board)
        (everyg #(fd/in % sudomain) (flatten board))
        (init-board (flatten board) (flatten sudoku))
        (everyg fd/distinct rows)
        (everyg fd/distinct columns)
        (everyg fd/distinct boxes))))

;; Note that although the order of constraits should not matter in theory, if
;; you exchange the first `everyg` and `init-board` in the `run*`, the program
;; will freeze and never return the answer.
;;
;; See https://dev.clojure.org/jira/browse/LOGIC-189.
