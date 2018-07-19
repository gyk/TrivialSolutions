; Lossy Counting
; ==============
;
; ## References
;
; - Manku, Gurmeet Singh, and Rajeev Motwani. "Approximate frequency counts over data streams." VLDB'02: Proceedings
;   of the 28th International Conference on Very Large Databases. 2002.
; - For a good pictorial illustration, see <http://micvog.com/2015/07/18/frequency-counting-algorithms-over-data-streams/>.
;   But the implementation there is actually incorrect (<https://github.com/mvogiatzis/freq-count/issues/1>).

; FIXME: all input parameters should be range-checked but I'm too lazy to do it now.

(ns lossy-counting.core
  "Approximate frequency counts by Lossy Counting")


(defrecord LossyCounter
  [m n error-threshold bucket-width])

(defrecord Entry
  [freq max-error])

; The deletion criteria defined in the paper seems wrong? I guess it should be either
;
; $$
; f + \Delta \leq b_{current}, whenever N === 1 (mod w)
; $$
;
; or
;
; $$
; f + \Delta < b_{current}, whenever N === 0 (mod w)
; $$
; .
;
; `(* error-threshold n)` is the maximum possible underestimated frequency.
;
; And some notes on Lamma 4.1:
;
; w = ceil(1/eps) = 1/eps + ee, where ee >= 0
; b = ceil(N/w), but when deletion occurs we have N === 0 (mod w), so N must be b*w.
; So N*eps = (b*w) * eps = b * (1/eps + ee) * eps = b + ee * eps >= b.

(defn create-counter [error-threshold]
  (let [bucket-width (-> (/ 1.0 error-threshold)
                         Math/ceil
                         int)]
    (atom (->LossyCounter {} 0 error-threshold bucket-width))))

(defn- get-current-bucket [n bucket-width]
  (-> n (dec)
        (quot bucket-width)
        (inc)))

(defn- update-map-by-entry [m x current-bucket]
  (if-let [current-entry (m x)]
    (let [{freq :freq max-error :max-error} current-entry]
      (if (< (+ freq max-error) current-bucket)
        (dissoc m x)
        (assoc m x (->Entry (inc freq) max-error))))
    (assoc m x (->Entry 1 (dec current-bucket)))))

(defn update-counter [lossy-counter x]
  (let [{m :m
         n :n
         bucket-width :bucket-width} @lossy-counter

        n (inc n)
        ; This can be optimized.
        current-bucket (get-current-bucket n bucket-width)
        current-entry (m x)
        m (update-map-by-entry m x current-bucket)]
    (swap! lossy-counter assoc
      :m m
      :n n)))

(defn query-counter-with-freq
  "Returns a map of `{key frequency}`."
  [lossy-counter proportion-threshold]
  (let [lossy-counter @lossy-counter
        error-threshold (:error-threshold lossy-counter)
        n (:n lossy-counter)
        m (:m lossy-counter)
        threshold (* n (- proportion-threshold error-threshold))]
    (into {}
      (for [[k entry] m :let [freq (:freq entry)] :when (>= freq threshold)]
        [k freq]))))

(defn query-counter
  [lossy-counter]
  (query-counter-with-freq lossy-counter (* (:error-threshold @lossy-counter) 10.0)))

(defn smoke []
  (let [n 5
        N 10
        c (create-counter 0.02)
        s (cycle (range n))]
    (doseq [x (take (* n N) s)]
      (update-counter c x))
    (assert (= (query-counter c) (into {} (map vector (range n) (repeat N)))))
    "OK"))
