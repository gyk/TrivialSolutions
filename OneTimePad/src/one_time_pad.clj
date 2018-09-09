(ns one-time-pad
    "Implements one-time pad (OTP) encryption."
    (:require [pandect.algo.sha1 :refer [sha1-bytes]]
              [clojure.string :as str]))

(def ^:const digest-size (count (sha1-bytes "")))

(defn- pad-secret [^"[B" secret-bytes]
  (let [len (count secret-bytes)
        pad-len (mod (- len) digest-size)
        byte-seq (concat secret-bytes (repeat pad-len 0))]
    (into-array Byte/TYPE byte-seq)))

(defn- key-byte-seq [^String key ^long n-digests]
  (let [bytes-seq (->> (.getBytes key)
                       (iterate sha1-bytes)
                       (rest)
                       (take n-digests))]
    (for [bs bytes-seq
          b bs]
      b)))

(defn otp-encrypt [^String secret ^String key]
  (let [padded-secret (pad-secret (.getBytes secret))
        secret-len (count padded-secret)
        n (quot secret-len digest-size)
        padded-key (key-byte-seq key n)
        encrypted (into-array Byte/TYPE (map bit-xor padded-secret padded-key))]
    encrypted))

(defn otp-decrypt [^String encrypted ^String key]
  (let [secret-len (count encrypted)
        n (quot secret-len digest-size)
        padded-key (key-byte-seq key n)
        decrypted (->> (map bit-xor encrypted padded-key)
                       (take-while #(not= % 0))
                       (into-array Byte/TYPE)
                       (String.))]
    decrypted))

(defn -main []
  (let [key (str "hunoz" (rand-int 65536) "hukairz")
        secret "Someone is eavesdropping."
        enc (otp-encrypt secret key)
        dec (otp-decrypt enc key)]
    (assert (= dec secret))
    (prn "OK.")))
