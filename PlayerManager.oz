functor
import
   PlayerXXXMyCustomName
export
   playerGenerator:PlayerGenerator
define
   PlayerGenerator
in
   fun{PlayerGenerator Kind Color ID}
      case Kind
      of basicAI then {PlayerXXXMyCustomName.portPlayer Color ID}
      end
   end
end