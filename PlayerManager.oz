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
      of playerxxxcustomname then {PlayerXXXMyCustomName.portPlayer Color ID}
      end
end end