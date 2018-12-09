(*******************************************************************************)
(* Proves `plus` is associative, the hard way.                                 *)
(*                                                                             *)
(* The standard solutions can be seen in the "Induction" chapter of "Software  *)
(* Foundations" (the `plus_assoc'` and `plus_assoc''` theorems).               *)
(*                                                                             *)
(*******************************************************************************)

Lemma plus_n_O : forall n : nat,
    n = n + 0.
Proof.
  intros n.
  induction n as [ | n' IHn' ].
  - reflexivity.
  - simpl.
    rewrite <- IHn'.
    reflexivity.
Qed.

Lemma plus_distr : forall n m: nat, S (n + m) = n + S m.
Proof.
  intros. 
  induction n as [ | n' IHn' ].
  - reflexivity.
  - simpl.
    rewrite -> IHn'. 
    reflexivity. 
Qed.

(*
  At first I thought this proposition should be trivial to prove as it is just
  the second branch of the definition of `plus`, but it turns out `tail_plus`
  is tail-recursive, whereas `plus` is not.
*)
Lemma plus_distr2 : forall n m : nat,
    S n + m = n + S m.
Proof.
  intros.
  simpl.
  rewrite plus_distr.
  reflexivity.
Qed.


Theorem plus_assoc : forall n m p : nat,
    (n + m) + p = n + (m + p).
Proof.
  intros n m p.
  induction m as [ | m' IHm'].
  - simpl.
    rewrite <- plus_n_O.
    reflexivity.
  - rewrite <- plus_distr2.
    simpl.
    rewrite <- plus_distr.
    rewrite IHm'.
    reflexivity.
Qed.
