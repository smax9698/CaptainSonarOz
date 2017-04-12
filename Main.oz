functor
import
   GUI
   Input
   PlayerManager
   Browser
define
   Browse=Browser.browse
   PortGUI
   PortPlayers
   BuildLifeRecord
   SetPlayersPort
   TurnByTurnGame
   CheckEnd
   BuildList
   BuildTurnAtSurfaceCounter
   V
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
      end
   end

   %Send Message to all player
   proc{Sender Msg}
      for X in 1..Input.NbPlayer
	 {Send PortPlayers.X Msg}
      end
   end
   

   
   fun{CheckEnd Tab}
      fun{CheckEnd T Acc}
	 case T
	 of A|B then
	    if A == 0 then {CheckEnd B Acc+1}
	    else {CheckEnd B Acc}
	    end
	 [] nil then {Browse Acc} Acc==(Input.nbPlayer-1)
	 end
      end
   in
      {CheckEnd Tab 0}
   end
   
   % Jeu tour par tour. S'arrete quand il ne reste plus qu'un joueur en vie 
   fun{TurnByTurnGame ActualP MaxP Life TurnAtSurface}
  
   in
      if Life.ActualP == 0 then {TurnByTurnGame (ActualP+1 mod MaxP) MaxP Life} 
      elseif {CheckEnd Life} then % End of the game
	 {Browse 'End Of The Game'}
	 true
      else

	 % IMPLEMENTER UN TOUR 
	 % Check if the submarine can play |1|
	 local Id Ans in
	    {Send PortPlayers.ActualP isSurface(Id Ans)}
	    if Ans == true
	       if TurnAtSurface.ActualP == Input.turnSurface then
		  %say dive |2|
		  {Send PortPlayers.ActualP dive}
		  TurnAtSurface.ActualP = 0
	       else TurnAtSurface.ActualP = TurnAtSurface.ActualP + 1
                  %finish
		  {TurnByTurnGame (ActualP+1 mod MaxP) MaxP Life TurnAtSurface}
	       end
	    end
	 end

	 %Ask choose direction |3|
	 local Id Position Direction in
	    {Send PortPlayer.ActualP move(Id Position Direction)}
	    if Direction == surface then
		  %say to other player |4|
	       {Sender saySurface(ActualP)}
		  %say to GUI
	       {Send PortGUI surface(ActualP)}
		  %finish
	       {TurnByTurnGame (ActualP+1 mod MaxP) MaxP Life TurnAtSurface}
	    else
		  %say to other player the direction |5|
	       {Sender sayMove(ActualP Direction)}
		  %say to the GUI
	       {Send PortGUI movePlayer(ActualP Position)}
	    end
	 end

	 %Ask charge Item |6|
	 local Id KindItem in
	    {Send PortPlayers.ActualP chargeItem(Id KindItem)}
	    {Wait Id}
	    if {Value.isDet KindItem}
		  %say to other player that he charge
	       {Sender sayCharge(ActualP KindItem)}
	    end
	 end

	 %Ask fire |7|
	 local Id KindFire Msg in
	    {Send PortPlayers.ActualP fireItem(Id KindFire)}
	    {Wait Id}
	    if {Value.isDet KindFire} then
		  %The case of KindFire is a mine 
	       case KindFire of mine(P) then
		  {Sender sayMinePlaced(ActualP)}
		  {Send PortGUI putMine(ActualP P)}
		     
		  %The case of KindFire is a missile
	       [] missile(P) then
		     %say to each player that a missil was launched
		  for X in 1..Input.NbPlayer do
		     Id Ans
		  in
		     {Send PortPlayers.X sayMissileExplode(ActualP P Msg)}
			%check the response of the player X
		     if Msg > 0 then
			   %the player X lost life point
			Life.X = {max 0 Life.X-Msg}
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
		  for X in 1..Input.NbPlayer do
		     Id Ans
		  in
		     {Send PortPlayers.X sayPassingDrone(KindFire Id Ans)}
		     {Wait Id}
		     {Send PortPlayers.ActualP sayAnswerDrone(Kindfire Id Ans)}
		  end

		%The case of KindFire is a drone(column)
	       [] drone(column Y) then
		  for X in 1..Input.NbPlayer do
		     Id Ans
		  in
		     {Send PortPlayers.X sayPassingDrone(KindFire Id Ans)}
		     {Wait Id}
		     {Send PortPlayers.ActualP sayAnswerDrone(Kindfire Id Ans)}
		  end
		%The case of KindFire is a sonar
	       [] sonar then
		  for X in 1..Input.NbPlayer do
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
	    if {Value.isDet Mine}
	       if Mine != nil
		   %say to each player that a mine explode
		  for X in 1..Input.NbPlayer do
		     Id Ans
		  in
		     {Send PortPlayers.X sayMineExplode(ActualP Mine Msg)}
			%check the response of the player X
		     if Msg > 0 then
			   %the player X lost life point
			Life.X = {max 0 Life.X-Msg}
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
	 {TurnByTurnGame (ActualP+1 mod MaxP) MaxP Life TurnAtSurface}
      end
   end
   
   
   % Creation du Port vers le GUI et affichage de la fenetre
   PortGUI = {GUI.portWindow}
   {Send PortGUI buildWindow}

   % Creation d'un record contenant les ports 'joueurs'. PortPlayers = portPlayer(1:P1 2:P2 3:P3 ... nbPlayer:PnbPlayer)
   PortPlayers={SetPlayersPort Input.players Input.colors Input.nbPlayer}

   % Demande aux joueurs de choisir leur position initiale
   for I in 1..{Width PortPlayers} do
      local Id Pos in
	 {Send PortPlayers.I initPosition(Id Pos)}
	 {Send PortGUI initPlayer(Id Pos)}
      end
   end
   {Wait PortPlayers.4}

   if Input.isTurnByTurn then
      V = {TurnByTurnGame 1 Input.nbPlayer {BuildLifeRecord Input.nbPlayer} {BuildTurnAtSurfaceCounter Input.nbPlayer} }
   else
      skip
   end
end
