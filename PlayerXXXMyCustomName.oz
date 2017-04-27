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
   DeleteMine
   ExplodeMine
   Dist
   ChargeItemRand
   NewItem
   PersonalNewRecord
   FindPlaceForFire
   ChooseFire
   FireArme
in
   % Lance le joueur avec ses paramètres initiaux :
   % record id : contient l'identifiant du joueur.
   % record arme : contient le nombre de charge pour chaque arme.
   % Boolean Surface : est à true si le sous-marin est la surface et a false sinon (initialement à true).
   % Liste ListPosition : contient l'ensemble des position parcourue dans l'ordre anti-chronologique (initialement à nil).
   % Liste ListMine : contient l'ensemble des mines placées par le joueur
   % Entier MyLife : Vie actuelle du joueur
   fun{StartPlayer Color ID}
      Stream
      Port
   in
      {NewPort Stream Port}
      thread
	 {TreatStream Stream id(id:ID color:Color name:ID) arme(missile:0 mine:0 sonar:0 drone:0) true nil nil Input.maxDamage}
      end
      Port
   end

    % Retourne true si la case est une case eau et false si case est une case terre ou est hors de la carte
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
      if X < 1 orelse X  > Input.nRow then % verifie que la case est dans la carte
	 Rep=false
      elseif Y < 1 orelse Y > Input.nColumn then % verifie que la case est dans la carte
	 Rep=false
      else % la case est dans la carte
	 Rep={CPX X Y Input.map}
      end
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

      % On test dans un ordre aléatoire les 4 directions possibles et on s'arrête des qu'on en trouve une acceptable
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

	 % Si aucune direction n'est possible, on fait surface.
	 if D == 4 then
	    Dir=surface
	    {U}
	 end
      end
      Dir
   end

    % On charge une arme de facon aleatoire et on retourne un nouveau record arme
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
      elseif R == 4 then % mine
	 ArmeRecordSub = {Record.subtract ArmeRecord mine}
	 NewArmeRecord = {AdjoinAt ArmeRecordSub mine (ArmeRecord.mine + 1)}
      else
	 NewArmeRecord=nil
      end
      NewArmeRecord

   end


   % Determine si une arme a ete crée
   fun{NewItem OldItem NewIt}
      Item
   in
      if NewIt.missile > OldItem.missile andthen (NewIt.missile mod Input.missile) == 0 then
	 Item=missile
      elseif NewIt.mine > OldItem.mine andthen (NewIt.mine mod Input.mine) == 0 then
	 Item=mine
      elseif NewIt.sonar > OldItem.sonar andthen (NewIt.sonar mod Input.sonar) == 0 then
	 Item=sonar
      elseif NewIt.drone > OldItem.drone andthen (NewIt.drone mod Input.drone) == 0 then
	 Item=drone
      else
	 Item=nil
      end
      Item
   end

   % Determine une case ou l'on peut tirer/placer une arme
   fun{FindPlaceForFire Min Max Position}
      S X Y
   in
      S = ({OS.rand} mod ((Max-Min)+1)) + Min
      X = (S - {OS.rand} mod (S+1)) * {Pow ~1 ({OS.rand} mod 2 + 1)}
      Y = (S - {Abs X}) * {Pow ~1 ({OS.rand} mod 2 + 1)}

      if {CheckPosition Position.x+X Position.y+Y} then
	 pt(x:(Position.x+X) y:(Position.y+Y))
      else
	 {FindPlaceForFire Min Max Position}
      end

   end

   % Modifie un champ d'un record en retournant un nouveau record qui est une copie modifiée du record initial
   fun{PersonalNewRecord R Feat Val}
      PNRSub NewR
   in
      PNRSub = {Record.subtract R Feat}
      NewR = {AdjoinAt R Feat Val}
   end

   % Retourne le record arme modifié après un tir
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

   fun{Dist Pt1 Pt2}
      {Abs Pt1.x-Pt2.x} + {Abs Pt1.y-Pt2.y}
   end

   % Dès qu'une arme est chargée, on la choisit.
   fun{ChooseFire Arme Position}
      Fire
   in
      if Arme.sonar >= Input.sonar then
	 Fire=sonar
      elseif Arme.missile >= Input.missile then
	 Fire=missile({FindPlaceForFire {Max 2 Input.minDistanceMissile} Input.maxDistanceMissile Position})

      elseif Arme.drone >= Input.drone then
	 Fire=drone(row (({OS.rand} mod Input.nRow)+1))
      elseif Arme.mine >= Input.mine then
	 Fire=mine({FindPlaceForFire Input.minDistanceMine Input.maxDistanceMine Position})
      else Fire=nil
      end
      Fire
   end

   fun{ExplodeMine ListMine Pos}
      case ListMine
      of H|T then
	 if {Dist H Pos} >= 2 then
	    H
	 else {ExplodeMine T Pos}
	 end
      [] nil then nil
      end
   end

   fun{DeleteMine ListeMine Mine}
      case ListeMine
      of H|T then
	 if H == Mine then
	    {DeleteMine T Mine}
	 else
	    H|{DeleteMine T Mine}
	 end
      [] nil then nil
      end
   end


   proc{TreatStream Stream Id Arme Surface ListPosition ListMine MyLife} % has as many parameters as you want
      NewArme
   in
      case Stream
      of nil|T then skip
	 % On chosit une position aléatoire correcte
      [] initPosition(ID Pos)|T then Pos={RandPosWater}
	 if MyLife > 0 then
	    ID=Id
	    {TreatStream T Id Arme Surface Pos|ListPosition ListMine MyLife}
	 else
	    ID=nil
	    {TreatStream T Id Arme Surface Pos|ListPosition ListMine MyLife}
	 end

	 % On met la variable Surface a false
      [] dive|T then
	 case ListPosition of H|U then
	    {TreatStream T Id Arme false H|nil ListMine MyLife}
	 else
	    {TreatStream T Id Arme false ListPosition ListMine MyLife}
	 end

	 % On donne à Ans la valeur de la variable Surface
      [] isSurface(ID Ans)|T then  
	 if MyLife > 0 then
	    Ans=Surface ID=Id
	    {TreatStream T Id Arme Surface ListPosition ListMine MyLife}
	 else
	    Ans = false
	    ID=nil
	    {TreatStream T Id Arme Surface ListPosition ListMine MyLife}
	 end

	 % On fait appel à la fonction ChooseRandDirection et on modifie notre position en fonction du resultat
      [] move(ID Pos Dir)|T then
	 if MyLife > 0 then
	    Dir = {ChooseRandDirection ListPosition}
	    if Dir == west then Pos = pt(x:ListPosition.1.x y:(ListPosition.1.y-1))
	    elseif Dir == east then Pos = pt(x:ListPosition.1.x y:(ListPosition.1.y+1))
	    elseif Dir == south then Pos = pt(x:(ListPosition.1.x+1) y:ListPosition.1.y)
	    elseif Dir == north then Pos = pt(x:(ListPosition.1.x-1) y:ListPosition.1.y)
	    else Pos = ListPosition.1
	    end
	    ID = Id
	    {TreatStream T Id Arme (Dir==surface) Pos|ListPosition ListMine MyLife}
	 else
	    Dir = nil
	    Pos = nil
	    ID = nil
	    {TreatStream T Id Arme Surface ListPosition ListMine MyLife}
	 end

	 % On choisit une arme à charger et on indique si une nouvelle arme a été créée
      [] chargeItem(ID KindItem)|T then
	 if MyLife > 0 then
	    NewArme={ChargeItemRand Arme} % Nouveau record arme avec une arme ayant recu une charge supplémentaire
	    KindItem = {NewItem Arme NewArme} % KindItem n'est pas nil si une nouvelle arme a été créée
	    ID=Id
	    {TreatStream T Id NewArme Surface ListPosition ListMine MyLife}
	 else
	    KindItem = nil
	    ID = nil
	    {TreatStream T Id Arme Surface ListPosition ListMine MyLife}
	 end
	 

	 % On choisit l'arme a utliser
      [] fireItem(ID KindFire)|T then
	 if MyLife > 0 then
	    KindFire={ChooseFire Arme ListPosition.1} % KindFire n'est pas nil si une arme peut-être tirée
	    NewArme={FireArme Arme KindFire} % Nouveau record arme avec une arme utilisée et donc ayant perdu des charges
	    ID=Id
	    case KindFire of mine(P) then
	       {TreatStream T Id NewArme Surface ListPosition P|ListMine MyLife}
	    else
	       {TreatStream T Id NewArme Surface ListPosition ListMine MyLife}
	    end
	 else
	    KindFire = nil
	    ID = nil
	    {TreatStream T Id Arme Surface ListPosition ListMine MyLife}
	 end
	 
	 % On décide de faire exploser une mine si une mine est disponible
      [] fireMine(ID Mine)|T then
	 if MyLife > 0 then
	    Mine={ExplodeMine ListMine ListPosition.1}
	    ID=Id
	    if Mine == nil then
	       {TreatStream T Id Arme Surface ListPosition ListMine MyLife}
	    else
	       {TreatStream T Id Arme Surface ListPosition {DeleteMine ListMine Mine} MyLife}
	    end
	 else
	    Mine = nil
	    ID = nil
	    {TreatStream T Id Arme Surface ListPosition ListMine MyLife}
	 end
	 

      [] sayMove(ID Dir)|T then
	 {TreatStream T Id Arme Surface ListPosition ListMine MyLife}

      [] saySurface(ID)|T then
	 {TreatStream T Id Arme Surface ListPosition ListMine MyLife}
	 
      [] sayCharge(ID KindItem)|T then
	 {TreatStream T Id Arme Surface ListPosition ListMine MyLife}

      [] sayMinePlaced(ID)|T then
	 {TreatStream T Id Arme Surface ListPosition ListMine MyLife}

	 % On determine si on est touché ou non par le missile
      [] sayMissileExplode(ID Pos Message)|T then
	 if MyLife > 0 then
	    Distance
	 in
	  %check if we are touch by the explosion
	    case Pos of pt(x:X y:Y) then
	       Distance = ({Abs X-ListPosition.1.x} + {Abs Y-ListPosition.1.y})
	       if Distance>=2 then
		  Message=nil
	       elseif Distance==1 then
		  Message = 1
	       else
		  Message = 2
	       end
	    end
	    if Message \= nil then
	       {TreatStream T Id Arme Surface ListPosition ListMine {Max 0 MyLife-Message}}
	    else
	       {TreatStream T Id Arme Surface ListPosition ListMine MyLife}
	    end
	 
	 else
	    Message = nil
	    {TreatStream T Id Arme Surface ListPosition ListMine MyLife}
	 end
	 

      [] sayMineExplode(ID Pos Message)|T then
	 if MyLife > 0 then
	    Distance
	 in
	  %check if we are touch by the explosion
	    case Pos of pt(x:X y:Y) then
	       Distance = ({Abs X-ListPosition.1.x} + {Abs Y-ListPosition.1.y})
	       if(Distance>=2) then
		  Message = nil
	       elseif(Distance==1) then
		  Message = 1
	       else
		  Message = 2
	       end
	    end
	    if Message \= nil then
	       {TreatStream T Id Arme Surface ListPosition ListMine {Max 0 MyLife-Message}}
	    else
	       {TreatStream T Id Arme Surface ListPosition ListMine MyLife}
	    end
	 
	 else
	    {TreatStream T Id Arme Surface ListPosition ListMine MyLife}
	 end

      [] sayPassingDrone(Drone ID Ans)|T then
	 if MyLife > 0 then
	  %check if we are in the row or column of the drone
	    case Drone of drone(row X) then
	       Ans=(X == ListPosition.1.x)
	    [] drone(column Y) then
	       Ans=(Y == ListPosition.1.y)
	    end
	    ID = Id
	    {TreatStream T Id Arme Surface ListPosition ListMine MyLife}
	 else
	    ID = nil
	    {TreatStream T Id Arme Surface ListPosition ListMine MyLife}
	 end

      [] sayAnswerDrone(Drone ID Ans)|T then
	 {TreatStream T Id Arme Surface ListPosition ListMine MyLife}

      [] sayPassingSonar(ID Ans)|T then
	 if MyLife > 0 then 
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
	    {TreatStream T Id Arme Surface ListPosition ListMine MyLife}
	 else
	    Ans = false
	    ID = nil
	    {TreatStream T Id Arme Surface ListPosition ListMine MyLife}
	 end

      [] sayAnswerSonar(ID Ans)|T then
	 {TreatStream T Id Arme Surface ListPosition ListMine MyLife}

      [] sayDeath(ID)|T then
	 if ID.id == Id.id then
	    {Browse deadAt|ListPosition.1}
	 end
	 {TreatStream T Id Arme Surface ListPosition ListMine MyLife}

      [] sayDamageTaken(ID Damage LifeLeft)|T then
	 {TreatStream T Id Arme Surface ListPosition ListMine MyLife}
      else
	 {Browse unknown_instruction}
	 skip
      end
   end
end