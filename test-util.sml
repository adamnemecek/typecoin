structure TestUtil =
struct
  local
      open LF Logic
  in

  val T = SgFamilyDecl
  val O = SgObjectDecl

  (* This depends on the bullshit we are doing. *)
  fun arrow t1 t2 = EPi ("_", t1, t2)
  fun arrow' (t1, t2) = arrow t1 t2
  infixr -->
  val (op -->) = arrow'


  fun c_app c ls = EApp (HConst (Const.LThis, c), listToSpine ls)
  fun c_app' ns c ls = EApp (HConst (Const.LId ns, c), listToSpine ls)

  end

end
