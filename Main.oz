functor
import
   GUI
   Input
   PlayerManager
   Browser
define
   Browse=Browser.browse
   PortGUI
in
   PortGUI = {GUI.portWindow}
   {Send PortGUI buildWindow}
end