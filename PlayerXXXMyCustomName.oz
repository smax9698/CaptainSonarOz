functor
import 
   Input
export
   portPlayer:StartPlayer
define
   StartPlayer
   TreatStream
in
    fun{StartPlayer Color ID}
       Stream
       Port
    in
        {NewPort Stream Port}
        thread
        {TreatStream Stream}
        end
        Port
    end
    proc{TreatStream Stream} % has as many parameters as you want
       Stream=1
    end
end
