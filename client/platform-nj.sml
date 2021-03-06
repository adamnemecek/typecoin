
structure Platform :> PLATFORM =
   struct

(* No longer needed since v110.76

      structure SI = SMLofNJ.SysInfo

      val Socket_sameDesc =
         (case SI.getOSKind () of
             SI.WIN32 =>
                (* Work around broken Socket.sameDesc. *)
                let
                   fun getFd sd =
                      Unsafe.Object.toInt (List.nth (Unsafe.Object.toTuple (Unsafe.Object.toObject sd), 1))
                in
                   (fn (sd, sd') => getFd sd = getFd sd')
                end
           | _ =>
                Socket.sameDesc)

      val adjustSelectTimeout =
         (case SI.getOSKind () of
             SI.WIN32 =>
                (* On Windows, NJ waits twice the indicated timeout. *)
                (fn t => Time.fromMilliseconds (Time.toMilliseconds t div 2))
           | _ =>
                (fn t => t))

      fun fileExists filename =
         (OS.FileSys.fileSize filename; true)
         handle OS.SysErr _ => false
              | Overflow => true

      fun BinIO_openAppend filename =
         if fileExists filename then
            BinIO.openAppend filename
         else
            BinIO.openOut filename
*)
         
      fun hashWord32 w =
         MJHash.hashInc (ConvertWord.word32ToWord w) (ConvertWord.word32ToWord (Word32.>> (w, 0w1)))

   end
