functor
import 
   Input
   Browser
export
   portPlayer:StartPlayer
define
   StartPlayer
   TreatStream
   Browse = Browser.browse
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
       case Stream
       of nil then skip
       [] hello|T then {Browse 'hello how are you'}
	  {TreatStream T}
       [] hh|T then {Browse 'HEIL HITLER'}
	  {TreatStream T}
       end
    end
end
