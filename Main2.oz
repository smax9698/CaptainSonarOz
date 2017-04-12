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
      fun{BuildList A Max}
	 if A == Max then Max|nil
	 else
	    A|{BuildList A+1 Max}
	 end
      end
   in
      {FillRecord {MakeRecord portPlayer {BuildList 1 N}} KindP ColorP 1}
   end

   fun{BuildLifeRecord NbPlayer}
      if NbPlayer == 0 then nil
      else
	 Input.maxDamage|{BuildLifeRecord NbPlayer-1}
      end
   end

   
   fun{CheckEnd Tab}
      fun{CheckEnd T Acc}
	 case T
	 of A|B then
	    if A == 0 then {CheckEnd B Acc+1}
	    else {CheckEnd B Acc}
	    end
	 [] nil then Acc==(Input.nbPlayer-1)
	 end
      end
   in
      {CheckEnd Tab 0}
   end
   
   % Jeu tour par tour. S'arrete quand il ne reste plus qu'un joueur en vie 
   fun{TurnByTurnGame ActualP MaxP Life}
      Ans Pos Dir Pos2 Dir2 Id1 Id2 Id3 Id4 Id5 Item Item2 Item3
   in
      if {CheckEnd Life} then % End of the game
	 {Browse 'End Of The Game'}
	 true
      else

	 % IMPLEMENTER UN TOUR 
	 % Check if the submarine can play
	 local Id in
	    {Send PortPlayers.ActualP isSurface(Id Ans)}
	 end
	 {Send PortPlayers.ActualP move(Id1 Pos Dir)}
	 {Browse Pos}
	 {Browse Dir}
	 {Delay 3000}
	 {Send PortGUI movePlayer(Id1 Pos)}

	 {Send PortPlayers.ActualP move(Id2 Pos2 Dir2)}
	 {Browse Pos2}
	 {Browse Dir2}
	 {Delay 3000}
	 {Send PortGUI movePlayer(Id2 Pos2)}

	 {Send PortPlayers.ActualP chargeItem(Id3 Item)}
	 {Browse Item|Item}
	 {Delay 1000}

	 {Send PortPlayers.ActualP chargeItem(Id4 Item2)}
	 {Browse Item2|Item2}
	 {Delay 1000}

	 {Send PortPlayers.ActualP chargeItem(Id5 Item3)}
	 {Browse Item3|Item3}
	 {Delay 1000}

	 {TurnByTurnGame ActualP MaxP [0 0 0 1]}
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
      V = {TurnByTurnGame 1 Input.nbPlayer {BuildLifeRecord Input.nbPlayer}}
   else
      skip
   end

end
