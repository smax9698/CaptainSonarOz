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
      
      if Life.ActualP == 0 then {TurnByTurnGame ((ActualP mod MaxP)+1) MaxP Life TurnAtSurface} 
      elseif {CheckEnd Life} then % End of the game
	 {Browse 'End Of The Game'}
      else
	 
	 % IMPLEMENTER UN TOUR 
	 % Check if the submarine can play |1|
	 local Id Ans in
	    {Send PortPlayers.ActualP isSurface(Id Ans)}
	    if Ans then
	       if TurnAtSurface.ActualP == Input.turnSurface then
		  %say dive |2|
		  {Send PortPlayers.ActualP dive}
		  {TurnByTurnGame ActualP MaxP Life {PersonalNewRecord TurnAtSurface ActualP 0}}
	       else
                  %finish
		  {TurnByTurnGame ((ActualP mod MaxP)+1) MaxP Life {PersonalNewRecord TurnAtSurface ActualP TurnAtSurface.ActualP+1}}
	       end
	    end
	 end

	 {Browse hello}
	 {Delay 50}
	 %Ask choose direction |3|
	 local Id Position Direction in
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
	       {Browse zizi}
	       {Send PortGUI movePlayer(Id Position)}
	    end
	 end

	 %Ask charge Item |6|
	 local Id KindItem in
	    {Send PortPlayers.ActualP chargeItem(Id KindItem)}
	    {Wait Id}
	    if {Value.isDet KindItem} then
		  %say to other player that he charge
	       {Sender sayCharge(Id KindItem)}
	    end
	 end

	 %Ask fire |7|
	 local Id KindFire Msg in
	    {Send PortPlayers.ActualP fireItem(Id KindFire)}
	    {Wait Id}
	    if {Value.isDet KindFire} then
		  %The case of KindFire is a mine 
	       case KindFire of mine(P) then
		  {Sender sayMinePlaced(Id)}
		  {Send PortGUI putMine(Id P)}
		     
		  %The case of KindFire is a missile
	       [] missile(P) then
		     %say to each player that a missil was launched
		  for X in 1..Input.nbPlayer do
		     {Send PortPlayers.X sayMissileExplode(Id P Msg)}
			%check the response of the player X
		     if Msg > 0 then
			   %the player X lost life point
			Life.X = {Max 0 Life.X-Msg}
			{Sender sayDamageTaken(X Msg Life.X)}
			{Send PortGUI lifeUpdate(X Life.X)}
			if Life.X == 0 then
			       %The player X is dead
			   {Sender sayDeath(X)}
			end
		     end
		  end	  

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
	 local Id Mine Msg in
	    {Send PortPlayers.ActualP fireMine(Id Mine)}
	    {Wait Id}
	    if {Value.isDet Mine} then
	       if (Mine \= nil) then
		   %say to each player that a mine explode
		  for X in 1..Input.nbPlayer do
		     {Send PortPlayers.X sayMineExplode(ActualP Mine Msg)}
			%check the response of the player X
		     if Msg > 0 then
			   %the player X lost life point
			Life.X = {Max 0 Life.X-Msg}
			{Sender sayDamageTaken(X Msg Life.X)}
			{Send PortGUI lifeUpdate(X Life.X)}
			if Life.X == 0 then
			       %The player X is dead
			   {Sender sayDeath(X)}
			end
		     end
		  end
	       end
	       
	    end
	    
	 end

	 %finish |9|
	 {TurnByTurnGame ((ActualP mod MaxP)+1) MaxP Life TurnAtSurface}
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
