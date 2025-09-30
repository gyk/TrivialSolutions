(ns max-clique.graph
  (:require
    [max-clique :refer [->graph]]))


(defn erdos-renyi
  "Generates a random undirected graph using the Erdős-Rényi model."
  [n p]
  (let [vertices (range n)
        edges    (for [i     vertices
                       j     (range (inc i) n)
                       :when (< (rand) p)]
                   [i j])]
    (->graph vertices edges)))

(defn with-planted-clique
  "Generate G(n, p) and plant a clique of size k."
  [n k p]
  (let [base     (erdos-renyi n p)
        vertices (range n)
        clique   (take k (shuffle vertices))
        edges    (for [i     clique
                       j     clique
                       :when (< i j)]
                   [i j])
        graph    (reduce (fn [g [u v]]
                           (-> g
                               (update u conj v)
                               (update v conj u)))
                   base
                   edges)]
    {:graph  graph
     :clique (set clique)}))
