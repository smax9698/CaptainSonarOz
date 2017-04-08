functor
import 
   Input
   OS
   Browser
export
   portPlayer:StartPlayer
define
   StartPlayer
   TreatStream
   Browse = Browser.browse
   RandPosWater
   CheckPosition
in
    fun{StartPlayer Color ID}
       Stream
       Port
    in
        {NewPort Stream Port}
        thread
        {TreatStream Stream id(id:ID color:Color name:_)}
        end
        Port
    end

    % Retourne true si case eau et false si case terre
    fun{CheckPosition X Y}
       fun{CPX X Y Map}
	  fun{CPY Y Line}
	     if Y == 1 then Line.1 == 0
	     else
		{CPY Y-1 Line.2}
	     end
	  end
       in
	  if X == 1 then
	     {CPY Y Map.1}
	  else
	     {CPX X-1 Y Map.2}
	  end
       end
    in
       {CPX X Y Input.map}
    end

    % retourne une position aleatoire dans l'eau
    fun{RandPosWater}
       X Y
    in
       X=({OS.rand} mod Input.nColumn)+1 
       Y=({OS.rand} mod Input.nRow)+1
       {Browse X|Y}
       if {CheckPosition X Y} then pt(x:X y:Y)
       else
	  {RandPosWater}
       end
    end
    
    proc{TreatStream Stream Id} % has as many parameters as you want
       case Stream
       of nil then skip
       [] initPosition(ID Position)|T then ID=Id Position={RandPosWater}
	  {TreatStream T Id}
       end
    end
end
