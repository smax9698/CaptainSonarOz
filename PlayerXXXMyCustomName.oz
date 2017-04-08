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
        {TreatStream Stream id(id:ID color:Color name:_) arme(missile:0 mine:0 sonar:0 drone:0) 0 pt(x:1 y:1)}
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
    
    proc{TreatStream Stream Id Arme Surface Position} % has as many parameters as you want
       case Stream
       of nil then skip
       [] initPosition(ID Pos)|T then ID=Id Pos={RandPosWater}
	  {TreatStream T Id Arme Surface Pos}
       [] dive|T then
	  {TreatStream T Id Arme 0 Position}
       [] isSurface(ID Ans)|T then ID=Id Ans=(Surface > 0)
	  if Ans then
	     {TreatStream T Id Arme (Surface+1 mod 4) Position}
	  else
	     {TreatStream T Id Arme 0 Position}
	  end
       [] move(ID Pos Dir)|T then true
       [] chargeItem(ID KindItem)|T then true
       [] fireItem(ID KindFire)|T then true
       [] fireMine(ID Mine)|T then true
       [] sayMove(ID Dir)|T then true 
       [] saySurface(ID) then true 
       [] sayCharge(ID KindItem) then true
       [] sayMinePlaced(ID) then true 
       [] sayMissileExplode(ID Pos Message) then true
       [] sayMineExplde(ID Pos Message) then true 
       [] sayPassingDrone(Drone ID Ans) then true 
       [] sayAnswerDrone(Drone ID Ans) then true
       [] sayPassingSonar(ID Ans) then true 
       [] sayAnswerSonar(ID Ans) then true
       [] sayDeath(ID) then true 
       [] sayDamageTaken(ID Damage LifeLeft) then true
       end
    end
end
