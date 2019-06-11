------------------------------ MODULE BadLock2 ------------------------------

(*
    The LockTwo algorithm from "The Art of Multiprocessor Programming".
*)

EXTENDS Naturals

VARIABLES victim, state
vars == <<victim, state>>

Enum(set) == [x \in set |-> x]
State == Enum({ "Start", "VictimSet", "Acquired", "Released" })

ProcSet == 0..1

Other(pid) == 1 - pid

Init == /\ victim \in ProcSet
        /\ state = [ pid \in ProcSet |-> State.Start ]

Next == \/ (\E pid \in ProcSet: /\ state[pid] = State.Start
                                /\ victim' = pid
                                /\ state' = [ state EXCEPT ![pid] = State.VictimSet ])
        \/ (\E pid \in ProcSet: /\ state[pid] = State.VictimSet
                                /\ victim = Other(pid)
                                /\ state' = [ state EXCEPT ![pid] = State.Acquired ]
                                /\ UNCHANGED victim)
        \/ (\E pid \in ProcSet: /\ state[pid] = State.Acquired
                                /\ state' = [ state EXCEPT ![pid] = State.Released ]
                                /\ UNCHANGED victim)

Fairness == WF_vars(Next)

Spec == Init /\ [][Next]_<<victim, state>> /\ Fairness

MutualExclusion == \A p1, p2 \in ProcSet: p1 /= p2 =>
    ~(state[p1] = State.Acquired /\ state[p2] = State.Acquired)

Liveness1 == \A pid \in ProcSet: <>(state[pid] = State.Acquired)
Liveness2 == \A pid \in ProcSet: state[pid] = State.Start ~> state[pid] = State.Acquired



(*

Output:

Deadlock reached.

state[0] = "Released" /\ state[1] == "VictimSet"

*)

=============================================================================
