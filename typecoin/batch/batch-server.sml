structure T = Thread (structure T = ThreadBase
                      structure RC = SelectReactorCore
                      structure C = ConfigPrintEverything)

structure CV = CondVar(T)
structure CS = ChiralSocketFn(T)
structure SU = ChiralSockUtil(CS)
structure LR = LineReader(CS.Socket)


structure BatchAction =
struct
  local
      open Unityped
  in


  fun decodeChain chain = valOf (IOTypes.readFromVector TypeCoinTxn.readChain chain)
  fun decodeBody body = valOf (IOTypes.readFromVector TypeCoinTxn.readTxn_body body)

  fun encodeBody body = Bytestring (IOTypes.writeToVector TypeCoinTxn.writeTxn_body body)

  fun Resid id = Int (Int32.toInt id)
  fun BatchTxnId id = Int (Int32.toInt id)

  fun List f [] = Nil
    | List f (x::xs) = Cons (f x, List f xs)

  fun action userid (method : Word8.word) args =
      (case (method, args) of
           (0w10, Cons (Bytestring chain, Cons (String txnid, Int idx))) =>
           Resid (
             Batch.depositResource
                 userid
                 (decodeChain chain)
                 (txnid, idx))

         | (0w11, Cons (Bytestring chain, Bytestring body)) =>
           let val (txnid, resids) = Batch.makeTransaction
                                         userid
                                         (decodeChain chain)
                                         (decodeBody body)
           in Cons (BatchTxnId txnid,
                    List Resid resids)
           end

         | (0w12, Int resid) =>
           let val (txn_body, txnid) = Batch.withdrawResource userid (Int32.fromInt resid)
           in Cons (encodeBody txn_body, String txnid) end

         | _ => Method
      )


  end
end


structure BatchServer =
struct
  val default_port = 5124

  structure BS = Bytestring
  structure U = Unityped



  fun batch_server (conn, conn_addr) () =
      let
          (* First, we "authenticate" by reading in the userid the connection thinks it is *)
          (* XXX: should do some sort of actual authentication at all. *)
          val userid = SU.recvVec (conn, 20)

          val () = print ("Got batch server connection from " ^ TypeCoinTxn.toHexId userid ^ "\n")

          fun loop () =
              let val sz = Word32.toInt (ConvertWord.bytesToWord32B (SU.recvVec (conn, 4)))
                  val line = SU.recvVec (conn, sz)
                  val request = Reader.readfull U.reader line

                  val response =
                      (case request of
                           U.Cons (U.Byte method, args) =>
                           (case method of
                                (* should handle any top level things *)
                                _ =>
                                    (BatchAction.action userid method args
                                     handle exn => U.Exception (U.String (exnMessage exn))))
                         | _ => U.Method)

                  val response_str = Writer.write (U.writer response)

                  val () = SU.sendVec (conn, (ConvertWord.word32ToBytesB (Word32.fromInt (BS.size response_str))))
                  val () = SU.sendVec (conn, response_str)

              in SU.sendVec (conn, line);
                 loop ()
              end

      in loop () end


  (* Adapted from some Stilts code *)
  fun spawn_server addr application =
      let
          val listener = CS.INetSock.TCP.socket ()

          val (server_host, server_port) = CS.INetSock.fromAddr addr
          val sbind = (NetHostDB.toString server_host, server_port)

          fun accept () = let
              val conn = CS.Socket.accept listener
              val t = T.new (application conn)
          in
              accept ()
          end

          fun app () = (
              CS.Socket.Ctl.setREUSEADDR (listener, true);
              CS.Socket.bind (listener, addr);
              CS.Socket.listen (listener, 9);
              accept ()
          ) handle x => (CS.Socket.close listener; raise x)

    in
      T.new app
    end


  fun main _ =
      let val () = print "Listening...\n"
          val serverthread = spawn_server (INetSock.any default_port) batch_server
      in
          T.run ();
          0
      end


end
