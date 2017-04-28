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
   ChooseDir
   CheckPosition
   CheckList
   DeleteMine
   BuildList
   ExplodeMine
   NewAdvPosSonar
   MoveAdv
   PlayerNearMine
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
   % Liste ListMine : ensemble des mines placées par le joueur
   % Record AdvPosition : record contenant des informations sur la position potentielle de l'adversaire
   %
   % ===== LE CHAMP AdvPostion est TRES IMPORTANT. IL EST DETAILLE DANS LE RAPPORT =====
   %
   % Naturel MyLife : Vie actuelle du joueur
   % Point LastMineExplosion : Position de la derniere mine qu'on a fait exploser
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
	 {TreatStream Stream id(id:ID color:Color name:ID) arme(missile:0 mine:0 sonar:0 drone:0) true nil nil AdvPosition Input.maxDamage nil}
      end
      Port
   end

   % Construit une liste allant de A à Max 
   fun{BuildList A Max}
      if A == Max then Max|nil
      else
	 A|{BuildList A+1 Max}
      end
   end

   % AdvStatus : record contenant le statut des adversaires (tracked, double,...)
   % Request : on demande si un joueur du record a un statut particulier (tracked, xRight,...)
   % Repond true si c'est le cas et false sinon
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
  
   % On modifie la position pontentielle de l'adversaire dans le record R
   fun{MoveAdv R Id Dir}
      if Id \= null then
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
      else
	 R
      end
   end
   
   % Un drone nous fournit des informations sur un joueur.
   % On tente d'en déduire des informations sur la position du joueur
   fun{NewAdvPosDrone R Id Drone Ans}
      case R.(Id.id)
      of nil then % Si pas encore d'information sur le joueur, on peut juste déduire une de ses coordonnée (x ou y)
	 if Ans then
	    case Drone
	    of drone(row X) then {PersonalNewRecord R Id.id posType(xRight pt(x:X y:1))}
	    [] drone(column Y) then {PersonalNewRecord R Id.id posType(yRight pt(x:1 y:Y))}
	    end
	 else
	    R
	 end
      [] posType(xRight pt(x:X y:_)) then % Si on connait déjà x et que le drone nous donne y, on connait la position exacte du joueur => Le joueur devient 'tracked'
	 if Ans then
	    case Drone
	    of drone(row _) then R
	    [] drone(column Y2) then {PersonalNewRecord R Id.id posType(tracked pt(x:X y:Y2))}
	    end
	 else
	    R
	 end
      [] posType(yRight pt(x:_ y:Y)) then % Si on connait déjà x et que le drone nous donne y, on connait la position exacte du joueur => Le joueur devient 'tracked'
	 if Ans then
	    case Drone
	    of drone(row X2) then {PersonalNewRecord R Id.id posType(tracked pt(x:X2 y:Y))}
	    [] drone(column _) then R
	    end
	 else
	    R
	 end
      [] posType(tracked pt(x:_ y:_)) then R % Si on connait déjà la position il n'y a plus de déduction a faire
      [] posType(double pt(x:X1 y:Y1) pt(x:X2 y:Y2)) then % Si il y deux positions possibles, dans certains cas on peut déduire quelle position est la bonne
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
      [] posType(firstGuess pt(x:X y:Y)) then % Si on avait reçu des informations d'un sonar, on peut déduire une des coordonnées
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
      [] posType(xRight pt(x:X y:_)) then
	 if X \= P.x then % On connaissait X et maintenant on connait aussi Y et donc la position exacte
	    {PersonalNewRecord R Id.id posType(tracked pt(x:X y:P.y))}
	 else % On ne peut rien déduire 
	    R
	 end
      [] posType(yRight pt(x:_ y:Y)) then % On connaissait Y et maintenant on connait aussi X et donc la position exacte
	 if Y \= P.y then
	    {PersonalNewRecord R Id.id posType(tracked pt(x:P.x y:Y))}
	 else % On ne peut rien déduire 
	    R
	 end
      [] posType(tracked pt(x:_ y:_)) then R 
      [] posType(double pt(x:_ y:_) pt(x:_ y:_)) then % Pas de déduction possible
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

   fun{ChooseDir ListPos}
      Dir
   in
      if {CheckPosition ListPos.1.x ListPos.1.y+1} andthen {CheckList ListPos pt(x:ListPos.1.x y:(ListPos.1.y+1))}==false then % On essaie d'aller vers la droite en priorité
	 Dir = east
      elseif {CheckPosition ListPos.1.x ListPos.1.y-1} andthen {CheckList ListPos pt(x:ListPos.1.x y:(ListPos.1.y-1))}==false then % Sinon on essaie d'aller vers la gauche
	 Dir = west
      else % Si ce n'est pas possible, on essaie de monter ou de descendre. Si on trouve se dans le bas de la carte on essaie d'abord de monter et puis de descendre et inversement
	 if ListPos.1.x =< (Input.nRow div 2) then
	    if {CheckPosition ListPos.1.x+1 ListPos.1.y} andthen {CheckList ListPos pt(x:(ListPos.1.x+1) y:ListPos.1.y)}==false then
	       Dir=south
	    elseif {CheckPosition ListPos.1.x-1 ListPos.1.y} andthen {CheckList ListPos pt(x:(ListPos.1.x-1) y:ListPos.1.y)}==false then
	       Dir=north
	    else
	       Dir=surface
	    end
	 else
	    if {CheckPosition ListPos.1.x-1 ListPos.1.y} andthen {CheckList ListPos pt(x:(ListPos.1.x-1) y:ListPos.1.y)}==false then
	       Dir=north
	    elseif {CheckPosition ListPos.1.x+1 ListPos.1.y} andthen {CheckList ListPos pt(x:(ListPos.1.x+1) y:ListPos.1.y)}==false then
	       Dir=south
	    else
	       Dir=surface
	    end
	 end	 
      end
   end


    % On charge une arme en fonction du statut des adversaires
   fun{ChargeItem ArmeRecord AdvStatus}
      R
   in
      % On charge deux sonar pour obtenir une première information sur les joueurs
      if {PlayerStatus AdvStatus nil} orelse {PlayerStatus AdvStatus firstGuess} then 
	 {PersonalNewRecord ArmeRecord sonar ArmeRecord.sonar+1}

	 % Si on a seulement une coordonnée de correcte pour chaque joueur, on charge un sonar 1 fois sur 4, un missile ou une mine 1 fois sur 4 et une mine une fois sur 2
      elseif ({PlayerStatus AdvStatus tracked} == false andthen {PlayerStatus AdvStatus double} == false) andthen ({PlayerStatus AdvStatus xRight} orelse {PlayerStatus AdvStatus yRight}) then
	 R = {OS.rand} mod 4
	 if R < 1 then
	    {PersonalNewRecord ArmeRecord sonar ArmeRecord.sonar+1}
	 elseif R == 1 then
	    {PersonalNewRecord ArmeRecord missile ArmeRecord.missile+1}
	 else
	    {PersonalNewRecord ArmeRecord mine ArmeRecord.mine+1}
	 end

	 % Si on a au moins un joueur avec deux positions possibles et pas de joueur 'tracked', on charge un drone la moitié du temps et un missile ou une mine l'autre moitié
      elseif ({PlayerStatus AdvStatus tracked} == false andthen {PlayerStatus AdvStatus double}) then
	 R = {OS.rand} mod 4
	 if R =< 1 then
	    {PersonalNewRecord ArmeRecord drone ArmeRecord.drone+1}
	 elseif R == 2 then
	    {PersonalNewRecord ArmeRecord missile ArmeRecord.missile+1}
	 else
	    {PersonalNewRecord ArmeRecord mine ArmeRecord.mine+1}
	 end

	 % Si au moins un joueur est 'tracked' on charge un missile 3 sur 8 fois, une mine 3 sur 8 fois et un sonar 2 sur 8 fois
      elseif ({PlayerStatus AdvStatus tracked} andthen ({PlayerStatus AdvStatus double} orelse {PlayerStatus AdvStatus xRight} orelse {PlayerStatus AdvStatus yRight})) then
	 R = {OS.rand} mod 8
	 if R =< 2 then
	    {PersonalNewRecord ArmeRecord mine ArmeRecord.mine+1}
	 elseif R >= 5 then
	    {PersonalNewRecord ArmeRecord missile ArmeRecord.missile+1}
	 else
	    {PersonalNewRecord ArmeRecord sonar ArmeRecord.sonar+1}
	 end
	 % Si tous les joueurs sont 'tracked' on charge que des mines et des missiles
      elseif ({PlayerStatus AdvStatus tracked} andthen {PlayerStatus AdvStatus double} == false andthen ({PlayerStatus AdvStatus xRight} == false andthen {PlayerStatus AdvStatus yRight})) == false then
	 R = {OS.rand} mod 3
	 if R =< 1 then
	    {PersonalNewRecord ArmeRecord missile ArmeRecord.missile+1}
	 else
	    {PersonalNewRecord ArmeRecord mine ArmeRecord.mine+1}
	 end
	 % Si aucun de ces cas, on charge une des quatre armes de facon aléatoire
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
	 Item=null
      end
      Item
   end

   % Determine aléatoirement une case ou l'on peut tirer/placer une arme
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
      {AdjoinAt R Feat Val}
   end

   % Retourne le record arme modifié après un tir
   fun{FireArme Arme Kind}
      case Kind of null then Arme
      [] sonar then {PersonalNewRecord Arme sonar Arme.sonar-Input.sonar}
      [] missile(_) then {PersonalNewRecord Arme missile Arme.missile-Input.missile}
      [] drone(row _) then {PersonalNewRecord Arme drone Arme.drone-Input.drone}
      [] drone(column _) then {PersonalNewRecord Arme drone Arme.drone-Input.drone}
      [] mine(_) then {PersonalNewRecord Arme mine Arme.mine-Input.mine}
      else Arme
      end	 
   end


   % Determine une position sur laquelle se trouve un adversaire et ou on peut tirer. Si il n'y en a pas on retourne nil
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

   % Tire un drone si un joueur à le staut "double" de façon à déduire sa position
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
	       Drone=null
	    end
	    {U}
	 else
	    skip
	 end
	 if I==Input.nbPlayer then
	    Drone=null
	    {U}
	 end
      end
      Drone
   end

   % Détermine la distance entre deux points
   fun{Dist Pt1 Pt2}
      {Abs Pt1.x-Pt2.x} + {Abs Pt1.y-Pt2.y}
   end
   
   % On choisit l'arme a tirer en fonction des informations sur les adversaires et des armes disponibles
   fun{ChooseFire Arme Position AdvSt}
      Fire
   in

      % Si aucun joueur n'est 'tracked' ou 'double' on tire en priorité un sonar et sinon une mine
      if {PlayerStatus AdvSt tracked} == false andthen {PlayerStatus AdvSt double} == false then
	 if Arme.sonar >= Input.sonar then
	    Fire=sonar
	 elseif Arme.mine >= Input.mine then
	    Fire=mine({FindPlaceForFire Input.minDistanceMine Input.maxDistanceMine Position})
	 else
	    Fire=null
	 end

	 % Si un joueur est 'double' mais qu'il n'y a pas de tracked, on tire en priorité un drone puis un sonar puis une mine
      elseif {PlayerStatus AdvSt tracked} == false andthen {PlayerStatus AdvSt double} then
	 if Arme.drone >= Input.drone then
	    Fire={FireDrone AdvSt}
	 elseif Arme.sonar >= Input.sonar then
	    Fire=sonar
	 elseif Arme.mine >= Input.mine then
	    Fire=mine({FindPlaceForFire Input.minDistanceMine Input.maxDistanceMine Position})
	 else
	    Fire=null
	 end

	 % Si un joueur est tracked, on regarde si on a un missile et si le joueur est atteignable. Si c'est le cas on tire le missile sinon on place une mine et finalement on utilise un sonar
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
	    Fire=null
	 end
      else
	 % Si on est dans aucun de ces cas, on lance en priorité un sonar et sinon on place une mine
	 if Arme.sonar >= Input.sonar then
	    Fire=sonar
	 elseif Arme.mine >= Input.mine then
	    Fire=mine({FindPlaceForFire Input.minDistanceMine Input.maxDistanceMine Position})
	 else
	    Fire=null
	 end
      end
      Fire
   end

   % On déterminé si il y a potentiellement un joueur près d'une de nos mines
   fun{PlayerNearMine AdvSt Mine}
      Ans
   in
      for I in 1..Input.nbPlayer break:U do
	 case AdvSt.I
	 of posType(xRight pt(x:Xr y:_)) then
	    if Xr==Mine.x then
	       Ans=I
	       {U}
	    end
	 [] posType(yRight pt(x:_ y:Yr)) then
	    if Yr==Mine.y then
	       Ans=I
	       {U}
	    end
	 else
	    skip
	 end
	 if I == Input.nbPlayer then
	    Ans=0
	    {U}
	 end
      end
      Ans
   end



   % Décide de faire exploser ou non une de nos mines
   fun{ExplodeMine ListMine Pos AdvSt}
      case ListMine
      of H|T then
	 Adv
      in
	 Adv = {PositionPlayerToTarget 0 1 AdvSt H}
	 if Adv \= nil andthen {Dist Pos H} > 1 then % Si un adversaire est assez prêt d'une de nos mines on la fait exploser
	    explodeMine(minePlace:H playerId:0) 
	 else 
	    PId
	 in
	    PId={PlayerNearMine AdvSt H} % Sinon si un joueur est 'potentiellement' près d'une de nos mine, on peut décider de la faire exploser
	    % Si le joueur est touché on pourra en tirer des informations sur sa position
	    if {Dist Pos H}>1 andthen {OS.rand} mod 1 == 0 andthen PId > 0 then
	       explodeMine(minePlace:H playerId:PId)
	    elseif {Dist Pos H}>1 andthen {OS.rand} mod 10025 == 0 then
	       explodeMine(minePlace:H playerId:0)
	    else
	       {ExplodeMine T Pos AdvSt}
	    end
	 end
      [] nil then nil
      end
   end

   % On supprime une mine de la liste de mine
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
   
  
   proc{TreatStream Stream Id Arme Surface ListPosition ListMine AdvPosition MyLife LastMineExplosion} % has as many parameters as you want
      NewArme
   in 
      case Stream
      of nil|_ then skip
	 % On chosit une position aléatoire correcte
      [] initPosition(ID Pos)|T then Pos={RandPosWater} ID=Id
	 {TreatStream T Id Arme Surface Pos|ListPosition ListMine AdvPosition MyLife nil}

	 % On met la variable Surface a false
      [] dive|T then
	 case ListPosition of H|_ then
	    {TreatStream T Id Arme false H|nil ListMine AdvPosition MyLife nil}
	 else
	    {TreatStream T Id Arme false ListPosition ListMine AdvPosition MyLife nil}
	 end

	 % On donne à Ans la valeur de la variable Surface
      [] isSurface(ID Ans)|T then
	 if MyLife > 0 then
	    Ans=Surface ID=Id
	 else
	    Ans=false ID=null
	 end
	 {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife nil}

	 % On fait appel à la fonction ChooseRandDirection et on modifie notre position en fonction du resultat
      [] move(ID Pos Dir)|T then
	 if MyLife > 0 then
	    Dir = {ChooseDir ListPosition}
	    if Dir == west then Pos = pt(x:ListPosition.1.x y:(ListPosition.1.y-1))
	    elseif Dir == east then Pos = pt(x:ListPosition.1.x y:(ListPosition.1.y+1)) 
	    elseif Dir == south then Pos = pt(x:(ListPosition.1.x+1) y:ListPosition.1.y)
	    elseif Dir == north then Pos = pt(x:(ListPosition.1.x-1) y:ListPosition.1.y)
	    else Pos = ListPosition.1
	    end
	    ID = Id
	    {TreatStream T Id Arme (Dir==surface) Pos|ListPosition ListMine AdvPosition MyLife nil}
	 else
	    Dir = null
	    Pos = null
	    ID = null
	    {TreatStream T Id Arme (Dir==surface) ListPosition ListMine AdvPosition MyLife nil}
	 end
	 
	 % On choisit une arme à charger et on indique si une nouvelle arme a été créée
      [] chargeItem(ID KindItem)|T then
	 if MyLife > 0 then
	    NewArme={ChargeItem Arme AdvPosition} % Nouveau record arme avec une arme ayant recu une charge supplémentaire
	    KindItem = {NewItem Arme NewArme} % KindItem n'est pas nil si une nouvelle arme a été créée
	    ID=Id
	    {TreatStream T Id NewArme Surface ListPosition ListMine AdvPosition MyLife nil}
	 else
	    KindItem=null
	    ID=null
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife nil}
	 end
	 
	 % On choisit l'arme a utliser
      [] fireItem(ID KindFire)|T then
	 if MyLife > 0 then
	    KindFire={ChooseFire Arme ListPosition.1 AdvPosition} % KindFire n'est pas nil si une arme peut-être tirée
	    NewArme={FireArme Arme KindFire} % Nouveau record arme avec une arme utilisée et donc ayant perdu des charges
	    ID=Id
	    case KindFire of mine(P) then
	       {TreatStream T Id NewArme Surface ListPosition P|ListMine AdvPosition MyLife nil}
	    else
	       {TreatStream T Id NewArme Surface ListPosition ListMine AdvPosition MyLife nil}
	    end
	 else
	    KindFire = null
	    ID=null
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife nil}
	 end

	 % On décide de faire exploser une mine si une mine est près d'un adversaire
      [] fireMine(ID Mine)|T then
	 if MyLife> 0 then
	    MineRec
	 in
	    MineRec={ExplodeMine ListMine ListPosition.1 AdvPosition} % Determine la mine a faire exploser
	    if MineRec \=nil then 
	       Mine=MineRec.minePlace % Mine a faire exploser
	    else
	       Mine=null
	    end
	 
	    ID=Id
	    if Mine == null then
	       {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife nil}
	    else
	       {TreatStream T Id Arme Surface ListPosition {DeleteMine ListMine Mine} AdvPosition MyLife MineRec} % On enregistre l'explosion (MineRec) pour pouvoir déduire la position d'un adversaire si on recoit un TakeDamage 
	    end
	 else
	    Mine = null
	    ID = null
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife nil}
	 end
      [] sayMove(ID Dir)|T then
	 if MyLife > 0 then
	    if ID \= null then
	       if ID.id == Id.id then
		  {TreatStream T Id Arme Surface ListPosition ListMine {MoveAdv AdvPosition ID Dir} MyLife nil}
	       else
		  {TreatStream T Id Arme Surface ListPosition ListMine {MoveAdv AdvPosition ID Dir} MyLife LastMineExplosion}
	       end
	    else 
	       {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife LastMineExplosion}
	    end
	 else % On modifie la position potentielle de l'adversaire
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife nil}
	 end
	 
      [] saySurface(ID)|T then
	 if ID.id == Id.id then
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife nil}
	 else
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife LastMineExplosion}
	 end

      [] sayCharge(ID _)|T then
	 if ID.id == Id.id then
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife nil}
	 else
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife LastMineExplosion}
	 end
	 
      [] sayMinePlaced(ID)|T then
	 if ID.id == Id.id then 
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife nil}
	 else
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife LastMineExplosion}
	 end

	 % On determine si on est touché ou non par le missile
      [] sayMissileExplode(_ Pos Message)|T then
	 if MyLife > 0 then
	    Distance
	 in
	  %check if we are touch by the explosion
	    case Pos of pt(x:X y:Y) then
	       Distance = ({Abs X-ListPosition.1.x} + {Abs Y-ListPosition.1.y})
	       if Distance>=2 then
		  Message=null
	       elseif Distance==1 then
		  if {Max MyLife-1 0} > 0 then
		     Message = sayDamageTaken(Id 1 MyLife-1)
		  else
		     Message = sayDeath(Id)
		  end
		  
	       else
		  if {Max MyLife-2 0} > 0 then
		     Message = sayDamageTaken(Id 2 MyLife-2)
		  else
		     Message = sayDeath(Id)
		  end
	       end
	    end
	    case Message of sayDamageTaken(_ _ LL) then
	       {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition LL nil}
	    [] sayDeath(_) then
	       {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition 0 nil}
	    else
	       {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife nil}
	    end
	 else
	    Message = null
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife nil}
	 end
	 
      [] sayMineExplode(ID Pos Message)|T then
	 if MyLife > 0 then
	    Distance
	 in
	  %check if we are touch by the explosion
	    case Pos of pt(x:X y:Y) then
	       Distance = ({Abs X-ListPosition.1.x} + {Abs Y-ListPosition.1.y})
	       if(Distance>=2) then
		  Message = null
	       elseif(Distance==1) then
		  if {Max MyLife-1 0} > 0 then
		     Message = sayDamageTaken(Id 1 MyLife-1)
		  else
		     Message = sayDeath(Id)
		  end
	       else
		  if {Max MyLife-2 0} > 0 then
		     Message = sayDamageTaken(Id 2 MyLife-2)
		  else
		     Message = sayDeath(Id)
		  end
	       end
	    end

	    if LastMineExplosion \= nil then
	       if Pos == LastMineExplosion.minePlace then % Si la mine qui a explosée était la notre on laisse LastMineExplosion sinon on met cette variable à nil
		  case Message of sayDamageTaken(_ _ LL) then
		     {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition LL LastMineExplosion}
		  [] sayDeath(_) then
		     {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition 0 LastMineExplosion}
		  else
		     {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife LastMineExplosion}
		  end
		  
	       else

		  case Message of sayDamageTaken(_ _ LL) then
		     {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition LL nil}
		  [] sayDeath(_) then
		     {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition 0 nil}
		  else
		     {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife nil}
		  end
	       end	    
	    else
	       case Message of sayDamageTaken(_ _ LL) then
		  {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition LL nil}
	       [] sayDeath(_) then
		  {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition 0 nil}
	       else
		  {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife nil}
	       end
	    end
	 else
	    Message=null
	    ID=null
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife nil}
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
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife LastMineExplosion}
	 else
	    Ans = false
	    ID = null
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife LastMineExplosion}
	 end
	 
	 
      [] sayAnswerDrone(Drone ID Ans)|T then
	 if ID \=null then
	    {TreatStream T Id Arme Surface ListPosition ListMine {NewAdvPosDrone AdvPosition ID Drone Ans} MyLife LastMineExplosion} % On traite l'information reçue et on met à joueur la position potentielle de l'adversaire
	 else
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife LastMineExplosion}
	 end
	 
      [] sayPassingSonar(ID Ans)|T then
	 if MyLife > 0 then
	    X Y
	 in
	  %random choice of wrong coordonate
	    if({OS.rand} mod 1) == 0 then % Choix non aléatoire en réalité! on donne toujours x pour que l'adversaire déduise moins facilement notre position
	       X=({OS.rand} mod Input.nRow)+1
	       Y = ListPosition.1.y
	    else
	       Y=({OS.rand} mod Input.nColumn)+1
	       X= ListPosition.1.x
	    end
	    Ans = pt(x:X y:Y)
	    ID = Id
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife LastMineExplosion}
	 else
	    Ans = false
	    ID = null
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife LastMineExplosion}
	 end
	 
      [] sayAnswerSonar(ID Ans)|T then
	 if ID \= null then
	    {TreatStream T Id Arme Surface ListPosition ListMine {NewAdvPosSonar AdvPosition ID Ans} MyLife LastMineExplosion}% On traite l'information reçue et on met à joueur la position potentielle de l'adversaire
	 else
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife LastMineExplosion}
	 end
	 
      [] sayDeath(ID)|T then
	 {TreatStream T Id Arme Surface ListPosition ListMine {PersonalNewRecord AdvPosition ID.id posType(dead)} MyLife LastMineExplosion} % On met le statut du joueur à 'death'
	 
      [] sayDamageTaken(ID Damage LifeLeft)|T then
	 if MyLife > 0 andthen ID\=null andthen ID\=nil then
	    
	    if LastMineExplosion \=  nil then % Si un adversaire a perdu de la vie et que nous avions enregistrée une mine dans LastMineExplosion, c'est que c'est notre mine qui a provoqué ces dégats. On peut donc en déduire des informations sur la position de l'adversaire
	       NewAdvPos
	    in
	       if ID.id == LastMineExplosion.playerId andthen LifeLeft > 0 then
		  case AdvPosition.(LastMineExplosion.playerId)
		  of posType(xRight pt(x:Xr y:_)) then % Si on connaissait le x de l'adversaire, on peut en déduire y si l'adversaire a subit 2 dégats et une double position si il a subit un seul dégat
		     if LastMineExplosion.minePlace.x == Xr andthen Damage==2 then
			NewAdvPos={PersonalNewRecord AdvPosition ID.id posType(tracked pt(x:Xr y:LastMineExplosion.minePlace.y))}
		     elseif LastMineExplosion.minePlace.x == Xr andthen Damage==1 then
			NewAdvPos={PersonalNewRecord AdvPosition ID.id posType(double pt(x:Xr y:LastMineExplosion.minePlace.y-1) pt(x:Xr y:LastMineExplosion.minePlace.y+1))}
		     else
			NewAdvPos=AdvPosition
		     end
		  [] posType(yRight pt(x:_ y:Yr)) then % Si on connaissait le y de l'adversaire, on peut en déduire x si l'adversaire a subit 2 dégats et une double position si il a subit un seul dégat
		     if LastMineExplosion.minePlace.y == Yr andthen Damage==2 then
			NewAdvPos={PersonalNewRecord AdvPosition ID.id posType(tracked pt(x:LastMineExplosion.minePlace.x y:Yr))}
		     elseif LastMineExplosion.minePlace.y == Yr andthen Damage==1 then
			NewAdvPos={PersonalNewRecord AdvPosition ID.id posType(double pt(x:LastMineExplosion.minePlace.x-1 y:Yr) pt(x:LastMineExplosion.minePlace.x+1 y:Yr))}
		     else
			NewAdvPos=AdvPosition
		     end
		  else
		     NewAdvPos=AdvPosition
		  end
	       else
		  NewAdvPos=AdvPosition
	       end
	       {TreatStream T Id Arme Surface ListPosition ListMine NewAdvPos MyLife nil}
	    else
	       {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife LastMineExplosion}
	    end
	 else
	    {TreatStream T Id Arme Surface ListPosition ListMine AdvPosition MyLife nil}
	 end
	 
      else
	 {Browse unknown_instruction}
	 skip
      end
   end
end