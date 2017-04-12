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
in
    fun{StartPlayer Color ID}
       Stream
       Port
    in
        {NewPort Stream Port}
        thread
        {TreatStream Stream id(id:ID color:Color name:_) arme(missile:2 mine:2 sonar:2 drone:2) true nil}
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
       X=({OS.rand} mod Input.nColumn)+1 
       Y=({OS.rand} mod Input.nRow)+1
       if {CheckPosition X Y} then pt(x:X y:Y)
       else
	  {RandPosWater}
       end
    end

    % Retourne la direction choisie de facon aléatoire. Si aucune direction n'est possible 
    fun{ChooseRandDirection ListPos}
       R Dir
    in
       R = ({OS.rand} mod 4) + 1
       
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
       R = ({OS.rand} mod 4) + 1
       if R == 1 then % missile
	  ArmeRecordSub = {Record.subtract ArmeRecord missile}
	  NewArmeRecord = {AdjoinAt ArmeRecordSub missile (ArmeRecord.missile + 1)}
       elseif R == 2 then % sonar
	  ArmeRecordSub = {Record.subtract ArmeRecord sonar}
	  NewArmeRecord = {AdjoinAt ArmeRecordSub sonar (ArmeRecord.sonar + 1)}
       elseif R == 3 then % drone
	  ArmeRecordSub = {Record.subtract ArmeRecord drone}
	  NewArmeRecord = {AdjoinAt ArmeRecordSub drone (ArmeRecord.drone + 1)}
       else % mine
	  ArmeRecordSub = {Record.subtract ArmeRecord mine}
	  NewArmeRecord = {AdjoinAt ArmeRecordSub mine (ArmeRecord.mine + 1)}
       end
       {Browse NewArmeRecord}
       NewArmeRecord
    end

    fun{NewItem OldItem NewIt}
       Item
    in
       {Browse OldItem.missile}
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
       {Browse Item}
       Item
    end
  
    proc{TreatStream Stream Id Arme Surface ListPosition} % has as many parameters as you want
       case Stream
       of nil then skip
       [] initPosition(ID Pos)|T then ID=Id Pos={RandPosWater}
	  {TreatStream T Id Arme Surface Pos|ListPosition}
       [] dive|T then
	  {TreatStream T Id Arme false ListPosition}
       [] isSurface(ID Ans)|T then ID=Id Ans=Surface
	  {TreatStream T Id Arme Surface ListPosition}
       [] move(ID Pos Dir)|T then
	  ID = Id
	  Dir = {ChooseRandDirection ListPosition}
	  if Dir == west then Pos = pt(x:ListPosition.1.x y:(ListPosition.1.y-1))
	  elseif Dir == east then Pos = pt(x:ListPosition.1.x y:(ListPosition.1.y+1)) 
	  elseif Dir == south then Pos = pt(x:(ListPosition.1.x+1) y:ListPosition.1.y)
	  elseif Dir == north then Pos = pt(x:(ListPosition.1.x-1) y:ListPosition.1.y)
	  else Pos = ListPosition.1
	  end
	  {TreatStream T Id Arme (Dir==surface) Pos|ListPosition}
       [] chargeItem(ID KindItem)|T then
	  NewArme
       in
	  ID=Id
	  NewArme={ChargeItemRand Arme}
	  KindItem = {NewItem Arme NewArme}
	  {TreatStream T Id NewArme Surface ListPosition}
       [] fireItem(ID KindFire)|T then {TreatStream T Id Arme Surface ListPosition}
       [] fireMine(ID Mine)|T then {TreatStream T Id Arme Surface ListPosition}
       [] sayMove(ID Dir)|T then {TreatStream T Id Arme Surface ListPosition}
       [] saySurface(ID)|T then {TreatStream T Id Arme Surface ListPosition}
       [] sayCharge(ID KindItem)|T then {TreatStream T Id Arme Surface ListPosition}
       [] sayMinePlaced(ID)|T then {TreatStream T Id Arme Surface ListPosition} 
       [] sayMissileExplode(ID Pos Message)|T then {TreatStream T Id Arme Surface ListPosition}
       [] sayMineExplde(ID Pos Message)|T then {TreatStream T Id Arme Surface ListPosition}
       [] sayPassingDrone(Drone ID Ans)|T then {TreatStream T Id Arme Surface ListPosition}
       [] sayAnswerDrone(Drone ID Ans)|T then {TreatStream T Id Arme Surface ListPosition}
       [] sayPassingSonar(ID Ans)|T then {TreatStream T Id Arme Surface ListPosition}
       [] sayAnswerSonar(ID Ans)|T then {TreatStream T Id Arme Surface ListPosition}
       [] sayDeath(ID)|T then {TreatStream T Id Arme Surface ListPosition}
       [] sayDamageTaken(ID Damage LifeLeft)|T then {TreatStream T Id Arme Surface ListPosition}
       end
    end
end
