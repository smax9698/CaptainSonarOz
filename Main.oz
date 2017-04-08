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
   SetPlayersPort
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
   
   % Creation du Port vers le GUI et affichage de la fenetre
   PortGUI = {GUI.portWindow}
   {Send PortGUI buildWindow}

   % Creation d'un record contenant les ports 'joueurs'
   PortPlayers={SetPlayersPort Input.players Input.colors Input.nbPlayer}
   
end