(ns max-clique
  "Bron-Kerbosch algorithm for finding the maximum clique in an undirected graph."
  (:require
    [clojure.set :refer [difference intersection union]]))

(def ^:private conj' (fnil conj #{}))

(defn ->graph
  ([edges]
   (->graph {} edges))
  ([vertices edges]
   (reduce
     (fn [g [from to]]
       (-> g
           (update from conj' to)
           (update to conj' from)))
     (zipmap vertices (repeat #{}))
     edges)))

(defn graph->dot
  [g]
  (->> ["graph G {"
        (for [[from neighbors] g
              to               neighbors
              :when            (< from to)]
          (str "  " from " -- " to ";"))
        "}"]
       (flatten)
       (interpose "\n")
       (apply str)))

(defn- bron-kerbosch-r
  [g r p x best*]
  (cond
    (and (empty? p)
         (empty? x))
      (swap! best* (partial max-key count) r)

    (< (+ (count r) (count p)) (count @best*))
      nil

    :else
      (when-let [pivot (when (seq p)
                         (apply min-key
                           #(count (difference p (g %)))
                           (union p x)))]
        (loop [candidates (difference p (g pivot))
               p          p
               x          x]
          (when-let [v (first candidates)]
            (let [neighbors (g v)
                  r'        (conj r v)
                  p'        (intersection p neighbors)
                  x'        (intersection x neighbors)]
              (bron-kerbosch-r g r' p' x' best*))
            (recur (disj candidates v)
                   (disj p v)
                   (conj x v)))))))

(defn bron-kerbosch
  [g]
  (let [r     #{}
        p     (into #{} (keys g))
        x     #{}
        best* (atom #{})]
    (bron-kerbosch-r g r p x best*)
    @best*))

(comment
  (first (conj #{} 4 5 2 3))

  (def g {1 #{}})

  (def g
    (->graph (partition
               2
               [1 2
                1 5
                2 3
                2 5
                3 4
                4 5
                4 6])))

  (bron-kerbosch g)

  (println (graph->dot g))

  nil)
