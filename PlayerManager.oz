functor
import
   Player033Basic
   Player033Advanced
export
   playerGenerator:PlayerGenerator
define
   PlayerGenerator
in
   fun{PlayerGenerator Kind Color ID}
      case Kind
      of basicAI then {Player033Basic.portPlayer Color ID}
      [] advancedAI then {Player033Advanced.portPlayer Color ID}
      end
   end
end