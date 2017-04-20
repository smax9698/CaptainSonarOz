functor
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
define
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

%%%% Style of game %%%%
   
   IsTurnByTurn = true

%%%% Description of the map %%%%
   
   NRow = 5
   NColumn = 5

   % Map = [[0 0 0]
   % 	  [0 0 0]
   %      [0 0 0]]

   Map = [[0 0 0 0 1]
	  [1 0 0 0 0]
	  [1 0 0 0 1]
	  [1 0 1 0 1]
	  [1 0 0 0 1]]
   
   % Map = [[1 0 0 0 0 0 0 0 0 0]
   % 	  [0 0 0 0 0 0 0 0 0 0]
   % 	  [0 0 0 1 1 0 0 0 0 0]
   % 	  [0 0 1 1 0 0 1 0 0 0]
   % 	  [0 0 0 0 0 0 0 0 0 0]
   % 	  [0 0 0 0 0 0 0 0 0 0]
   % 	  [0 0 0 1 0 0 1 1 0 0]
   % 	  [0 0 1 1 0 0 1 0 0 0]
   % 	  [0 0 0 0 0 0 0 0 0 0]
   % 	  [0 0 0 0 0 0 0 0 0 0]]

%%%% Players description %%%%
   
   NbPlayer = 4
   Players = [basicAI basicAI basicAI basicAI]
   Colors = [green yellow red blue]

%%%% Thinking parameters (only in simultaneous) %%%%
   
   ThinkMin = 500
   ThinkMax = 3000

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