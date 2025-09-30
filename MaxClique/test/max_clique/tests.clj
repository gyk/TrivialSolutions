(ns max-clique.tests
  (:require
    [clojure.test :refer [deftest is testing]]
    [max-clique :refer [->graph bron-kerbosch]]
    [max-clique.graph :as g]))

(deftest test->graph
  (testing "Building graph from edges"
    (let [edges [[1 2] [1 3] [2 3]]
          g     (->graph edges)]
      (is (= {1 #{2 3} 2 #{1 3} 3 #{1 2}} g)))))

(deftest test-bron-kerbosch
  (testing "Finding max clique in a simple graph"
    (let [edges  [[1 2] [1 3] [2 3]]
          g      (->graph edges)
          clique (bron-kerbosch g)]
      (is (= #{1 2 3} clique))))

  (testing "Finding max clique in a larger graph"
    (let [edges  [[1 2] [1 5] [2 3] [2 5] [3 4] [4 5] [4 6]]
          g      (->graph edges)
          clique (bron-kerbosch g)]
      (is (= #{1 2 5} clique))))

  ; https://csdl-images.ieeecomputer.org/trans/td/2021/09/figures/chen1-3067053.gif
  (testing "IEEE CSDL Trans"
    (let [edges  (partition
                   2
                   [0 1
                    0 3
                    0 5
                    1 3
                    1 4
                    2 3
                    2 5
                    3 4
                    3 5
                    3 6
                    4 7
                    5 6
                    7 8
                    7 9
                    7 10
                    8 9
                    8 10
                    9 10])
          g      (->graph edges)
          clique (bron-kerbosch g)]
      (is (= 4 (count clique))))))

(deftest test-samples
  (testing "Sample Input 1"
    (let [n      1
          edges  []
          g      (->graph (range n) edges)
          clique (bron-kerbosch g)]
      (is (= 1 (count clique)))))

  (testing "Sample Input 2"
    (let [n      3
          edges  [[0 1]]
          g      (->graph (range n) edges)
          clique (bron-kerbosch g)]
      (is (= 2 (count clique)))))

  (testing "Sample Input 3"
    (let [n      3
          edges  [[0 1] [0 2]]
          g      (->graph (range n) edges)
          clique (bron-kerbosch g)]
      (is (= 2 (count clique)))))

  (testing "Sample Input 4"
    (let [n      3
          edges  [[0 1] [0 2] [1 2]]
          g      (->graph (range n) edges)
          clique (bron-kerbosch g)]
      (is (= 3 (count clique))))))

(deftest randomized
  ; This test fails with small probability
  (testing "Randomized test with planted clique"
    (let [n       100
          p       0.5
          ; When p = 0.5, the expected number of cliques of size s is approximately
          ; C (n, s) · 2 ^{-s (s−1) /2} ~ 2 · log₂ (n), + 5 for safety
          k       (+ (* 2 (Math/ceil (/ (Math/log n) (Math/log 2)))) 5)
          {:keys [graph clique]} (g/with-planted-clique n k p)
          clique' (bron-kerbosch graph)]
      (is (= clique clique')
          (str "Planted clique " clique " should equal found clique " clique')))))
