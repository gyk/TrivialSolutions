;;; Miller–Rabin Primality Test in Scheme (r5rs)

; n = (2 ^ s) * d
; returns `(values s d)`
(define (factor-2 n)
  (define (go d s)
    (if (even? d)
      (go (/ d 2) (+ 1 s))
      (values s d)))
  (go n 0))

; calculates (base ^ exp) % m
(define (mod-exp base exp m)
  (define (go base exp ret)
    (cond ((zero? exp) ret)
          ((odd? exp) (go base (- exp 1) (modulo (* ret base) m)))
          (else (go (modulo (* base base) m)
                    (arithmetic-shift exp -1)
                    ret))))
  (if (= m 1) 0
      (go base exp 1)))

(define (andmap f xs)
  (cond ((null? xs) #t)
        ((f (car xs)) (andmap f (cdr xs)))
        (else #f)))

(define (bool->yes-no b)
  (if b "Yes" "No"))

(define (miller-rabin n bases)
  (define n-1 (- n 1))
  (call-with-values (lambda () (factor-2 n-1))
    (lambda (s d)
      (define (witness n a)
        (define (witness-r x r)
          (if (> r s)
            #t
            (let ((x (mod-exp x 2 n)))
              (cond ((= x 1) #t)
                    ((= x n-1) #f)
                    (else (witness-r x (+ 1 r)))))))

        (let ((x (mod-exp a d n)))
          (if (or (= x 1) (= x n-1))
              #f
              (witness-r x 2))))
      (andmap (lambda (a) (not (witness n a))) bases))))

(define (prime? n)
  (cond ((<= n 3) #t) ; n > 1
        ((even? n) #f)
        (else (miller-rabin
               n
               (cond ((<= n 4759123141) '(2 7 61))
                     (else ; n <= 2 ^ 63
                       '(2 325 9375 28178 450775 9780504 1795265022)))))))

(begin
  (define (loop k)
    (if (> k 0)
      (begin
        (display (bool->yes-no (prime? (read))))
        (newline)
        (loop (- k 1)))))

  (loop (read))
  (exit 0))
