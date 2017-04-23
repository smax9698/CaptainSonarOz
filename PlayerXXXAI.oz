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
   BuildList
   ExplodeMine
   NewAdvPosSonar
   MoveAdv
   NewAdvPosDrone
   PositionPlayerToTarget
   Dist
   ChargeItem
   FireDrone
   PlayerStatus
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

   
   fun{StartPlayer Color ID}
      Stream
      Port
      AdvPosition
      fun{SetAdvRecord Size Id}
	 fun{FillRecord R I N MyId}
	    if I>N then
	       R
	    else
	       if I == MyId then
		  R.I=posType(myself)
		  {FillRecord R I+1 N MyId}
	       else
		  R.I=nil
		  {FillRecord R I+1 N MyId}
	       end
	    end
	 end
      in
	 {FillRecord {MakeRecord adv {BuildList 1 Size}} 1 Size Id}
      end
   in
      {NewPort Stream Port}
      AdvPosition = {SetAdvRecord Input.nbPlayer ID}
      thread
	 {TreatStream Stream id(id:ID color:Color name:ID) arme(missile:0 mine:0 sonar:0 drone:0) true nil nil AdvPosition Input.maxDamage}
      end
      Port
   end

   
   fun{BuildList A Max}
      if A == Max then Max|nil
      else
	 A|{BuildList A+1 Max}
      end
   end

   % AdvStatus : record contenant le statut des adversaires (tracked, double,...)
   % Request : on demande si un joueur du record a un statut particulier (tracked, xRight,...)
   fun{PlayerStatus AdvStatus Request}
      Ans
   in
      if Request \= nil then
	 for I in 1..Input.nbPlayer break:U do
	    if AdvStatus.I \= nil then
	       if AdvStatus.I.1 == Request then
		  Ans = true
		  {U}
	       end
	    end
	    if I == Input.nbPlayer then
	       Ans = false
	       {U}
	    end
	 end
      else
	 
	 for I in 1..Input.nbPlayer break:U do
	    if AdvStatus.I == nil then
	       Ans = true
	       {U}
	    end
	    if I == Input.nbPlayer then
	       Ans = false
	       {U}
	    end
	 end
      end
      Ans
   end
  
   
   fun{MoveAdv R Id Dir}
      case R.(Id.id)
      of posType(A pt(x:X y:Y)) then
	 if Dir == west then {PersonalNewRecord R Id.id posType(A pt(x:X y:Y-1))}
	 elseif Dir == east then {PersonalNewRecord R Id.id posType(A pt(x:X y:Y+1))}
	 elseif Dir == south then {PersonalNewRecord R Id.id posType(A pt(x:X+1 y:Y))}
	 elseif Dir == north then {PersonalNewRecord R Id.id posType(A pt(x:X-1 y:Y))}
	 else
	    R
	 end
      [] posType(A pt(x:X1 y:Y1) pt(x:X2 y:Y2)) then
	 if Dir == west then
	    if {CheckPosition X1 Y1-1} == false then  {PersonalNewRecord R Id.id  posType(tracked pt(x:X2 y:Y2-1))}
	    elseif {CheckPosition X2 Y2-1} == false then {PersonalNewRecord R Id.id  posType(tracked pt(x:X1 y:Y1-1))}
	    else
	       {PersonalNewRecord R Id.id  posType(A pt(x:X1 y:Y1-1) pt(x:X2 y:Y2-1))}
	    end
	 elseif Dir == east then
	    if {CheckPosition X1 Y1+1} == false then  {PersonalNewRecord R Id.id  posType(tracked pt(x:X2 y:Y2+1))}
	    elseif {CheckPosition X2 Y2+1} == false then {PersonalNewRecord R Id.id  posType(tracked pt(x:X1 y:Y1+1))}
	    else
	       {PersonalNewRecord R Id.id  posType(A pt(x:X1 y:Y1+1) pt(x:X2 y:Y2+1))}
	    end
	 elseif Dir == south then
	    if {CheckPosition X1+1 Y1} == false then  {PersonalNewRecord R Id.id  posType(tracked pt(x:X2+1 y:Y2))}
	    elseif {CheckPosition X2+1 Y2} == false then {PersonalNewRecord R Id.id  posType(tracked pt(x:X1+1 y:Y1))}
	    else
	       {PersonalNewRecord R Id.id  posType(A pt(x:X1+1 y:Y1) pt(x:X2+1 y:Y2))}
	    end
	 elseif Dir == north then
	    if {CheckPosition X1-1 Y1} == false then {PersonalNewRecord R Id.id  posType(tracked pt(x:X2-1 y:Y2))}
	    elseif {CheckPosition X2-1 Y2} == false then {PersonalNewRecord R Id.id  posType(tracked pt(x:X1-1 y:Y1))}
	    else
	       {PersonalNewRecord R Id.id  posType(A pt(x:X1-1 y:Y1) pt(x:X2-1 y:Y2))}
	    end
	 else
	    R
	 end
      else
	 R
      end
   end
   
   
   fun{NewAdvPosDrone R Id Drone Ans}
      case R.(Id.id)
      of nil then
	 if Ans then
	    case Drone
	    of drone(row X) then {PersonalNewRecord R Id.id posType(xRight pt(x:X y:1))}
	    [] drone(column Y) then {PersonalNewRecord R Id.id posType(yRight pt(x:1 y:Y))}
	    end
	 else
	    R
	 end
      [] posType(xRight pt(x:X y:Y)) then
	 if Ans then
	    case Drone
	    of drone(row X2) then R
	    [] drone(column Y2) then {PersonalNewRecord R Id.id posType(tracked pt(x:X y:Y2))}
	    end
	 else
	    R
	 end
      [] posType(yRight pt(x:X y:Y)) then % On connaissait Y et maintenant on connait aussi X et donc la position exacte
	 if Ans then
	    case Drone
	    of drone(row X2) then {PersonalNewRecord R Id.id posType(tracked pt(x:X2 y:Y))}
	    [] drone(column Y2) then R
	    end
	 else
	    R
	 end
      [] posType(tracked pt(x:X y:Y)) then R
      [] posType(double pt(x:X1 y:Y1) pt(x:X2 y:Y2)) then % Pas de déduction possible (A VERIFIER)
	 case Drone
	 of drone(row Xd) then
	    if Ans then
	       if Xd == X1 andthen X1\=X2 then
		  {PersonalNewRecord R Id.id posType(tracked pt(x:X1 y:Y1))}
	       elseif Xd == X2 andthen X1\=X2 then
		  {PersonalNewRecord R Id.id posType(tracked pt(x:X2 y:Y2))}
	       else
		  R
	       end
	    else
	       if Xd == X1 andthen X1\=X2 then
		  {PersonalNewRecord R Id.id posType(tracked pt(x:X2 y:Y2))}
	       elseif Xd == X2 andthen X1\=X2 then
		  {PersonalNewRecord R Id.id posType(tracked pt(x:X1 y:Y1))}
	       else
		  R
	       end
	    end
	 [] drone(column Yd) then
	    if Ans then
	       if Yd == Y1 andthen Y1\=Y2 then
		  {PersonalNewRecord R Id.id posType(tracked pt(x:X1 y:Y1))}
	       elseif Yd == Y2 andthen Y1\=Y2 then
		  {PersonalNewRecord R Id.id posType(tracked pt(x:X2 y:Y2))}
	       else
		  R
	       end
	    else
	       if Yd == Y1 andthen Y1\=Y2 then
		  {PersonalNewRecord R Id.id posType(tracked pt(x:X2 y:Y2))}
	       elseif Yd == Y2 andthen Y1\=Y2 then
		  {PersonalNewRecord R Id.id posType(tracked pt(x:X1 y:Y1))}
	       else
		  R
	       end
	    end
	    
	 end
	    
      [] posType(firstGuess pt(x:X y:Y)) then
	 if Ans then
	    case Drone
	    of drone(row X2) then {PersonalNewRecord R Id.id posType(xRight pt(x:X2 y:Y))}
	    [] drone(column Y2) then {PersonalNewRecord R Id.id posType(yRight pt(x:X y:Y2))}
	    end
	 else
	    R
	 end
      else
	 R
      end
   end


   % P est l'information reçue par le sonar pr le joueur Id P = Pt(x:X y:Y). soit X soit Y est juste
   % NewAdvPosSonar traite l'information en conséquence et en déduit le plus d'information possible sur la position de l'adversaire
   fun{NewAdvPosSonar R Id P}

      case R.(Id.id)
      of nil then {PersonalNewRecord R Id.id posType(firstGuess P)} 
      [] posType(xRight pt(x:X y:Y)) then
	 if X \= P.x then % On connaissait X et maintenant on connait aussi Y et donc la position exacte
	    {PersonalNewRecord R Id.id posType(tracked pt(x:X y:P.y))}
	 else % On ne peut rien déduire 
	    R
	 end
      [] posType(yRight pt(x:X y:Y)) then % On connaissait Y et maintenant on connait aussi X et donc la position exacte
	 if Y \= P.y then
	    {PersonalNewRecord R Id.id posType(tracked pt(x:P.x y:Y))}
	 else % On ne peut rien déduire 
	    R
	 end
      [] posType(tracked pt(x:X y:Y)) then R 
      [] posType(double pt(x:X1 y:Y1) pt(x:X2 y:Y2)) then % Pas de déduction possible (A VERIFIER)
	 R
      [] posType(firstGuess pt(x:X y:Y)) then
	 if P.x==X andthen P.y==Y then % Pas de déduction possible
	    R 
	 elseif P.x\=X andthen P.y\=Y then % Deux position possible 
	    {PersonalNewRecord R Id.id posType(double pt(x:X y:P.y) pt(x:P.x y:Y))}
	 elseif P.x==X andthen P.y\=Y then % X est la bonne donnée
	    {PersonalNewRecord R Id.id posType(xRight pt(x:P.x y:P.y))}
	 else % Y est la bonne donnée
	    {PersonalNewRecord R Id.id posType(yRight pt(x:P.x y:P.y))}
	 end
      else
	 R
      end
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

    % On charge une arme en fonction du statut des adversaires
   fun{ChargeItem ArmeRecord AdvStatus}
      R
   in
      if {PlayerStatus AdvStatus nil} orelse {PlayerStatus AdvStatus firstGuess} then

	 {PersonalNewRecord ArmeRecord sonar ArmeRecord.sonar+1}
      elseif ({PlayerStatus AdvStatus tracked} == false andthen {PlayerStatus AdvStatus double} == false) andthen ({PlayerStatus AdvStatus xRight} orelse {PlayerStatus AdvStatus yRight}) then
	 R = {OS.rand} mod 4
	 if R =< 1 then
	    {PersonalNewRecord ArmeRecord sonar ArmeRecord.sonar+1}
	 elseif R == 2 then
	    {PersonalNewRecord ArmeRecord missile ArmeRecord.missile+1}
	 else
	    {PersonalNewRecord ArmeRecord mine ArmeRecord.mine+1}
	 end
      elseif ({PlayerStatus AdvStatus tracked} == false andthen {PlayerStatus AdvStatus double}) then
	 R = {OS.rand} mod 4
	 if R =< 1 then
	    {PersonalNewRecord ArmeRecord drone ArmeRecord.drone+1}
	 elseif R == 2 then
	    {PersonalNewRecord ArmeRecord missile ArmeRecord.missile+1}
	 else
	    {PersonalNewRecord ArmeRecord mine ArmeRecord.mine+1}
	 end
      elseif ({PlayerStatus AdvStatus tracked} andthen ({PlayerStatus AdvStatus double} orelse {PlayerStatus AdvStatus xRight} orelse {PlayerStatus AdvStatus yRight})) then
	 R = {OS.rand} mod 8
	 if R =< 2 then
	    {PersonalNewRecord ArmeRecord mine ArmeRecord.mine+1}
	 elseif R >= 5 then
	    {PersonalNewRecord ArmeRecord missile ArmeRecord.missile+1}
	 else
	    {PersonalNewRecord ArmeRecord sonar ArmeRecord.sonar+1}
	 end
      elseif ({PlayerStatus AdvStatus tracked} andthen {PlayerStatus AdvStatus double} == false andthen ({PlayerStatus AdvStatus xRight} == false andthen {PlayerStatus AdvStatus yRight})) == false then
	 R = {OS.rand} mod 2
	 if R == 0 then
	    {PersonalNewRecord ArmeRecord missile ArmeRecord.missile+1}
	 else
	    {PersonalNewRecord ArmeRecord mine ArmeRecord.mine+1}
	 end
      else
	 R = {OS.rand} mod 4
	 if R == 0 then
	    {PersonalNewRecord ArmeRecord mine ArmeRecord.mine+1}
	 elseif R==1 then
	    {PersonalNewRecord ArmeRecord missile ArmeRecord.missile+1}
	 elseif R==2 then
	    {PersonalNewRecord ArmeRecord sonar ArmeRecord.sonar+1}
	 else
	    {PersonalNewRecord ArmeRecord drone ArmeRecord.drone+1}
	 end
      end

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
      S = ({OS.rand} mod Max) + Min
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


   % Determine la position sur laquelle se trouve un adversaire et ou on peut tirer. Si il n'y en a pas on retourne nil
   fun{PositionPlayerToTarget MinD MaxD AdvStatus Position}
      Pt
   in
      for I in 1..Input.nbPlayer break:U do
	 case AdvStatus.I
	 of posType(tracked PAdv) then
	    if {Dist PAdv Position} >= MinD andthen {Dist PAdv Position} =< MaxD then
	       Pt=PAdv
	       {U}
	    else
	       skip
	    end
	 else
	    skip
	 end
	 if I==Input.nbPlayer then
	    Pt=nil
	 end
      end
      Pt
   end

   fun{FireDrone AdvStatus}
      Drone
   in
      for I in 1..Input.nbPlayer break:U do
	 case AdvStatus.I
	 of posType(double pt(x:X1 y:Y1) pt(x:X2 y:Y2)) then
	    if X1 \= X2 then
	       Drone=drone(row X1)
	    elseif Y1 \=Y2 then
	       Drone=drone(column Y1)
	    else
	       Drone=nil
	    end
	    {U}
	 else
	    skip
	 end
	 if I==Input.nbPlayer then
	    Drone=nil
	    {U}
	 end
      end
      Drone
   end
   
   fun{Dist Pt1 Pt2}
      {Abs Pt1.x-Pt2.x} + {Abs Pt1.y-Pt2.y}
   end
   
   % On choisit l'arme a tirer en fonction des informations sur les adversaires et des armes disponibles
   fun{ChooseFire Arme Position AdvSt}
      Fire
   in

      if {PlayerStatus AdvSt tracked} == false andthen {PlayerStatus AdvSt double} == false then

	 if Arme.sonar >= Input.sonar then
	    Fire=sonar
	 elseif Arme.mine >= Input.mine then
	    Fire=mine({FindPlaceForFire Input.minDistanceMine Input.maxDistanceMine Position})
	 else
	    Fire=nil
	 end
      elseif {PlayerStatus AdvSt tracked} == false andthen {PlayerStatus AdvSt double} then
	 if Arme.drone >= Input.drone then
	    Fire={FireDrone AdvSt}
	 elseif Arme.sonar >= Input.sonar then
	    Fire=sonar
	 elseif Arme.mine >= Input.mine then
	    Fire=mine({FindPlaceForFire Input.minDistanceMine Input.maxDistanceMine Position})
	 else
	    Fire=nil
	 end
      elseif {PlayerStatus AdvSt tracked} then
	 Pt
      in
	 Pt = {PositionPlayerToTarget {Max 2 Input.minDistanceMissile} Input.maxDistanceMissile AdvSt Position}
	 if Arme.missile >= Input.missile andthen Pt \= nil then % On regarde si un joueur est atteignable
	    Fire=missile(Pt)
	 elseif Arme.mine >= Input.mine then
	    Fire=mine({FindPlaceForFire Input.minDistanceMine Input.maxDistanceMine Position})
	 elseif Arme.sonar >= Input.sonar then
	    Fire=sonar
	 else
	    Fire=nil
	 end
      else
	 if Arme.sonar >= Input.sonar then
	    Fire=sonar
	 elseif Arme.mine >= Input.mine then
	    Fire=mine({FindPlaceForFire Input.minDistanceMine Input.maxDistanceMine Position})
	 else
	    Fire=nil
	 end
      end
      Fire
   end

   fun{ExplodeMine ListMine Pos AdvSt}
      case ListMine
      of H|T then
	 Adv
      in
	 Adv = {PositionPlayerToTarget 0 1 AdvSt H}
	 if Adv \= nil andthen {Dist Pos H} > 1 then
	    {Browse touchAdvMine}
	    H
	 else
	    if {Dist Pos H}>1 andthen {OS.rand} mod 30000 == 0 then
	       H
	    else
	       {ExplodeMine T Pos AdvSt}
	    end
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
   
  
   proc{TreatStream Stream Id Arme Surface ListPosition ListMine AdvPosition MyLife} % has as many parameters as you want
      NewArme
   in
      case Stream
      of nil|T then skip
	 % On chosit une position aléatoire correcte
      [] initPosition(ID Pos)|T then Pos={RandPosWater} ID=Id
	 {TreatStream T Id Arme Surface Pos|ListPosition ListMine AdvPosition MyLife}

	 % On met la variable Surface a false
      [] dive|T then
	 case ListPosition of H|U then
	    {TreatStream T Id Arme false H|nil ListMine AdvPosition MyLife}
	 else
	    {TreatStream T Id Arme false ListPosition ListMine AdvPosition MyLife}
	 end

	 % On donne à Ans la valeur de la variable Surface
      [] isSurface(ID Ans)|T then
	 if MyLife > 0 then
	    Ans=Surface ID=Id
	 else
	    Ans=nil ID=nil
	 end
	 {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife}

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
	    {TreatStream T Id Arme (Dir==surface) Pos|ListPosition ListMine AdvPosition MyLife}
	 else
	    Dir = nil
	    Pos = nil
	    ID = nil
	    {TreatStream T Id Arme (Dir==surface) ListPosition ListMine AdvPosition MyLife}
	 end
	 
	 % On choisit une arme à charger et on indique si une nouvelle arme a été créée
      [] chargeItem(ID KindItem)|T then
	 NewArme={ChargeItem Arme AdvPosition} % Nouveau record arme avec une arme ayant recu une charge supplémentaire
	 KindItem = {NewItem Arme NewArme} % KindItem n'est pas nil si une nouvelle arme a été créée
	 ID=Id
	 {TreatStream T Id NewArme Surface ListPosition ListMine AdvPosition MyLife}

	 % On choisit l'arme a utliser
      [] fireItem(ID KindFire)|T then
	 KindFire={ChooseFire Arme ListPosition.1 AdvPosition} % KindFire n'est pas nil si une arme peut-être tirée
	 % case KindFire of missile(pt(x:X y:Y)) then
	 %    {Browse AdvPosition}
	 %    {Browse missileExplode|KindFire}
	 % else
	 %    skip
	 % end
	 
	 NewArme={FireArme Arme KindFire} % Nouveau record arme avec une arme utilisée et donc ayant perdu des charges
	 ID=Id
	 case KindFire of mine(P) then
	    {TreatStream T Id NewArme Surface ListPosition P|ListMine AdvPosition MyLife}
	 else
	    {TreatStream T Id NewArme Surface ListPosition ListMine AdvPosition MyLife}
	 end

	 % On décide de faire exploser une mine si une mine est près d'un adversaire
      [] fireMine(ID Mine)|T then
	 Mine={ExplodeMine ListMine ListPosition.1 AdvPosition}
	 ID=Id
	 if Mine == nil then
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife}
	 else
	    {TreatStream T Id Arme Surface ListPosition {DeleteMine ListMine Mine} AdvPosition MyLife}
	 end
	 
      [] sayMove(ID Dir)|T then
	 %{Browse 'The player'(ID 'move in derection'(Dir))}
	 {TreatStream T Id Arme Surface ListPosition ListMine {MoveAdv AdvPosition ID Dir} MyLife}
	 
      [] saySurface(ID)|T then
	 %{Browse 'The next player is at the surface'(ID)}
	 {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife}
	 
      [] sayCharge(ID KindItem)|T then
	 {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife}
	 
      [] sayMinePlaced(ID)|T then
	 %{Browse 'The next player placed a mine'(ID)}
	 {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife}

	 % On determine si on est touché ou non par le missile
      [] sayMissileExplode(ID Pos Message)|T then
	 Distance
      in
	  %check if we are touch by the explosion
	 case Pos of pt(x:X y:Y) then
	    Distance = ({Abs X-ListPosition.1.x} + {Abs Y-ListPosition.1.y})
	    if Distance>=2 then
	       Message= nil
	    elseif Distance==1 then
	       Message = 1
	    else
	       Message = 2
	    end
	 end
	 if Message \= nil then
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition {Max MyLife-Message 0}}
	 else
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife}
	 end

	 
      [] sayMineExplode(ID Pos Message)|T then
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
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition {Max MyLife-Message 0}}
	 else
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife}
	 end
	 
      [] sayPassingDrone(Drone ID Ans)|T then
	  %check if we are in the row or column of the drone
	 case Drone of drone(row X) then
	    Ans=(X == ListPosition.1.x)
	 [] drone(column Y) then
	    Ans=(Y == ListPosition.1.y)
	 end
	 ID = Id
	 {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife}
	 
      [] sayAnswerDrone(Drone ID Ans)|T then
	 {TreatStream T Id Arme Surface ListPosition ListMine {NewAdvPosDrone AdvPosition ID Drone Ans} MyLife}
	 
      [] sayPassingSonar(ID Ans)|T then
	 X Y
      in
	  %random choice of wrong coordonate
	 if({OS.rand} mod 2) == 0 then
	    X=({OS.rand} mod Input.nRow)+1
	    Y = ListPosition.1.y
	 else
	    Y=({OS.rand} mod Input.nColumn)+1
	    X= ListPosition.1.x
	 end
	 Ans = pt(x:X y:Y)
	 ID = Id
	 {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife}
	 
      [] sayAnswerSonar(ID Ans)|T then
	 %{Browse 'The sonar detect the player'(ID 'at position'(Ans))}
	 {TreatStream T Id Arme Surface ListPosition ListMine {NewAdvPosSonar AdvPosition ID Ans} MyLife}
	 
      [] sayDeath(ID)|T then
	 %{Browse 'The next player is dead'(ID)}
	 {TreatStream T Id Arme Surface ListPosition ListMine {PersonalNewRecord AdvPosition ID.id posType(dead)} MyLife}
	 
      [] sayDamageTaken(ID Damage LifeLeft)|T then
	 %{Browse 'Damage on player'(ID' number'(Damage) 'Lifeleft'(LifeLeft))}
	 {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife}
      else
	 {Browse unknown_instruction}
	 skip
      end
   end
end

