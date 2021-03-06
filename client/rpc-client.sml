
signature RPC_CLIENT_PARAMS =
sig
  val getParams : unit -> Network.addr * int
end

functor RpcClientFn(structure Params : RPC_CLIENT_PARAMS) :> RPC_CLIENT =
   struct

      structure B = Bytestring
      structure BS = Bytesubstring
      structure C = BytesubstringCostring
      structure U = Unityped


      val theSock : Network.asock option ref = ref NONE
      val theCostring : C.costring ref = ref C.null

      exception RPC
      exception RemoteError of string


      fun disconnect () =
         (
         Option.app Network.close (!theSock);
         theSock := NONE;
         theCostring := C.null
         )


      fun connect () =
         let
            val (address, port) = Params.getParams ()
            val sock =
               Network.connect (address, port)
               handle Network.NetworkException _ => raise RPC

            val sd = Socket.sockDesc sock

            fun receive () =
               let
                  val {rds=ready, ...} =
                     Socket.select {rds=[sd], wrs=[], exs=[], timeout=SOME Constants.rpcTimeout}
                     handle _ => raise RPC
               in
                  (case ready of
                      [] =>
                         (* timeout *)
                         raise RPC
                    | [_] =>
                         BS.full (Network.recvVec sock)
                    | _ =>
                         (* only gave select one descriptor *)
                         raise (Fail "impossible"))
               end
               handle RPC =>
                  (
                  disconnect ();
                  raise RPC
                  )
         in
            theSock := SOME sock;
            theCostring := C.fromProcess receive;
            sock
         end


      fun send sock str =
         (Network.sendVec (sock, BS.full (ConvertWord.word32ToBytesB (Word32.fromInt (B.size str))))
          andalso
          Network.sendVec (sock, BS.full str))
         handle Network.NetworkException _ => false


      fun connectAndSend str =
         let
            val (sock, isfresh) =
               (case !theSock of
                   NONE =>
                      (connect (), true)
                 | SOME sock =>
                      (sock, false))
         in
            if send sock str then
               sock
            else
               (
               disconnect ();

               if isfresh then
                  raise RPC
               else
                  (* try once more if the connection was old *)
                  connectAndSend str
               )
         end


      fun rpc (method, args) =
         let
            val sock = connectAndSend (Writer.write (U.writer (U.Cons (U.Byte method, args))))
         in
            let
               val cos = !theCostring

               val sz =
                  Word32.toInt (ConvertWord.bytesToWord32SB (C.slice (cos, 0, 4)))
                  handle Overflow => raise RPC
                       | Subscript => raise RPC

               val resp =
                  Reader.readfullS U.reader (C.slice (cos, 4, sz))
                  handle Reader.SyntaxError => raise RPC
                       | Subscript => raise RPC
            in
               theCostring := C.suffix (cos, 4+sz);

               (case resp of
                   U.Method =>
                      (* remote syntax error *)
                      raise RPC
                 | U.Exception (U.String str) =>
                      raise (RemoteError str)
                 | _ =>
                      resp)
            end
            handle RPC =>
               (
               disconnect ();
               raise RPC
               )
         end


      (* These method numbers must be consistent with RpcServer. *)

      fun close () =
         (case !theSock of
             NONE =>
                ()
           | SOME sock =>
                (
                send sock (Writer.write (U.writer (U.Cons (U.Byte 0w1, U.Nil))));
                disconnect ()
                ))


      fun shutdown () =
         (
         connectAndSend (Writer.write (U.writer (U.Cons (U.Byte 0w2, U.Nil))));
         disconnect ()
         )

   end

structure RpcClient = RpcClientFn(structure Params =
                                  struct
                                    fun getParams () =
                                        (Address.toInAddr (valOf (Address.fromString "127.0.0.1")),
                                         !Constants.rpcPort)
                                  end)
