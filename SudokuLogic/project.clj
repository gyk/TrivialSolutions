(defproject sudoku "0.1.0-SNAPSHOT"
  :description "Sudoku solver using core.logic"
  :dependencies [[org.clojure/clojure "1.8.0"]
                 [org.clojure/core.logic "0.8.11"]
                 [org.clojure/tools.cli "0.3.5"]]
  :repl-options {:init-ns user}
  :profiles
    {:dev {:dependencies [[org.clojure/tools.namespace "0.2.11"]]
           :source-paths ["dev"]}})
