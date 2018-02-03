(ns alias-method.core
  "Sampling from a discrete probability distribution using Alias method")

(defn prepare-tables
  [probabilities]
  {:pre [(every? pos? probabilities)
         (-> (apply + probabilities)
             (- 1.0)
             Math/abs
             (< 1e-6))]}
  (let [n (count probabilities)
        prob (mapv #(* % n) probabilities)  ; scaling to $p_i * n$

        ; Descending sort, for the so-called "Robin Hood" heuristic
        prob-indexed (sort-by second #(compare %2 %1) (map vector (range) prob))

        cmp (fn [x y]
              (let [r (compare (second y) (second x))]
                (if (zero? r)
                  (compare (first y) (first x))
                  r)))

        {overfull true underfull false} (group-by #(>= (second %) 1.0) prob-indexed)]

    (loop [prob-table   (transient (vec (repeat n 1.0)))
           alias-table  (transient (vec (range n)))
           overfull     (into (sorted-set-by cmp) overfull)
           underfull    (into (sorted-set-by cmp) underfull)]
      (if (or (empty? overfull) (empty? underfull))
        [(persistent! prob-table) (persistent! alias-table)]
        (let [[oi ov :as o] (first overfull)
              overfull' (disj overfull o)

              [ui uv :as u] (last underfull)
              underfull' (disj underfull u)

              ov' (+ ov uv -1.0)]
          (recur (assoc! prob-table ui uv)
                 (assoc! alias-table ui oi)
                 (if (>= ov' 1.0) (conj overfull' [oi ov']) overfull')
                 (if (< ov' 1.0) (conj underfull' [oi ov']) underfull')))))))

(defn choose
  [prob-table alias-table]
  {:pre [(vector? prob-table)
         (vector? alias-table)]}
  (let [i (rand-int (count prob-table))
        p (prob-table i)
        j (alias-table i)
        q (rand)]
    (if (> p q) i j)))

(defn alias-method [probabilities times]
  (let [[prob-table alias-table] (prepare-tables probabilities)
        gen #(choose prob-table alias-table)]
    (for [i (range times)]
      (gen))))

(let [n 100000
      results (alias-method [(/ 1.0 2) (/ 1.0 3) (/ 1.0 12) (/ 1.0 12)] n)
      freq (frequencies results)]
  (when (< n 500)
    (prn results))
  (prn freq)  ; this should follow multinomial distribution
  (prn (for [[k v] freq]
          [k (float (/ v n))])))
