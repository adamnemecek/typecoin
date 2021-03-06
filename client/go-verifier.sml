
structure Go =
   struct

      structure A = Arguments

      fun >>= (r, f) = A.bind r f
      fun >> (r, r') = A.seq r r'
      infixr 3 >>= >>
      
      val flags =
         [
         A.full "-rpcport" (A.assign Constants.rpcPort A.int),
         A.full "-testnet" (A.exec (fn () => Chain.theChain := Chain.testnet)),
         A.prefix' "-" (A.call (fn flag => (print ("Unknown option "^flag^"\n"); raise A.Usage)))
         ]
      
      val parser =
         A.scan flags
         >>
         A.int
         >>= (fn first =>
         A.int
         >>= (fn last =>
         A.string
         >>= (fn logfile =>
         A.eol
         >>
         A.exec (fn () => Verifier.verifier first last logfile)
         )))

      val usage = "Usage: verifier [options ...] first-block last-block log-file\n    -rpcport <number>   port for rpc server\n    -testnet            run on testnet\n"

      val () =
         A.parse parser usage (CommandLine.arguments ())

   end
