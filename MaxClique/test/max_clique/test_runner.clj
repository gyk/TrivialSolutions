(ns max-clique.test-runner
  (:require
    [clojure.test :as t]))

(def test-namespaces
  '[max-clique.tests])

(defn run-all-tests
  [& _]
  (doseq [test-ns test-namespaces]
    (require test-ns))
  (let [{:keys [fail error]} (apply t/run-tests test-namespaces)]
    (when (pos? (+ fail error))
      (System/exit 1))))