;;; Computes all permutations

(set! *warn-on-reflection* true)

(defn permutations-array [n k]
  (let [^"[I" indices (into-array Integer/TYPE (range n))
        ^"[I" cycles (into-array Integer/TYPE (range n (- n k) -1))
        extract (fn [^"[I" indices]
                  (let [a (int-array k)]
                    (dotimes [i k]
                      (aset a i (aget indices i)))
                    a))
        rotate (fn [^"[I" indices from]
                  (let [fst (aget indices from)
                        lst (dec n)]
                    (doseq [i (range from lst)]
                      (aset indices i (aget indices (inc i))))
                    (aset indices lst fst)))]
    (loop [ret (transient [(extract indices)])
           i (dec k)]
      (if (= -1 i) (persistent! ret)
        (do
          (aset cycles i (dec (aget cycles i)))
          (if (= 0 (aget cycles i))
            (do
              (rotate indices i)
              (aset cycles i ^int (- n i))
              (recur ret (dec i)))
            (let [j (- n (aget cycles i))
                  iv (aget indices i)
                  jv (aget indices j)]
              (aset indices i jv)
              (aset indices j iv)
              (recur (conj! ret (extract indices)) (dec k)))))))))

(defn permutations [n k]
  (map vec (permutations-array n k)))
