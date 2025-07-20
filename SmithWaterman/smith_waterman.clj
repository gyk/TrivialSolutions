(ns smith-waterman)

(defn- find-max-pos
  [table]
  (let [xs (for [r (range (count table))
                 c (range (count (table r)))]
             [(get-in table [r c]) [r c]])]
    (->> xs
         (apply max-key first)
         (second))))

(defn- traceback
  [a-vec b-vec table {:keys [score-fn gap-penalty]}]
  (let [[max-r max-c] (find-max-pos table)]
    (loop [a-aligned []
           b-aligned []
           r         max-r
           c         max-c]
      (let [r- (dec r)
            c- (dec c)
            x  (-> table
                   (nth r)
                   (nth c))]
        (if (zero? x)
          [(reverse a-aligned)
           (reverse b-aligned)]
          (let [dir (condp = x
                      (+ (get-in table [r- c-])
                         (score-fn (a-vec r-)
                                   (b-vec c-)))
                        :diag
                      (- (get-in table [r- c])
                         gap-penalty)
                        :upper
                      (- (get-in table [r c-])
                         gap-penalty)
                        :left

                      (throw (ex-info "Fail to trace back"
                                      {:r r
                                       :c c})))
                a-x (case dir
                      :left \0
                      (a-vec r-))
                r'  (case dir
                      :left r
                      r-)
                b-x (case dir
                      :upper \0
                      (b-vec c-))
                c'  (case dir
                      :upper c
                      c-)]
            (recur (conj a-aligned a-x)
                   (conj b-aligned b-x)
                   r'
                   c')))))))

(defn smith-waterman-linear
  [a-vec b-vec
   {:keys [score-fn gap-penalty]
    :or   {score-fn    #(if (= %1 %2)
                          3
                          -3)
           gap-penalty 2}}]
  (let [a-len     (count a-vec)
        b-len     (count b-vec)
        first-row (into [] (repeat (inc b-len) 0))]
    (loop [table [first-row]
           r     1]
      (if (> r a-len)
        (traceback a-vec
                   b-vec
                   table
                   {:score-fn    score-fn
                    :gap-penalty gap-penalty})
        (let [row' (loop [new-row (transient [0])
                          c       1]
                     (if (> c b-len)
                       (persistent! new-row)
                       (let [r-    (dec r)
                             c-    (dec c)
                             score (score-fn (a-vec r-)
                                             (b-vec c-)) ; 0-based
                             val   (max
                                     (+ (get-in table [r- c-])
                                        score)
                                     (- (get-in table [r- c])
                                        gap-penalty)
                                     (- (nth new-row c-)
                                        gap-penalty)
                                     0)]
                         (recur (conj! new-row val)
                                (inc c)))))]
          (recur (conj table row')
                 (inc r)))))))

(comment

  (defn print-aligned
    [xs]
    (apply str
      (map #(if (= % \0) \- %)
        xs)))

  (let [xs        (vec "GGTTGACTA")
        ys        (vec "TGTTACGG")
        [xs' ys'] (smith-waterman-linear
                    xs
                    ys
                    {})]
    [(print-aligned xs')
     (print-aligned ys')])

  ; https://kaell.se/bibook/pairwise/waterman.html
  (let [xs        (vec "CTATCTCGCTATCCA")
        ys        (vec "CTACGCTATTTCA")
        [xs' ys'] (smith-waterman-linear
                    xs
                    ys
                    {:score-fn    #(if (= %1 %2)
                                     3
                                     -1)
                     :gap-penalty 2})]
    [(print-aligned xs')
     (print-aligned ys')])

  nil)


(comment

  (defn edit-distance
    [a-vec b-vec]
    (let [a-len (count a-vec)
          b-len (count b-vec)
          row   (into [] (range (inc b-len)))]
      (loop [row row
             r   1]
        (if (> r a-len)
          (peek row)
          (let [row' (loop [new-row (transient [r])
                            c       1]
                       (if (> c b-len)
                         (persistent! new-row)
                         (let [r-       (dec r) ; 0-based, distance between a[:r]
                               c-       (dec c) ; and b[:c]
                               matched? (= (a-vec r-)
                                           (b-vec c-))
                               value    (min (+ (nth row c) 1)
                                             (+ (nth new-row c-) 1)
                                             (+ (nth row c-) (if matched? 0 1)))]
                           (recur (conj! new-row value)
                                  (inc c)))))]
            (recur row'
                   (inc r)))))))

  (defn bounded-edit-distance
    "Computes the edit distance between two sequences, bounded by k. If the distance > k,
    returns k + 1."
    [a-vec b-vec k]
    (let [a-len (count a-vec)
          b-len (count b-vec)
          row   (into []
                      (range (min (inc b-len)
                                  (inc k))))
          ; The sentinel value
          k+    (inc k)]
      (if (> (abs (- a-len b-len)) k)
        k+
        (loop [row row
               r   1]
          (if (> r a-len)
            (get row b-len k+)
            (let [from (max (- r k) 0) ; 0-based, inclusive
                  to   (min (+ r k) b-len)
                  ; We must start from `from` rather than `from + 1` because `k` is not
                  ; sentinel value. However, when `from` is 0, we start from 1 to avoid
                  ; accessing out-of-bounds indices.
                  row' (loop [new-row (if (zero? from)
                                        (transient [r])
                                        (transient (vec (repeat from k+))))
                              c       (if (zero? from)
                                        1
                                        from)]
                         (if (> c to)
                           (persistent! new-row)
                           (let [r-       (dec r) ; 0-based, distance between a[:r]
                                 c-       (dec c) ; and b[:c]
                                 matched? (= (a-vec r-)
                                             (b-vec c-))
                                 ; Adjacent cells can differ by at most 1, so the `matched?`
                                 ; branch can be moved outside `min`.
                                 value    (if matched?
                                            (nth row c-)
                                            (inc (min (get row c k+)
                                                      (nth row c-)
                                                      (nth new-row c-))))
                                 value    (min value k+)]
                             (recur (conj! new-row value)
                                    (inc c)))))]
              (recur row'
                     (inc r))))))))

  (edit-distance (vec "intention") (vec "execution"))
  (edit-distance (vec "hello") (vec "seldom"))
  (edit-distance (vec "apple") (vec "apple"))
  (edit-distance (vec "Saturday") (vec "Sunday"))
  (edit-distance (vec "horse") (vec "ro"))

  (bounded-edit-distance (vec "intention") (vec "execution") 3)
  (bounded-edit-distance (vec "hello") (vec "seldom") 3)
  (bounded-edit-distance (vec "apple") (vec "apple") 3)
  (bounded-edit-distance (vec "Saturday") (vec "Sunday") 3)
  (bounded-edit-distance (vec "horse") (vec "ro") 3)
  (bounded-edit-distance (vec "a_loooooooong_string") (vec "a") 3)
  (bounded-edit-distance (vec "abc") (vec "xyz") 3)
  (bounded-edit-distance (vec "abc") (vec "xyz") 2)

  nil)
