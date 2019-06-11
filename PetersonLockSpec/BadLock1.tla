------------------------------ MODULE BadLock1 ------------------------------

(*
    The LockOne algorithm from "The Art of Multiprocessor Programming".
*)

EXTENDS Naturals

VARIABLES interested, state
vars == <<interested, state>>

Enum(set) == [x \in set |-> x]
State == Enum({ "Start", "InterestSet", "Acquired", "Released" })

ProcSet == 0..1

Other(pid) == 1 - pid

Init == /\ interested = [ pid \in ProcSet |-> FALSE ]
        /\ state = [ pid \in ProcSet |-> State.Start ]

Next == \/ (\E pid \in ProcSet: /\ state[pid] = State.Start
                                /\ interested' = [ interested EXCEPT ![pid] = TRUE ]
                                /\ state' = [ state EXCEPT ![pid] = State.InterestSet ])
        \/ (\E pid \in ProcSet: /\ state[pid] = State.InterestSet
                                /\ interested[pid] = TRUE
                                /\ interested[Other(pid)] = FALSE
                                /\ state' = [ state EXCEPT ![pid] = State.Acquired ]
                                /\ UNCHANGED interested)
        \/ (\E pid \in ProcSet: /\ state[pid] = State.Acquired
                                /\ state' = [ state EXCEPT ![pid] = State.Released ]
                                /\ interested' = [ interested EXCEPT ![pid] = FALSE ])

Fairness == WF_vars(Next)

Spec == Init /\ [][Next]_<<interested, state>> /\ Fairness

MutualExclusion == [](\A p1, p2 \in ProcSet: p1 /= p2 =>
    ~(state[0] = State.Acquired /\ state[1] = State.Acquired))

Liveness1 == \A pid \in ProcSet: <>(state[pid] = State.Acquired)
Liveness2 == \A pid \in ProcSet: state[pid] = State.Start ~> state[pid] = State.Acquired

(*

Output:

Deadlock reached.

interested[0] /\ interested[1]

*)

=============================================================================
