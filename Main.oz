functor
import
   GUI
   Input
   System
   PlayerManager
   Browser
   OS
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
   SimultaneousGame
   ServerLife
   PortLife
   StartServerLife
   End
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

   %construit une liste de A à Max A|...|max|nil
   fun{BuildList A Max}
      if A == Max then Max|nil
      else
	 A|{BuildList A+1 Max}
      end
   end

   %construit un record life(1:maxdammage ...) avec NbPlayer champs initialisé à maxDammage
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

   %construit un record life(1:turnSurface ...) avec NbPlayer champs initialisé à turnSurface
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


   %revoie true s'il n'y a plus qu'un joueur vivant
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

   %renvoie un nouveau record à partir de R ou la valeur contenue en Feat est remplacée par Val
   fun{PersonalNewRecord R Feat Val}
      PNRSub NewR
   in
      PNRSub = {Record.subtract R Feat}
      NewR = {AdjoinAt R Feat Val}
   end

   %Démare le serverLife (utile dans la version simultanée)
   fun{StartServerLife}
      Stream
      Port
      Life
      NumberInLife
   in
      {NewPort Stream Port}
      Life = {BuildLifeRecord Input.nbPlayer}
      NumberInLife = Input.nbPlayer
      thread
	 {ServerLife Stream Life NumberInLife}
      end
      Port
   end

   %ServerLife (utile dans la version simultanée)
   %Il reçoit les mise à jour des points de vie ainsi que les demandes d'état de la vie des joueurs
   proc{ServerLife Msg Life NumberInLife}
      case Msg of all(X)|T then
	 X = NumberInLife
	 {ServerLife T Life NumberInLife}
      [] life(p:Actual l:Y)|T then
	 Y = Life.Actual
	 {ServerLife T Life NumberInLife}
      [] long(L)|T then
	 L = Life
	 {ServerLife T Life NumberInLife}
      [] newlife(p:X l:L)|T then
	 if(L == 0) then
	    {ServerLife T {PersonalNewRecord Life X L} NumberInLife-1}
	 else
	    {ServerLife T {PersonalNewRecord Life X L} NumberInLife}
	 end
      end
   end


   % Jeu tour par tour. S'arrete quand il ne reste plus qu'un joueur en vie
   proc{TurnByTurnGame ActualP MaxP Life TurnAtSurface}


      if {CheckEnd Life} then % End of the game
	 {Browse 'End Of The Game'}
      elseif Life.ActualP == 0 then % Le joueur est mort donc au suivant
	 {TurnByTurnGame ((ActualP mod MaxP)+1) MaxP Life TurnAtSurface}
      else

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
		              %say to each player that a missil was launched
				 {Send PortGUI explosion(Id7 P)}
				 for X in 1..Input.nbPlayer do


			               %check the answer of the player X
				    if Life.X > 0 then
				       Msg in
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
					     {Send PortGUI removePlayer(IdPlayers.X)}
					  end
				       else
					  NewLife.X = Life.X
				       end
				    else
				       NewLife.X=Life.X
				    end
				 end

		              %The case of KindFire is a drone(row)
			      [] drone(row X) then

				 for X in 1..Input.nbPlayer do
				    Id Ans
				 in
				    {Send PortPlayers.X sayPassingDrone(KindFire Id Ans)}
				    {Wait Id}
				    if(Id \= nil) then
				       {Send PortPlayers.ActualP sayAnswerDrone(KindFire Id Ans)}
				    end

				    NewLife.X = Life.X
				 end

		              %The case of KindFire is a drone(column)
			      [] drone(column Y) then

				 for X in 1..Input.nbPlayer do
				    Id Ans
				 in
				    {Send PortPlayers.X sayPassingDrone(KindFire Id Ans)}
				    {Wait Id}
				    if(Id \= nil) then
				       {Send PortPlayers.ActualP sayAnswerDrone(KindFire Id Ans)}
				    end

				    NewLife.X=Life.X
				 end

		              %The case of KindFire is a sonar
			      [] sonar then

				 for X in 1..Input.nbPlayer do
				    Id Ans
				 in
				    {Send PortPlayers.X sayPassingSonar(Id Ans)}
				    {Wait Id}
				    if(Id \= nil) then
				       {Send PortPlayers.ActualP sayAnswerSonar(Id Ans)}
				    end
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
				 {Send PortGUI explosion(Id8 Mine)}
                                 %say to each player that a mine explode
				 for X in 1..Input.nbPlayer do
				    Msg
				 in
				    if NewLife.X > 0 then
				       {Send PortPlayers.X sayMineExplode(Id8 Mine Msg)}
		                       %check the response of the player X
				       if Msg \= nil then

			                  %the player X lost life point
					  NewLifeAfterMine.X = {Max 0 NewLife.X-Msg}
					  {Sender sayDamageTaken(IdPlayers.X Msg NewLifeAfterMine.X) NewLife}

					  if NewLifeAfterMine.X > 0 then
					     {Send PortGUI lifeUpdate(IdPlayers.X NewLifeAfterMine.X)}
					  end

					  if NewLifeAfterMine.X == 0 then
			                     %The player X is dead
					     {Sender sayDeath(IdPlayers.X) NewLife}
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


   %version simultanée
   proc{SimultaneousGame ActualP MaxP}
      X Y Life
   in
      {Send PortLife all(X)} %nombre de joueur encore en vie
      {Send PortLife long(Life)}
      {Send PortLife life(p:ActualP l:Y)} %vie du joueur actuel
      if  X == 1 then
	 End.ActualP = 0
      elseif Y == 0 then
	 %the player is dead
	 End.ActualP = 0
      else
	 local Id2 Ans2 in
	    %check if the payer is on surface
	    {Send PortPlayers.ActualP isSurface(Id2 Ans2)}
	    if Ans2 then

	       %say dive
	       {Send PortPlayers.ActualP dive}
	       {SimultaneousGame ActualP MaxP}
	    else
	       %simulate thinking |2|
	       {Delay (({OS.rand} mod Input.thinkMin) + (Input.thinkMax-Input.thinkMin))}

	       local Id3 Position3 Direction3 Life in
		  %chose direction |3|
		  {Send PortLife long(Life)}
		  {Send PortPlayers.ActualP move(Id3 Position3 Direction3)}
		  if Direction3 == surface then
		     %time to wait at surface
		     {Delay Input.turnSurface*1000}
		     %say to other player |4|
		     {Sender saySurface(Id3) Life}
		     %say to GUI
		     {Send PortGUI surface(Id3)}
		     {SimultaneousGame ActualP MaxP}
		  else
		     %say to other player the direction |5|
		     {Sender sayMove(Id3 Direction3) Life}
		     %say to the GUI
		     {Send PortGUI movePlayer(Id3 Position3)}
		  end % end if direction
	       end%end local direction
	    end% end if surface
	 end % end local surface


	 %simulate thinking |6|
	 {Delay (({OS.rand} mod Input.thinkMin) + (Input.thinkMax-Input.thinkMin))}

	 %Ask charge Item |7|
	 local Id6 KindItem Life in
	    {Send PortLife long(Life)}
	    {Send PortPlayers.ActualP chargeItem(Id6 KindItem)}
	    {Wait Id6}
	    if {Value.isDet KindItem} then
	       if KindItem \= nil then
                  %say to other player that he charge
		  {Sender sayCharge(Id6 KindItem) Life}
	       end
	    end
	 end

	 %simulate thinking |8|
	 {Delay (({OS.rand} mod Input.thinkMin) + (Input.thinkMax-Input.thinkMin))}

	 %Ask fire |9|
	 local Id7 KindFire Msg Life in
	    {Send PortLife long(Life)}
	    {Send PortPlayers.ActualP fireItem(Id7 KindFire)}
	    {Wait Id7}
	    if {Value.isDet KindFire} then
               %The case of KindFire is a mine
	       case KindFire of mine(P) then
		  {Sender sayMinePlaced(Id7) Life}
		  {Send PortGUI putMine(Id7 P)}

	       %The case of KindFire is a missile
	       [] missile(P) then

		  {Send PortGUI explosion(Id7 P)}
		  %say to each player that a missil was launched
		  for X in 1..Input.nbPlayer do
		     local Msg Lifex Life NewLife in
			%check the response of the player X
			{Send PortLife life(p:X l:Lifex)}
			{Send PortLife long(Life)}
			if Lifex > 0 then
			   {Send PortPlayers.X sayMissileExplode(Id7 P Msg)}
			   if Msg \= nil then

			      %the player X lost life point
			      NewLife = {Max 0 Lifex-Msg}
			      {Send PortLife newlife(p:X l:NewLife)}
			      {Sender sayDamageTaken(IdPlayers.X Msg NewLife) Life}
			      if NewLife > 0 then
				 {Send PortGUI lifeUpdate(IdPlayers.X NewLife)}
			      end

			      if NewLife == 0 then
			         %The player X is dead
				 {Browse IdPlayers.X|deadonmissile|P}
				 {Sender sayDeath(IdPlayers.X) Life}

				 {Send PortGUI removePlayer(IdPlayers.X)}
			      end
			   end
			end

		     end
		  end

	       %The case of KindFire is a drone(row)
	       [] drone(row X) then

		  for X in 1..Input.nbPlayer do
		     local Id Ans
		     in
			{Send PortPlayers.X sayPassingDrone(KindFire Id Ans)}
			{Wait Id}
			if(Id \= nil) then
			   {Send PortPlayers.ActualP sayAnswerDrone(KindFire Id Ans)}
			end
		     end

		  end

	       %The case of KindFire is a drone(column)
	       [] drone(column Y) then

		  for X in 1..Input.nbPlayer do
		     local Id Ans
		     in
			{Send PortPlayers.X sayPassingDrone(KindFire Id Ans)}
			{Wait Id}
			if(Id \= nil) then
			   {Send PortPlayers.ActualP sayAnswerDrone(KindFire Id Ans)}
			end
		     end

		  end

	       %The case of KindFire is a sonar
	       [] sonar then

		  for X in 1..Input.nbPlayer do
		     local Id Ans
		     in
			{Send PortPlayers.X sayPassingSonar(Id Ans)}
			{Wait Id}
			if(Id \= nil) then
			   {Send PortPlayers.ActualP sayAnswerSonar(Id Ans)}
			end
		     end
		  end

	       %The case of KindFire is null
	       [] nil then skip
	       end %end case kindfire
	    end %end if det
	 end % end local kindfire

	 %simulate thinking |10|
	 {Delay (({OS.rand} mod Input.thinkMin) + (Input.thinkMax-Input.thinkMin))}

	 %explode mine |11|
	 local Id8 Mine in

	    {Send PortPlayers.ActualP fireMine(Id8 Mine)}
	    {Wait Id8}
	    if {Value.isDet Mine} then
	       if (Mine \= nil) then
		  {Send PortGUI explosion(Id8 Mine)}
		  {Send PortGUI removeMine(Id8 Mine)}
                  %say to each player that a mine explode
		  for X in 1..Input.nbPlayer do
		     local  Msg Lifex Life NewLife  in
			%check the response of the player X
			{Send PortLife life(p:X l:Lifex)}
			{Send PortLife long(Life)}
			{Wait Lifex}
			{Wait Life}
			if Lifex > 0 then
			   {Send PortPlayers.X sayMineExplode(Id8 Mine Msg)}
		           %check the response of the player X
			   {Wait Msg}
			   if Msg \=nil then
			      %the player X lost life point
			      NewLife = {Max 0 Lifex-Msg}
			      {Send PortLife newlife(p:X l:NewLife)}
			      {Sender sayDamageTaken(IdPlayers.X Msg NewLife) Life}

			      if NewLife > 0 then
				 {Send PortGUI lifeUpdate(IdPlayers.X NewLife)}
			      end

			      if NewLife == 0 then
			         %The player X is dead
				 {Browse IdPlayers.X|deadonmine|Mine}
				 {Sender sayDeath(IdPlayers.X) Life}
				 {Send PortGUI removePlayer(IdPlayers.X)}
			      end
			   end % end if Msg
			end %end if lifex
		     end %end local for
		  end %end for
	       end %end min\ nil

	    end %end isdet
	 end %end local mine
	 {SimultaneousGame ActualP MaxP}

      end %end if alife
   end%end proc


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
      %jeu tour par tour
      {Delay 3000}
      {TurnByTurnGame 1 Input.nbPlayer {BuildLifeRecord Input.nbPlayer} {BuildTurnAtSurfaceCounter Input.nbPlayer}}
   else
      %jeu simultané
      {Delay 3000}
      PortLife = {StartServerLife}
      End = {MakeRecord endlist {BuildList 1 Input.nbPlayer}}
      for X in 1..Input.nbPlayer do
	 thread {SimultaneousGame X Input.nbPlayer} end
      end
      {Browse here}
      for X in 1.. Input.nbPlayer do
	 {Wait End.X}
      end

   end


   {Delay 1000}
   for U in 1..Input.nbPlayer do
      {Send PortPlayers.U nil}
   end

   {Send PortGUI stop}
   {Send PortGUI nil}
   {Delay 2000}

   {Browse 'the END'}
end
