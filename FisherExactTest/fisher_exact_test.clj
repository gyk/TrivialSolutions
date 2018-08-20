; Fisher's Exact Test
; ===================
;
; The left-upper cell follows Fisher's noncentral hypergeometric distribution, and when conditioned
; on the total, under the null hypothesis it degenerates to a hypergeometric distribution which no
; longer depends on the nuisance parameter $\pi$.
;
; Note that odds ratio = 1 is (roughly speaking) equivalent to conditioning on the total
; "responders", as under the null hypothesis the two types are all the same therefore only the total
; count is meaningful.
;
; # References
;
; - Mehta, Cyrus R., and Pralay Senchaudhuri. "Conditional versus unconditional exact tests for
;   comparing two binomials." Cytel Software Corporation 675 (2003): 1-5. (WARNING: some mistakes in
;   the paper.)
; - Does Fisher's Exact test for a 2×2 table use the Non-central Hypergeometric or the
;   Hypergeometric distribution? (<https://stats.stackexchange.com/q/259494>)
; - <https://en.wikipedia.org/wiki/Fisher%27s_exact_test#Controversies>

(defn binomial-coeff
  "Computes the value of `choose(n, k)`."
  [n k]
  (let [k (min k (- n k))
        num (apply *' (range (inc (- n k)) (inc n)))
        denum (apply *' (range 1 (inc k)))]
    (/ num denum)))


(defn hypergeometric-distribution
  "Returns a high-order function that transforms `x` to `choose(r, x) * choose(N - r, n - x) /
  choose(N, n)`"
  [r n N]
  (fn [x]
    (/ (* (binomial-coeff r x)
          (binomial-coeff (- N r) (- n x)))
       (binomial-coeff N n))))

(defn hypergeometric-distribution'
  "Similar to `hypergeometric-distribution` but tries to avoid arithmetic overflow at the expense
  of precision."
  [r n N]
  (fn [x]
    (Math/exp
      (+ (Math/log (binomial-coeff r x))
         (Math/log (binomial-coeff (- N r) (- n x)))
         (- (Math/log (binomial-coeff N n)))))))


; The table is arranged like this:
;
; | -  | X1 | X2 |
; |:--:|:--:|:--:|
; |*Y1*| a  | b  |
; |*Y2*| c  | d  |
;
;
; The probability is `(a + b)! (c + d)! (a + c)! (b + d)! / (a! b! c! d! (a + b + c + d)!)`. Due to
; the symmetry of the problem, rotating/swapping rows/swapping columns of the table does not change
; the probability.

(defn rearrange
  "Rearranges the table for easier computation."
  [tbl]
  (letfn [(swap-rows [[a b c d :as t]]
            (if (> (+ a c) (+ b d))
              [b a d c]
              t))
          (swap-cols [[a b c d :as t]]
            (if (> (/ (float a) c) (/ (float b) d))
              [c d a b]
              t))]
    (-> tbl
        swap-rows
        swap-cols)))

; NOTE: Only two-tailed minimum likelihood interval is supported.
(defn fisher-exact-test
  "Returns the p-value of the test."
  [a b c d]
  (let [[a b c d] (rearrange [a b c d])
        distr (hypergeometric-distribution
                (+ a b)
                (+ a c)
                (+ a b c d))

        p (distr a)
        p-left (reduce + (map distr (range 0 a)))
        p-right (reduce + (for [x (range (+ a c) a -1)
                                :let [p' (distr x)]
                                :while (<= p' p)]
                            p'))]

    ; For debugging, comment it out later.
    (do (prn "p = " (float p))
        (prn "p-left = " (float p-left))
        (prn "p-right = " (float p-right)))

    (float (+ p-left p p-right))))

; ================================
(defn- approx= [lhs rhs]
  (< (Math/abs (- lhs rhs)) 1e-4))

(assert (approx= (fisher-exact-test 1 9 11 3) 0.002759))
(assert (approx= (fisher-exact-test 7 12 0 5) 0.272069))
(assert (approx= (fisher-exact-test 2 31 136 15532) 0.033903))
(assert (approx= (fisher-exact-test 4 1 20 1) 0.353846))
