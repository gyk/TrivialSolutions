;;; Computes the k-th permutation

(defn ->factorial
  "Converts a number to factorial representation"
  [n k]
  (loop [radix 1
         k k
         res (-> n (repeat 0) vec transient)]
    (if (zero? k)
      (-> res persistent! vec)
      (recur (inc radix)
             (quot k radix)
             (assoc! res (- n radix) (rem k radix))))))

(defn kth-perm
  "Returns the k-th permutation of sequence 1, 2, ..., n"
  [n k]
  (loop [factorial (->factorial n k)
         v (vec (range 1 (inc n)))
         res (transient [])]
    (if (empty? factorial)
      (-> res persistent! vec)
      (let [[f & fs] factorial]
        (recur fs
               (into (subvec v 0 f)
                     (subvec v (inc f)))
               (conj! res (v f)))))))
