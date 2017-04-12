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
   ChooseRandDirection
   CheckPosition
   CheckList
   ChargeItemRand
   NewItem
   PersonalNewRecord
   FindPlaceForFire
   ChooseFire
   FireArme
in
   fun{StartPlayer Color ID}
      Stream
      Port
   in
      {NewPort Stream Port}
      thread
	 {TreatStream Stream id(id:ID color:Color name:_) arme(missile:0 mine:0 sonar:0 drone:0) true nil}
      end
      Port
   end

    % Retourne true si case eau et false si case terre ou hors de la carte
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
      Rep
   in
      if X < 1 orelse X  > Input.nRow then  {Browse 'out of the map' } Rep=false
      elseif Y < 1 orelse Y > Input.nColumn then {Browse 'out of the map'} Rep=false
      else Rep={CPX X Y Input.map} end
      Rep
   end

    
    % Renvoie true si NewPos est dans la liste des positions et false sinon
   fun{CheckList List NewPos}
      case List of pt(x:X y:Y)|T then
	 if NewPos.x == X andthen NewPos.y == Y then
	    true
	 else
	    {CheckList T NewPos}
	 end
      [] nil then false
      end
   end

    % retourne une position aleatoire dans l'eau
   fun{RandPosWater}
      X Y
   in
      X=({OS.rand} mod Input.nRow)+1 
      Y=({OS.rand} mod Input.nColumn)+1
      if {CheckPosition X Y} then pt(x:X y:Y)
      else
	 {RandPosWater}
      end
   end

    % Retourne la direction choisie de facon aléatoire. Si aucune direction n'est possible 
   fun{ChooseRandDirection ListPos}
      R Dir
   in
      R = ({OS.rand} mod 4)
      for D in 1..4 break:U do
	 Z in
	 Z = ((R+D) mod 4) + 1
	 if Z == 1 then % west
	    if ({CheckPosition ListPos.1.x ListPos.1.y-1} andthen {CheckList ListPos pt(x:ListPos.1.x y:(ListPos.1.y-1))}==false) then
	       Dir = west
	       {U}
	    end
	 elseif Z == 2 then % south
	    if {CheckPosition ListPos.1.x+1 ListPos.1.y} andthen {CheckList ListPos pt(x:(ListPos.1.x+1) y:ListPos.1.y)}==false then
	       Dir = south
	       {U}
	    end
	 elseif Z == 3 then % east
	    if {CheckPosition ListPos.1.x ListPos.1.y+1} andthen {CheckList ListPos pt(x:ListPos.1.x y:(ListPos.1.y+1))}==false then
	       Dir = east
	       {U}
	    end
	 else % north
	    if {CheckPosition ListPos.1.x-1 ListPos.1.y} andthen {CheckList ListPos pt(x:(ListPos.1.x-1) y:ListPos.1.y)}==false then
	       Dir=north
	       {U}
	    end
	 end

	 if D == 4 then
	    Dir=surface
	    {U}
	 end
      end
      Dir
   end  

   fun{ChargeItemRand ArmeRecord}
      R ArmeRecordSub NewArmeRecord
   in
       
      if ArmeRecord.missile == 3 andthen ArmeRecord.mine == 3 andthen ArmeRecord.drone == 3 andthen ArmeRecord.sonar == 3 then
	 NewArmeRecord=nil
      else
	 R = ({OS.rand} mod 4)
	 for D in 1..4 break:U do
	    Z in
	    Z = ((R+D) mod 4) + 1
	    if Z == 1 andthen ArmeRecord.missile < 3 then % missile
	       ArmeRecordSub = {Record.subtract ArmeRecord missile}
	       NewArmeRecord = {AdjoinAt ArmeRecordSub missile (ArmeRecord.missile + 1)}
	       {U}
	    elseif Z == 2 andthen ArmeRecord.sonar < 3 then % sonar
	       ArmeRecordSub = {Record.subtract ArmeRecord sonar}
	       NewArmeRecord = {AdjoinAt ArmeRecordSub sonar (ArmeRecord.sonar + 1)}
	       {U}
	    elseif Z == 3 andthen ArmeRecord.drone < 3 then % drone
	       ArmeRecordSub = {Record.subtract ArmeRecord drone}
	       NewArmeRecord = {AdjoinAt ArmeRecordSub drone (ArmeRecord.drone + 1)}
	       {U}
	    elseif Z == 4 andthen ArmeRecord.mine < 3 then % mine
	       ArmeRecordSub = {Record.subtract ArmeRecord mine}
	       NewArmeRecord = {AdjoinAt ArmeRecordSub mine (ArmeRecord.mine + 1)}
	       {U}
	    else
	       NewArmeRecord=nil
	       {U}
	    end
	 end
      end
      NewArmeRecord
   end

   fun{NewItem OldItem NewIt}
      Item
   in
      if NewIt.missile > OldItem.missile andthen NewIt.missile == Input.missile then
	 Item=missile
      elseif NewIt.mine > OldItem.mine andthen NewIt.mine == Input.mine then
	 Item=mine
      elseif NewIt.sonar > OldItem.sonar andthen NewIt.sonar == Input.sonar then
	 Item=sonar
      elseif NewIt.drone > OldItem.drone andthen NewIt.drone == Input.drone then
	 Item=drone
      else
	 Item=nil
      end
      Item
   end

   fun{FindPlaceForFire Min Max Position}
      P
   in
      P=pt(x:1 y:1)
   end

   fun{PersonalNewRecord R Feat Val}
      PNRSub NewR
   in
      PNRSub = {Record.subtract R Feat}
      NewR = {AdjoinAt R Feat Val}
   end
   
   fun{FireArme Arme Kind}
      case Kind of nil then Arme
      [] sonar then {PersonalNewRecord Arme sonar Arme.sonar-Input.sonar}
      [] missile(pt(x:X y:Y)) then {PersonalNewRecord Arme missile Arme.missile-Input.missile}
      [] drone(row X) then {PersonalNewRecord Arme drone Arme.drone-Input.drone}
      [] drone(column Y) then {PersonalNewRecord Arme drone Arme.drone-Input.drone}
      [] mine(pt(x:X y:Y)) then {PersonalNewRecord Arme mine Arme.mine-Input.mine}
      else Arme
      end	 
   end
   
   fun{ChooseFire Arme Position}
      Fire
   in
      if Arme.sonar >= Input.sonar then
	 Fire=sonar
      elseif Arme.missile >= Input.missile then
	 Fire=missile({FindPlaceForFire Input.minDistanceMissile Input.maxDistanceMissile Position})
      elseif Arme.drone >= Input.drone then
	 Fire=drone(row (({OS.rand} mod Input.nRow)+1))
      elseif Arme.mine >= Input.mine then
	 Fire=mine({FindPlaceForFire Input.minDistanceMine Input.maxDistanceMine Position})
      else Fire=nil
      end
      Fire
   end
  
   proc{TreatStream Stream Id Arme Surface ListPosition} % has as many parameters as you want
      NewArme
   in
      case Stream
      of nil then skip
      [] initPosition(ID Pos)|T then Pos={RandPosWater} ID=Id
	 {TreatStream T Id Arme Surface Pos|ListPosition}
      [] dive|T then
	 {TreatStream T Id Arme false ListPosition}
      [] isSurface(ID Ans)|T then  Ans=Surface ID=Id
	 {TreatStream T Id Arme Surface ListPosition}
      [] move(ID Pos Dir)|T then
	 Dir = {ChooseRandDirection ListPosition}
	 if Dir == west then Pos = pt(x:ListPosition.1.x y:(ListPosition.1.y-1))
	 elseif Dir == east then Pos = pt(x:ListPosition.1.x y:(ListPosition.1.y+1)) 
	 elseif Dir == south then Pos = pt(x:(ListPosition.1.x+1) y:ListPosition.1.y)
	 elseif Dir == north then Pos = pt(x:(ListPosition.1.x-1) y:ListPosition.1.y)
	 else Pos = ListPosition.1
	 end
	 ID = Id
	 {TreatStream T Id Arme (Dir==surface) Pos|ListPosition}
      [] chargeItem(ID KindItem)|T then
	 NewArme={ChargeItemRand Arme}
	 KindItem = {NewItem Arme NewArme}
	 ID=Id
	 {TreatStream T Id NewArme Surface ListPosition}
      [] fireItem(ID KindFire)|T then
	 KindFire={ChooseFire Arme ListPosition.1}
	 NewArme={FireArme Arme KindFire}
	 ID=Id
	 {TreatStream T Id NewArme Surface ListPosition}
      [] fireMine(ID Mine)|T then
	 Mine=nil
	 ID=Id
	 {TreatStream T Id Arme Surface ListPosition}
	 
      [] sayMove(ID Dir)|T then
	 {Browse 'The player'(ID 'move in derection'(Dir))}
	 {TreatStream T Id Arme Surface ListPosition}
      [] saySurface(ID)|T then
	 {Browse 'The next player is at the surface'(ID)}
	 {TreatStream T Id Arme Surface ListPosition}
      [] sayCharge(ID KindItem)|T then {TreatStream T Id Arme Surface ListPosition}
      [] sayMinePlaced(ID)|T then
	 {Browse 'The next player placed a mine'(ID)}
	 {TreatStream T Id Arme Surface ListPosition} 
      [] sayMissileExplode(ID Pos Message)|T then
	 Distance
      in
	  %check if we are touch by the explosion
	 case Pos of pt(x:X y:Y) then
	    Distance = {Abs X-ListPosition.1.x} + {Abs Y-ListPosition.1.y}
	    if(Distance>=2) then
	       Message = 0
	    elseif(Distance==1) then
	       Message = 1
	    else
	       Message = 2
	    end
	 end
	 {TreatStream T Id Arme Surface ListPosition}
      [] sayMineExplode(ID Pos Message)|T then
	 Distance
      in
	  %check if we are touch by the explosion
	 case Pos of pt(x:X y:Y) then
	    Distance = {Abs X-ListPosition.1.x} + {Abs Y-ListPosition.1.y}
	    if(Distance>=2) then
	       Message =0
	    elseif(Distance==1) then
	       Message = 1
	    else
	       Message = 2
	    end
	 end
	  		
	 {TreatStream T Id Arme Surface ListPosition}
      [] sayPassingDrone(Drone ID Ans)|T then
	  %check if we are in the row or column of the drone
	 case Drone of drone(row X) then
	    Ans=(X == ListPosition.1.x)
	 [] drone(column Y) then
	    Ans=(Y == ListPosition.1.y)
	 end
	 ID = Id
	 {TreatStream T Id Arme Surface ListPosition}
      [] sayAnswerDrone(Drone ID Ans)|T then
	 {Browse 'The drone detect the player'(ID)}	  
	 {TreatStream T Id Arme Surface ListPosition}
      [] sayPassingSonar(ID Ans)|T then
	 X Y
      in
	  %random choice of wrong coordonate
	 if({OS.rand} mod 2) ==0 then
	    X=({OS.rand} mod Input.nRow)+1
	    Y = ListPosition.1.y
	 else
	    Y=({OS.rand} mod Input.nColumn)+1
	    X= ListPosition.1.x
	 end
	 Ans = pt(x:X y:Y)
	 ID = Id
	 {TreatStream T Id Arme Surface ListPosition}
      [] sayAnswerSonar(ID Ans)|T then
	 {Browse 'The sonar detect the player'(ID 'at position'(Ans))}
	 {TreatStream T Id Arme Surface ListPosition}
      [] sayDeath(ID)|T then
	 {Browse 'The next player is dead'(ID)}
	 {TreatStream T Id Arme Surface ListPosition}
      [] sayDamageTaken(ID Damage LifeLeft)|T then
	 {Browse 'Damage on player'(ID' number'(Damage) 'Lifeleft'(LifeLeft))}
	 {TreatStream T Id Arme Surface ListPosition}
      end
   end
end
