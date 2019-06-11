------------------------------ MODULE Peterson ------------------------------

(*
    Peterson's locking algorithm.
*)

EXTENDS Naturals

VARIABLES interested, victim, state
vars == <<interested, victim, state>>

Enum(set) == [x \in set |-> x]
State == Enum({ "Start", "InterestSet", "VictimSet", "Acquired", "Released" })

ProcSet == 0..1

Other(pid) == 1 - pid

Init == /\ interested = [ pid \in ProcSet |-> FALSE ]
        /\ victim = 0
        /\ state = [ pid \in ProcSet |-> State.Start ]

Next == \/ (\E pid \in ProcSet: /\ state[pid] = State.Start
                                /\ interested' = [ interested EXCEPT ![pid] = TRUE ]
                                /\ state' = [ state EXCEPT ![pid] = State.InterestSet ]
                                /\ UNCHANGED victim)
        \/ (\E pid \in ProcSet: /\ state[pid] = State.InterestSet
                                /\ victim' = pid
                                /\ state' = [ state EXCEPT ![pid] = State.VictimSet ]
                                /\ UNCHANGED interested)
        \/ (\E pid \in ProcSet: /\ state[pid] = State.VictimSet
                                /\ (~(interested[Other(pid)]) \/ victim /= pid)
                                /\ state' = [ state EXCEPT ![pid] = State.Acquired ]
                                /\ UNCHANGED <<interested, victim>>)
        \/ (\E pid \in ProcSet: /\ state[pid] = State.Acquired
                                /\ state' = [ state EXCEPT ![pid] = State.Released ]
                                /\ interested' = [ interested EXCEPT ![pid] = FALSE ]
                                /\ UNCHANGED victim)

(* Equivalent definition:
SetInterest(pid) == /\ state[pid] = State.Start
                    /\ interested' = [ interested EXCEPT ![pid] = TRUE ]
                    /\ state' = [ state EXCEPT ![pid] = State.InterestSet ]
                    /\ UNCHANGED victim

SetVictim(pid) == /\ state[pid] = State.InterestSet
                  /\ victim' = pid
                  /\ state' = [ state EXCEPT ![pid] = State.VictimSet ]
                  /\ UNCHANGED interested

Acquire(pid) == /\ state[pid] = State.VictimSet
                /\ ~(interested[Other(pid)] /\ victim = pid)
                /\ state' = [ state EXCEPT ![pid] = State.Acquired ]
                /\ UNCHANGED <<interested, victim>>

Release(pid) == /\ state[pid] = State.Acquired
                /\ state' = [ state EXCEPT ![pid] = State.Released ]
                /\ interested' = [ interested EXCEPT ![pid] = FALSE ]
                /\ UNCHANGED victim

Step(pid) == \/ SetInterest(pid)
             \/ SetVictim(pid)
             \/ Acquire(pid)
             \/ Release(pid)

Next == \E pid \in ProcSet: Step(pid)
*)

Fairness == WF_vars(Next)

Spec == Init /\ [][Next]_<<interested, victim, state>> /\ Fairness

MutualExclusion == \A p1, p2 \in ProcSet: p1 /= p2 =>
    ~(state[p1] = State.Acquired /\ state[p2] = State.Acquired)

Liveness1 == \A pid \in ProcSet: <>(state[pid] = State.Acquired)
Liveness2 == \A pid \in ProcSet: state[pid] = State.Start ~> state[pid] = State.Acquired

(*

Known issues:

- How to go back to the initial state, i.e., treating "Released" the same as "Start"? Currently it
  leads to the "Back to state" error. (See also <https://github.com/tlaplus/tlaplus/issues/201>)
- Without PlusCal's PC, it's prone to write stuterring steps in TLA+, e.g., `UNCHANGED state` causes
  the problem. What is the solution?

*)

=============================================================================
