
structure Tests =
struct
  open LF Logic TypeCoinTxn TestUtil
  infixr -->

  val nat = c_app "nat" []
  val zero = c_app "z" []
  fun succ n = c_app "s" [n]
  fun plus n1 n2 n3 = c_app "plus" [n1, n2, n3]

  fun v s = HVar (~1, s)
  fun var s = EApp (v s, SNil)

  val [n, m, p, A, B, e, e', D, k, r] =
      map var ["n", "m", "p", "A", "B", "e", "e'", "D", "k", "r"]

  val a_test = FromNamed.convertBasis
      [(T, "nat", EType),
       (O, "z", nat),
       (O, "s", arrow nat nat),

       (T, "plus", arrow nat (arrow nat (arrow nat EType))),
       (O, "plus/0",
        EPi ("n", nat, plus zero n n)),
       (O, "plus/s",
        EPi ("m", nat, EPi ("n", nat, EPi ("p", nat,
             arrow (plus m n p)
                   (plus (succ m) n (succ p)))))),

       (T, "commutes",
        EPi ("m", nat, EPi ("n", nat, EPi ("p", nat,
             arrow (plus m n p)
             (arrow
              (plus n m p)
              EType))))),

       (T, "0/commutes",
        EPi ("n", nat, plus n zero n --> EType)),
       (O, "-0",
        c_app "0/commutes"
        [zero,
         c_app "plus/0" [zero]]),
       (O, "-1",
        EPi ("n", nat, EPi ("D", plus n zero n,
             c_app "0/commutes" [n, D] -->
             c_app "0/commutes"
             [succ n,
              c_app "plus/s" [n, zero, n, D]])))
      ]

  val tp = c_app "tp" []
  val term = c_app "term" []
  val base = c_app "base" []
  fun arr t1 t2 = c_app "arr" [t1, t2]
  fun eapp t1 t2 = c_app "app" [t1, t2]
  fun eof e A = c_app "of" [e, A]

  val lambda_test = FromNamed.convertBasis
      [(T, "tp", EType),
       (O, "base", tp),
       (O, "arr", tp --> tp --> tp),

       (T, "term", EType),
       (O, "app", term --> term --> term),
       (O, "lam", tp --> (term --> term) --> term),

       (T, "of", term --> tp --> EType),
       (O, "of/app",
        EPi ("A", tp, EPi ("B", tp, EPi ("e", term, EPi ("e'", term,
             eof e (arr A B) --> eof e' A --> eof (eapp e e') B)))))

      ]



  val i = c_app "i" []
  val logic_test_lf_part = FromNamed.convertBasis
      [(T, "A", EProp), (T, "B", EProp), (T, "C", EProp),
       (T, "i", EType),
       (T, "P", i --> EProp), (T, "Q", i --> EProp), (T, "R", i --> EProp)]
  val logic_test = map SConst logic_test_lf_part

  val A = PAtom (c_app "A" [])
  val B = PAtom (c_app "B" [])
  val C = PAtom (c_app "C" [])
  fun P x = PAtom (c_app "P" [x])
  fun Q x = PAtom (c_app "Q" [x])
  fun S x = PAtom (c_app "S" [x])

  val [x, y, z, z', w, x1, y1, z1, w1, x2, y2, z2, w2, z1', z2'] =
      map MVar ["x", "y", "z", "z'", "w", "x1", "y1", "z1", "w1", "x2", "y2", "z2", "w2", "z1'", "z2'"]


  (* prove A x B -o B x A *)
  val tensor_comm =
      MLam ("z", PTensor (A, B),
            MTensorLet (z, "z1", "z2",
                        MTensor (z2, z1)))
  (* prove (A -o B -o C) -> (A x B) -o C *)
  val uncurry =
      MLam ("y", PLolli (A, PLolli (B, C)),
       MLam ("z", PTensor (A, B),
        MTensorLet (z, "z1", "z2",
         MApp (MApp (y, z1), z2))))

  (* prove A x B -o A & B because no we are affine *)
  val tensor_imp_with =
      MLam ("z", PTensor (A, B),
            MTensorLet (z, "z1", "z2",
                        MWith (z1, z2)))

  (* prove !A x !B -o !A & !B *)
  val tensor_imp_with_bang =
      MLam ("z", PTensor (PBang A, PBang B),
       MTensorLet (z, "z1", "z2",
        MBangLet (z1, "z1'",
        MBangLet (z2, "z2'",
         MWith (MBang z1', MBang z2')))))
  (* don't prove !A & !B -o !A x !B  *)
  val with_imp_tensor_bang_wrong =
      MLam ("z", PWith (PBang A, PBang B),
            MTensor (MPi (L, z), MPi (R, z)))

  (* prove !A x !B -o !(A & B) *)
  val tensor_imp_with_bang2 =
      MLam ("z", PTensor (PBang A, PBang B),
       MTensorLet (z, "z1", "z2",
        MBangLet (z1, "z1'",
        MBangLet (z2, "z2'",
         MBang (MWith (z1', z2'))))))
  (* prove !(A & B) -o !A x !B  *)
  val with_imp_tensor_bang =
      MLam ("z", PBang (PWith (A, B)),
       MBangLet (z, "y",
        MTensor (MBang (MPi (L, y)), MBang (MPi (R, y)))))

  (* prove !(A x B) -o !(A & B) now, because we are affine*)
  val tensor_imp_with_bang_wrong =
      MLam ("y", PBang (PTensor (A, B)),
       MBangLet (y, "z",
        MTensorLet (z, "z1", "z2",
         MBang (MWith (z1, z2)))))

  (* fail to accept this bogus proof *)
  val tensor_imp_bang =
      MLam ("z", PTensor (PBang A, PBang B),
       MTensorLet (z, "z1", "z2",
        MBangLet (z1, "z1'",
                  MBang z1')))


  val one_lolli_a_equiv_a =
      MWith (
      MLam ("x", PLolli (POne, A),
            MApp (x, MOne)),
      MLam ("y", A,
            MLam ("z", POne,
                  y)))

  (* prove A + B -o B + A *)
  val oplus_comm =
      MLam ("z", POplus (A, B),
       MCase (z,
              "z1", MInj (R, z1, POplus (B, A)),
              "z2", MInj (L, z2, POplus (B, A))))

  (* prove A x (B + 0) -o A x B *)
  val thing_with_zero =
      MLam ("z", PTensor (A, POplus (B, PZero)),
       MTensorLet (z, "z1", "z2",
        MCase (z2,
               "x", MTensor (z1, x),
               "y", MAbort (y, PTensor (A, B)))))


  (* prove ((?x:i. P(x)) -o C) => (!x:i. P(x) -o C) *)
  val qcurry = FromNamed.convertProof []
      (MLam ("z", PLolli (PExists ("n", i, P n), C),
        MForallLam ("m", i,
         MLam ("y", P m,
          MApp (z,
                MPack (m, y, PExists ("n", i, P n)))))))


  (* prove !(!x:t. A(x) & B(x)) -o (!x:t. A(x)) & (!x:t. B(x)) *)
  (* meh, later. *)


  (* prove (?x:t. P(x) & Q(x)) -o (?x:t. P(x)) & (?x:t. Q(x)) *)
  val distrib_ex_and_1 = FromNamed.convertProof []
      (MLam ("z", PExists ("n", i, PWith (P n, Q n)),
        MUnpack (z, "n", "y",
         MWith (
          MPack (n, MPi (L, y), PExists ("n", i, P n)),
          MPack (n, MPi (R, y), PExists ("n", i, Q n))))))



  (* fail to prove !((?x:t. !P(x)) & (?x:t. !Q(x))) -o (?x:t. P(x) & Q(x)) *)
  val distrib_ex_and_2 = FromNamed.convertProof []
      (MLam ("z", PBang (PWith (PExists ("n", i, PBang (P n)), PExists ("n", i, PBang (Q n)))),
        MBangLet (z, "z'",
         MUnpack (MPi (L, z'), "n", "z1",
         MUnpack (MPi (R, z'), "m", "z2",
         MBangLet (z1, "z1'",
         MBangLet (z2, "z2'",
          MPack (n,
                 MWith (z1', z2'),
                 PExists ("n", i, PWith (P n, Q n))))))))))


  val K = TypeCoinStdlib.principal_hash (TypeCoinStdlib.test_hash)
  (* prove (A -o B) -o (<K>A -o <K>B) *)
  val affirmation_fmap_specific = FromNamed.convertProof []
      (MLam ("x", PLolli (A, B),
        MLam ("y", PAffirms (K, A),
         MSayBind (y, "z",
          MSayReturn (K, MApp (x, z))))))

  (* prove !k:principal. (A -o B) -o (<k>A -o <k>B) *)
  val affirmation_fmap = FromNamed.convertProof []
      (MForallLam ("k", TypeCoinStdlib.principal,
        MLam ("x", PLolli (A, B),
         MLam ("y", PAffirms (k, A),
          MSayBind (y, "z",
           MSayReturn (k, MApp (x, z)))))))


  (* prove !k:principal. <k><k>A -o <k>A *)
  val affirmation_join = FromNamed.convertProof []
      (MForallLam ("k", TypeCoinStdlib.principal,
         MLam ("z", PAffirms (k, PAffirms (k, A)),
          MSayBind (z, "z1",
           MSayBind (z1, "z2",
            MSayReturn (k, z2))))))

  (* fail to prove !k:principal. <k>A -o A *)
  val affirmation_unsafe_perform_io = FromNamed.convertProof []
      (MForallLam ("k", TypeCoinStdlib.principal,
         MLam ("z", PAffirms (k, A),
          MSayBind (z, "z1", z1))))

  (* fail to prove !k, k':principal. <k>A -o <k'>A *)
  val affirmation_coerce = FromNamed.convertProof []
      (MForallLam ("k", TypeCoinStdlib.principal,
        MForallLam ("n", TypeCoinStdlib.principal,
         MLam ("z", PAffirms (k, A),
          MSayBind (z, "z1", MSayReturn (n, z1))))))


  val tests = [
      (tensor_comm, true),
      (uncurry, true),
      (tensor_imp_bang, true),
      (with_imp_tensor_bang_wrong, false),
      (tensor_imp_with_bang2, true),
      (with_imp_tensor_bang, true),
      (tensor_imp_with_bang_wrong, false),
      (tensor_imp_bang, true),
      (one_lolli_a_equiv_a, true),
      (oplus_comm, true),
      (thing_with_zero, true),
      (qcurry, true),
      (distrib_ex_and_1, true),
      (distrib_ex_and_2, false),
      (affirmation_fmap_specific, true),
      (affirmation_fmap, true),
      (affirmation_join, true),
      (affirmation_unsafe_perform_io, false),
      (affirmation_coerce, false)
  ]

  (*******************************************************************************************)


  (*****************************************************************)

  fun println s = print (s ^ "\n")

  fun succeeded f x = (f x; true) handle _ => false

  fun check basis =
      (println "";
       println (PrettyLF.prettyBasis basis);
       ignore (TypeCheckLF.checkBasis basis);
       println "")
      handle (e as TypeCheckLF.TypeError s) => (println s; raise e)

  fun checkProof basis M =
      ((LogicCheck.inferProofOuter Bytestring.null basis LogicContext.empty M)
       handle (e as TypeCheckLF.TypeError s) => (println s; raise e)
            | (e as LogicCheck.ProofError s) => (println s; raise e))

  fun checkBasis basis =
      ((LogicCheck.checkBasis LogicCheck.stdlib_basis basis)
       handle (e as TypeCheckLF.TypeError s) => (println s; raise e)
            | (e as LogicCheck.ProofError s) => (println s; raise e))

  fun checkChain chain =
      ((TypeCoinCheck.checkChain LogicCheck.stdlib_basis TxnDict.empty chain)
       handle (e as TypeCheckLF.TypeError s) => (println s; raise e)
            | (e as LogicCheck.ProofError s) => (println s; raise e))

end
