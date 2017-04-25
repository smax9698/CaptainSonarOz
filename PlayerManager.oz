functor
import
   PlayerXXXMyCustomName
   PlayerXXXAI
   PlayerAdvancedAI
export
   playerGenerator:PlayerGenerator
define
   PlayerGenerator
in
   fun{PlayerGenerator Kind Color ID}
      case Kind
      of basicAI then {PlayerXXXMyCustomName.portPlayer Color ID}
      [] advancedAI then {PlayerXXXAI.portPlayer Color ID}
      end
   end
end