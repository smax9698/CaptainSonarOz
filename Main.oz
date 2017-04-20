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
   SetPlayersId
   IdPlayers
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

   fun{SetPlayersId ColorP N}
      fun{FillRecord R ColorP Id}
	 case ColorP
	 of P|Pr then R.Id=id(id:Id color:P name:Id)
	    {FillRecord R Pr Id+1}
	 [] nil then R
	 end
      end
   in
      {FillRecord {MakeRecord idPlayer {BuildList 1 N}} ColorP 1}
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
   proc{Sender Msg Life}
      for X in 1..Input.nbPlayer do
	 if Life.X > 0 then
	    {Send PortPlayers.X Msg}
	 end
      end
   end
   

   
   fun{CheckEnd Tab}
      fun{CheckEndA T Pos Acc}
	 A
      in
	 if Pos > Input.nbPlayer then
	    Acc >= (Input.nbPlayer-1)
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
      
      
      if {CheckEnd Life} then % End of the game
	 {Browse Life}
	 {Browse 'End Of The Game'}
      elseif Life.ActualP == 0 then % Le joueur est mort donc au suivant
	 {Browse nextImDead}
	 {TurnByTurnGame ((ActualP mod MaxP)+1) MaxP Life TurnAtSurface} 
      else
	 {Delay 600}
	 % IMPLEMENTER UN TOUR 
	 % Check if the submarine can play |1|

	 local Id2 Ans2 in
	    {Send PortPlayers.ActualP isSurface(Id2 Ans2)}
	    if Ans2 then
	       if TurnAtSurface.ActualP == Input.turnSurface then
		  %say dive |2|
		  {Send PortPlayers.ActualP dive}
		  {TurnByTurnGame ActualP MaxP Life {PersonalNewRecord TurnAtSurface ActualP 0}}
	       else
                  %finish
		  {TurnByTurnGame ((ActualP mod MaxP)+1) MaxP Life {PersonalNewRecord TurnAtSurface ActualP TurnAtSurface.ActualP+1}}
	       end
	    else

	       %Ask choose direction |3|
	       local Id3 Position3 Direction3 in
		  {Send PortPlayers.ActualP move(Id3 Position3 Direction3)}
		  if Direction3 == surface then
		     %say to other player |4|
		     {Sender saySurface(Id3) Life}
		     %say to GUI
		     {Send PortGUI surface(Id3)}
		     %increment turn at surface and finish
		     {TurnByTurnGame ((ActualP mod MaxP)+1) MaxP Life {PersonalNewRecord TurnAtSurface ActualP 1}}
		  else
		     %say to other player the direction |5|
		     {Sender sayMove(Id3 Direction3) Life}
		     %say to the GUI
		     {Send PortGUI movePlayer(Id3 Position3)}

		     %Ask charge Item |6|
		     local Id6 KindItem in
			{Send PortPlayers.ActualP chargeItem(Id6 KindItem)}
			{Wait Id6}
			if {Value.isDet KindItem} then
			   if KindItem \= nil then
                              %say to other player that he charge
			      {Sender sayCharge(Id6 KindItem) Life}
			   end
			end
		     end

		     local NewLife NewLifeAfterMine in
			NewLife={MakeRecord newLife {BuildList 1 Input.nbPlayer}}
			NewLifeAfterMine={MakeRecord newLifeAfterMine {BuildList 1 Input.nbPlayer}}

	                %Ask fire |7|
			local Id7 KindFire Msg in
			   {Send PortPlayers.ActualP fireItem(Id7 KindFire)}
			   {Wait Id7}
			   if {Value.isDet KindFire} then

		              %The case of KindFire is a mine 
			      case KindFire of mine(P) then
				 {Sender sayMinePlaced(Id7) Life}
				 {Send PortGUI putMine(Id7 P)}
				 for X in 1..Input.nbPlayer do
				    NewLife.X = Life.X
				 end
				 
		              %The case of KindFire is a missile
			      [] missile(P) then
				 {Browse bOOM}
		              %say to each player that a missil was launched

				 
				 for X in 1..Input.nbPlayer do
				    local Msg in

			               %check the response of the player X
				       if Life.X > 0 then
					  {Send PortPlayers.X sayMissileExplode(Id7 P Msg)}
					  if Msg \= nil then

			                  %the player X lost life point
					     NewLife.X = {Max 0 Life.X-Msg}
					     {Sender sayDamageTaken(IdPlayers.X Msg NewLife.X) Life}
					     if NewLife.X > 0 then
						{Send PortGUI lifeUpdate(IdPlayers.X NewLife.X)}
					     end
			
					     if NewLife.X == 0 then
			                     %The player X is dead
						{Sender sayDeath(IdPlayers.X) Life}
						{Browse missile|removePlayer|IdPlayers.X}
					     
						{Send PortGUI removePlayer(IdPlayers.X)}
					     end
					  else
					     NewLife.X = Life.X
					  end
				       else
					  NewLife.X=Life.X
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
				    NewLife.X = Life.X
				 end

		              %The case of KindFire is a drone(column)
			      [] drone(column Y) then
				 
				 for X in 1..Input.nbPlayer do
				    Id Ans
				 in
				    {Send PortPlayers.X sayPassingDrone(KindFire Id Ans)}
				    {Wait Id}
				    {Send PortPlayers.ActualP sayAnswerDrone(KindFire Id Ans)}
				    NewLife.X=Life.X
				 end
				 
		              %The case of KindFire is a sonar
			      [] sonar then
				 
				 for X in 1..Input.nbPlayer do
				    Id Ans
				 in
				    {Send PortPlayers.X sayPassingSonar(Id Ans)}
				    {Wait Id}
				    {Send PortPlayers.ActualP sayAnswerSonar(Id Ans)}
				    NewLife.X=Life.X
				 end
				 
		              %The case of KindFire is null
			      [] nil then
				 for X in 1..Input.nbPlayer do
				    NewLife.X = Life.X
				 end
			      end
			   end
			end

	                %explode mine |8|
			local Id8 Mine in
			   
			   {Send PortPlayers.ActualP fireMine(Id8 Mine)}
			   {Wait Id8}
			   if {Value.isDet Mine} then
			      if (Mine \= nil) then
				 {Send PortGUI removeMine(Id8 Mine)}
                                 %say to each player that a mine explode
				 for X in 1..Input.nbPlayer do
				    Msg
				 in
				    if NewLife.X > 0 then
				       {Send PortPlayers.X sayMineExplode(Id8 Mine Msg)}
		                       %check the response of the player X
				       if Msg > 0 then
					  {Browse lost_life_on_mine}
			                  %the player X lost life point
					  NewLifeAfterMine.X = {Max 0 NewLife.X-Msg}
					  {Sender sayDamageTaken(IdPlayers.X Msg NewLifeAfterMine.X) NewLife}

					  if NewLifeAfterMine.X > 0 then
					     {Send PortGUI lifeUpdate(IdPlayers.X NewLifeAfterMine.X)}
					  end

					  if NewLifeAfterMine.X == 0 then
			                     %The player X is dead
					     {Sender sayDeath(IdPlayers.X) NewLife}
					     {Browse removePlayer}
					     {Send PortGUI removePlayer(IdPlayers.X)}
					  end
				       else
					  NewLifeAfterMine.X = NewLife.X
				       end
				    else
				       NewLifeAfterMine.X = NewLife.X
				    end
				 end
				 
			      else
				 for X in 1..Input.nbPlayer do
				    NewLifeAfterMine.X = NewLife.X
				 end
			      end
	       
			   end
	    
			end

	                %finish |9|
			{TurnByTurnGame ((ActualP mod MaxP)+1) MaxP NewLifeAfterMine TurnAtSurface}
		     end
		  end	     
	       end
	    end
	 end
      end
   end
   
   % Creation du Port vers le GUI et affichage de la fenetre
   PortGUI = {GUI.portWindow}
   {Send PortGUI buildWindow}

   % Creation d'un record contenant les ports 'joueurs'. PortPlayers = portPlayer(1:P1 2:P2 3:P3 ... nbPlayer:PnbPlayer)
   PortPlayers={SetPlayersPort Input.players Input.colors Input.nbPlayer}

   % Creation d'un record contenant les id 'joueurs'.
   IdPlayers={SetPlayersId Input.colors Input.nbPlayer}
   {Browse IdPlayers}

   % Demande aux joueurs de choisir leur position initiale
   for I in 1..{Width PortPlayers} do
      local Id Pos in
	 {Send PortPlayers.I initPosition(Id Pos)}
	 {Send PortGUI initPlayer(Id Pos)}
      end
   end
   
   
   {Browse begin}
   if Input.isTurnByTurn then
      {Delay 3000}
      {TurnByTurnGame 1 Input.nbPlayer {BuildLifeRecord Input.nbPlayer} {BuildTurnAtSurfaceCounter Input.nbPlayer}}
   else
      skip
   end

   for U in 1..Input.nbPlayer do
      {Send PortPlayers.U nil}
   end

   {Send PortGUI nil}
   {Delay 4000}
   
   {Browse 'the END'}
end