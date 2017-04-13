functor
import
   GUI
   Input
   System
   PlayerManager
   Browser
define
   Browse=Browser.browse
   Show=System.show
   PortGUI
   PortPlayers
   BuildLifeRecord
   PersonalNewRecord
   SetPlayersPort
   TurnByTurnGame
   CheckEnd
   BuildList
   BuildTurnAtSurfaceCounter
   Sender
in

   % Retourne un Record contenant l'ensemble des ports associés aux joueurs
   
   fun{SetPlayersPort KindP ColorP N}
      fun{FillRecord R KindP ColorP Id}
	 case KindP|ColorP
	 of (K|Kr)|(P|Pr) then R.Id={PlayerManager.playerGenerator K P Id}
	    {FillRecord R Kr Pr Id+1}
	 [] nil|nil then R
	 end
      end
      
   in
      {FillRecord {MakeRecord portPlayer {BuildList 1 N}} KindP ColorP 1}
   end

   fun{BuildList A Max}
      if A == Max then Max|nil
      else
	 A|{BuildList A+1 Max}
      end
   end

   fun{BuildLifeRecord NbPlayer}
      Life
   in
      if NbPlayer == 0 then nil
      else
	 {MakeRecord life {BuildList 1 NbPlayer} Life}
	 for X in 1..NbPlayer do
	    Life.X = Input.maxDamage
	 end
	 Life
      end
   end

   fun{BuildTurnAtSurfaceCounter NbPlayer}
      Turn
   in
      if NbPlayer == 0 then nil
      else
	 {MakeRecord life {BuildList 1 NbPlayer} Turn}
	 for X in 1..NbPlayer do
	    Turn.X = Input.turnSurface
	 end
	 Turn
      end
   end

   %Send Message to all player
   proc{Sender Msg}
      for X in 1..Input.nbPlayer do
	 {Send PortPlayers.X Msg}
      end
   end
   

   
   fun{CheckEnd Tab}
      fun{CheckEndA T Pos Acc}
	 A
      in
	 if Pos> Input.nbPlayer then
	    Acc == (Input.nbPlayer-1)
	 else
	    A = T.Pos
	    if A == 0 then {CheckEndA T Pos+1 Acc+1}
	    else {CheckEndA T Pos+1 Acc}
	    end
	 end
      end
   in
      {CheckEndA Tab 1 0}
   end

   fun{PersonalNewRecord R Feat Val}
      PNRSub NewR
   in
      PNRSub = {Record.subtract R Feat}
      NewR = {AdjoinAt R Feat Val}
   end
   
   % Jeu tour par tour. S'arrete quand il ne reste plus qu'un joueur en vie 
   proc{TurnByTurnGame ActualP MaxP Life TurnAtSurface}
      NewLife NextLife
   in
      
      
      if Life.ActualP == 0 then {TurnByTurnGame ((ActualP mod MaxP)+1) MaxP Life TurnAtSurface} 
      elseif {CheckEnd Life} then % End of the game
	 {Browse 'End Of The Game'}
      else
	 
	 % IMPLEMENTER UN TOUR 
	 % Check if the submarine can play |1|
	 local Id Ans in
	    {Send PortPlayers.ActualP isSurface(Id Ans)}
	    if Ans then
	       {Browse 'tuple'(ActualP Ans TurnAtSurface.ActualP)}
	       {Delay 1000}
	       if TurnAtSurface.ActualP == Input.turnSurface then
		  %say dive |2|
		  {Send PortPlayers.ActualP dive}
		  {Browse TurnAtSurface.ActualP}
		  {Delay 2000}
		  {TurnByTurnGame ActualP MaxP Life {PersonalNewRecord TurnAtSurface ActualP 0}}
	       else
                  %finish
		  {TurnByTurnGame ((ActualP mod MaxP)+1) MaxP Life
		   {PersonalNewRecord TurnAtSurface ActualP TurnAtSurface.ActualP+1}}
	       end
	    end
	 end

	 {Browse hello}
	 {Delay 50}
	 %Ask choose direction |3|
	 local Id Position Direction in
	    {Browse 'move'}
	    %{Delay 1000}
	    {Send PortPlayers.ActualP move(Id Position Direction)}
	    if Direction == surface then
		  %say to other player |4|
	       {Sender saySurface(Id)}
		  %say to GUI
	       {Send PortGUI surface(Id)}
		  %finish
	       {TurnByTurnGame ((ActualP mod MaxP)+1) MaxP Life TurnAtSurface}
	    else
		  %say to other player the direction |5|
	       {Sender sayMove(Id Direction)}
		  %say to the GUI
	       {Send PortGUI movePlayer(Id Position)}
	    end
	 end

	 %Ask charge Item |6|
	 local Id KindItem in
	     {Browse 'ChargeItem'}
	    %{Delay 1000}
	    {Send PortPlayers.ActualP chargeItem(Id KindItem)}
	    {Wait Id}
	    if {Value.isDet KindItem} then
		  %say to other player that he charge
	       {Sender sayCharge(Id KindItem)}
	    end
	 end

	 %Ask fire |7|
	 local Id KindFire MsgR in
	    MsgR = {MakeRecord msg {BuildList 1 Input.nbPlayer}}
	     {Browse 'fireItem'}
	    {Delay 1000}
	    {Send PortPlayers.ActualP fireItem(Id KindFire)}
	    {Wait Id}
	     {Browse 'fireItem'(KindFire)}
	    {Delay 1000}
	    if {Value.isDet KindFire} then
		  %The case of KindFire is a mine 
	       case KindFire of mine(P) then
		  {Sender sayMinePlaced(Id)}
		  {Send PortGUI putMine(Id P)}
		     
		  %The case of KindFire is a missile
	       [] missile(P) then
		     %say to each player that a missil was launched
		  fun{Launch X L}
		     LP N
		  in
		     
		     if X > Input.nbPlayer then L
		     else
			{Send PortPlayers.X sayMissileExplode(Id P MsgR.X)}
			{Browse 'fireItem send missile'(X)}
			{Delay 1000}
			%check the response of the player X
			if MsgR.X > 0 then
			   %the player X lost life point
			   {Browse 'fireItem touch'(X)}
			   {Delay 1000}
			   LP = {Max 0 L.X-MsgR.X}
			   {Sender sayDamageTaken(X MsgR.X LP)}
			   {Send PortGUI lifeUpdate(X LP)}
			   if Life.X == 0 then
			       %The player X is dead
			      {Sender sayDeath(X)}
			   end
			   N = {Launch X+1 {PersonalNewRecord L X LP}}
			end
			N ={Launch X+1 L}
		     end
		  end
	       in
		  NewLife = {Launch 1 Life}	       
		     

		%The case of KindFire is a drone(row)
	       [] drone(row X) then
		  for X in 1..Input.nbPlayer do
		     Id Ans
		  in
		     {Send PortPlayers.X sayPassingDrone(KindFire Id Ans)}
		     {Wait Id}
		     {Send PortPlayers.ActualP sayAnswerDrone(KindFire Id Ans)}
		  end

		%The case of KindFire is a drone(column)
	       [] drone(column Y) then
		  for X in 1..Input.nbPlayer do
		     Id Ans
		  in
		     {Send PortPlayers.X sayPassingDrone(KindFire Id Ans)}
		     {Wait Id}
		     {Send PortPlayers.ActualP sayAnswerDrone(KindFire Id Ans)}
		  end
		%The case of KindFire is a sonar
	       [] sonar then
		  for X in 1..Input.nbPlayer do
		     Id Ans
		  in
		     {Send PortPlayers.X sayPassingSonar(Id Ans)}
		     {Wait Id}
		     {Send PortPlayers.ActualP sayAnswerSonar(Id Ans)}
		  end
		     %The case of KindFire is null
	       [] nil then
		  skip
	       end
	    end
	 end

	 %explode mine |8|
      local Id Mine MsgR in
	    MsgR = {MakeRecord msg {BuildList 1 Input.nbPlayer}}
	    {Wait Id}
	    if {Value.isDet Mine} then
	       if (Mine \= nil) then
		   %say to each player that a mine explode
		  fun{Explode X L}
		     LP N
		  in
		     {Send PortPlayers.X sayMineExplode(ActualP Mine MsgR.X)}
			%check the response of the player X
		     if MsgR.X > 0 then
			   %the player X lost life point
			LP = {Max 0 L.X-MsgR.X}
			{Sender sayDamageTaken(X MsgR.X LP)}
			{Send PortGUI lifeUpdate(X LP)}
			if LP == 0 then
			       %The player X is dead
			   {Sender sayDeath(X)}
			end
			N ={Explode X+1 {PersonalNewRecord L X LP}}
		     end
		     N ={Explode X+1 L}
		  end
	       in
		  
		  if{Value.isDet NewLife} then
		     NextLife = {Explode 1 NewLife}
		  else
		     NextLife = {Explode 1 Life}
		  end
		  
	       end
	       
	    end
	    
	 end

	 %finish |9|
	    if{Value.isDet NextLife} then
	       {TurnByTurnGame ((ActualP mod MaxP)+1) MaxP NextLife TurnAtSurface}
	    elseif {Value.isDet NewLife} then
	       {TurnByTurnGame ((ActualP mod MaxP)+1) MaxP NextLife TurnAtSurface}
	    else	       
	       {TurnByTurnGame ((ActualP mod MaxP)+1) MaxP Life TurnAtSurface}
	    end
	    
      end
   end
   
   {Browse 1}
   % Creation du Port vers le GUI et affichage de la fenetre
   PortGUI = {GUI.portWindow}
   {Send PortGUI buildWindow}
   {Browse 2}
   % Creation d'un record contenant les ports 'joueurs'. PortPlayers = portPlayer(1:P1 2:P2 3:P3 ... nbPlayer:PnbPlayer)
   PortPlayers={SetPlayersPort Input.players Input.colors Input.nbPlayer}
   {Browse 3}
   % Demande aux joueurs de choisir leur position initiale
   for I in 1..{Width PortPlayers} do
      local Id Pos in
	 {Send PortPlayers.I initPosition(Id Pos)}
	 {Send PortGUI initPlayer(Id Pos)}
      end
   end
   {Browse 4}
   {Wait PortPlayers.4}
   {Browse 5}
   if Input.isTurnByTurn then
      {Delay 10000}
      {TurnByTurnGame 1 Input.nbPlayer {BuildLifeRecord Input.nbPlayer} {BuildTurnAtSurfaceCounter Input.nbPlayer} }
   else
      skip
   end
end
