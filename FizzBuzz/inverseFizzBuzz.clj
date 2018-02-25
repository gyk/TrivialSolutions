;;; Inverse FizzBuzz Problem

(defn fizz-buzz [n]
  (cond
    (zero? (mod n 15)) 'fizzbuzz
    (zero? (mod n  3)) 'fizz
    (zero? (mod n  5)) 'buzz
    :else nil))

(defn match-here [f i xs]
  (loop [xs xs
         i i]
    (cond
      (empty? xs) i
      (zero? i) nil
      :else (let [i (f i)
                  noise (fizz-buzz i)]
              (if (nil? noise)
                (recur xs i)
                (if (= (first xs) noise)
                  (recur (rest xs) i)
                  nil))))))

(def match-begin
  (partial match-here dec 15))
(def match-end
  (partial match-here inc 15))

(defn match-begin-all [xs]
  ; NOTE: `min-key` returns the last one when several items have the same key
  (for [i (range (dec 15) 0 -1)
        :let [end (match-here inc i xs)]
        :when end]
    (range (inc i) (inc end))))

(defn find-begin-end [xs]
  (loop [rev-xs ()
         xs xs]
    (let [[x & more] xs]
      (cond
        (nil? x) nil
        (= x 'fizzbuzz) [(match-begin rev-xs) (match-end more)]
        :else (recur (cons x rev-xs) more)))))

(defn get-shortest [xs]
  (if (empty? xs) nil
    (apply min-key count xs)))

(defn inv-fizz-buzz [xs]
  (if-let [[begin end] (find-begin-end xs)]
    (range begin (inc end))
    (-> xs match-begin-all get-shortest)))


(assert (= (inv-fizz-buzz '(fizz buzz)) '(9 10)))
(assert (= (inv-fizz-buzz '(fizz)) '(3)))
(assert (= (inv-fizz-buzz '(fizz buzz fizz)) '(3 4 5 6)))
(assert (= (inv-fizz-buzz '(fizz fizz buzz fizz fizzbuzz fizz)) '(6 7 8 9 10 11 12 13 14 15 16 17 18)))
(assert (= (inv-fizz-buzz '(buzz buzz)) nil))
