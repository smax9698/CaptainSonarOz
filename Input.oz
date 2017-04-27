functor
import
   OS
export
   isTurnByTurn:IsTurnByTurn
   nRow:NRow
   nColumn:NColumn
   map:Map
   nbPlayer:NbPlayer
   players:Players
   colors:Colors
   thinkMin:ThinkMin
   thinkMax:ThinkMax
   turnSurface:TurnSurface
   maxDamage:MaxDamage
   missile:Missile
   mine:Mine
   sonar:Sonar
   drone:Drone
   minDistanceMine:MinDistanceMine
   maxDistanceMine:MaxDistanceMine
   minDistanceMissile:MinDistanceMissile
   maxDistanceMissile:MaxDistanceMissile
   mapGenerator:MapGenerator
define
   MapGenerator
   LineGenerator
   IsTurnByTurn
   NRow
   NColumn
   Map
   NbPlayer
   Players
   Colors
   ThinkMin
   ThinkMax
   TurnSurface
   MaxDamage
   Missile
   Mine
   Sonar
   Drone
   MinDistanceMine
   MaxDistanceMine
   MinDistanceMissile
   MaxDistanceMissile
in

   fun {LineGenerator Y Density}
      if Y==0 then nil
      else
	 if {OS.rand} mod 100 < Density then
	    1|{LineGenerator Y-1 Density}
	 else
	    0|{LineGenerator Y-1 Density}
	 end
      end
   end

   fun{MapGenerator X Y Density}
      if X == 0 then nil
      else
	 {LineGenerator Y Density}|{MapGenerator X-1 Y Density}
      end
   end

%%%% Style of game %%%%

   IsTurnByTurn = true

%%%% Description of the map %%%%

   NRow = 9
   NColumn = 9

   % Map = [[0 0 0]
   % 	  [0 0 0]
   %      [0 0 0]]

   % Map = [[0 0 0 0 1]
   % 	  [1 0 0 0 0]
   % 	  [1 0 0 0 1]
   % 	  [1 0 1 0 1]
   % 	  [1 0 0 0 1]]

   Map = {MapGenerator NRow NColumn 15}

%%%% Players description %%%%

   NbPlayer = 4
   Players = [advancedAI basicAI basicAI basicAI]
   Colors = [green yellow red blue]

%%%% Thinking parameters (only in simultaneous) %%%%

   ThinkMin = 50
   ThinkMax = 300

%%%% Surface time/turns %%%%

   TurnSurface = 3

%%%% Life %%%%

   MaxDamage = 4

%%%% Number of load for each item %%%%

   Missile = 2
   Mine = 2
   Sonar = 2
   Drone = 2

%%%% Distances of placement %%%%

   MinDistanceMine = 1
   MaxDistanceMine = 2
   MinDistanceMissile = 1
   MaxDistanceMissile = 4



end
