functor
import
   QTk at 'x-oz://system/wp/QTk.ozf'
   Input
   Browser
	OS
export
   portWindow:StartWindow
define

   StartWindow
   TreatStream
   Browse = Browser.browse
   RemoveItem
   RemovePath
   RemovePlayer

   Map = Input.map

   NRow = Input.nRow
   NColumn = Input.nColumn


   DrawSubmarine
   MoveSubmarine
   DrawMine
   RemoveMine
   DrawExplosion
   RemoveExplosion
   DrawPath

   BuildWindow

   Label
   Squares
   DrawMap

   StateModification

   UpdateLife

   FontPath

   SubmarineImg
	SubmarineBrokenImg
   WaterImg
   MineImg
   TerreImg
   ExplosionImg1
   ExplosionImg2
   ExplosionImg3
   ExplosionImg4
   ExplosionImg5
   ExplosionImg6
   ExplosionImg7
   ExplosionImg8
   ExplosionImg9
   ExplosionImg10

   Play
   W
   H
in
   W=65
   H=65
   SubmarineImg = {QTk.newImage photo(file:'img/submarine.gif' width:W height:H format:gif)}
   SubmarineBrokenImg = {QTk.newImage photo(file:'img/submarinebroken.gif' width:W height:H format:gif)}
   WaterImg = {QTk.newImage photo(file:'img/mer.gif' width:W height:H format:gif)}
   TerreImg = {QTk.newImage photo(file:'img/sol.gif' width:W height:H format:gif)}
   MineImg = {QTk.newImage photo(file:'img/mine2.gif' width:W height:H format:gif)}
   ExplosionImg1 = {QTk.newImage photo(file:'img/explosion1.gif' width:W height:H format:gif)}
   ExplosionImg2 = {QTk.newImage photo(file:'img/explosion2.gif' width:W height:H format:gif)}
   ExplosionImg3 = {QTk.newImage photo(file:'img/explosion3.gif' width:W height:H format:gif)}
   ExplosionImg4 = {QTk.newImage photo(file:'img/explosion4.gif' width:W height:H format:gif)}
   ExplosionImg5 = {QTk.newImage photo(file:'img/explosion5.gif' width:W height:H format:gif)}
   ExplosionImg6 = {QTk.newImage photo(file:'img/explosion6.gif' width:W height:H format:gif)}
   ExplosionImg7 = {QTk.newImage photo(file:'img/explosion7.gif' width:W height:H format:gif)}
   ExplosionImg8 = {QTk.newImage photo(file:'img/explosion8.gif' width:W height:H format:gif)}
   ExplosionImg9 = {QTk.newImage photo(file:'img/explosion9.gif' width:W height:H format:gif)}
   ExplosionImg10 = {QTk.newImage photo(file:'img/explosion10.gif' width:W height:H format:gif)}
   FontPath = {QTk.newFont font(size:4)}

%%%%% Build the initial window and set it up (call only once)
   fun{BuildWindow}
      Grid GridScore Toolbar Desc DescScore Window
   in
      Toolbar=lr(glue:we tbbutton(text:"Quit" glue:w action:toplevel#close))
      Desc=grid(handle:Grid height:((NRow+1)*H) width:((NColumn+1)*W))
      DescScore=grid(handle:GridScore height:100 width:500)
      Window={QTk.build td(Toolbar Desc DescScore)}

      {Window show}

      % configure rows and set headers
      {Grid rowconfigure(1 minsize:H weight:0 pad:0)}
      for N in 1..NRow do
	 {Grid rowconfigure(N+1 minsize:H weight:0 pad:0)}
	 {Grid configure({Label N} row:N+1 column:1 sticky:wesn)}
      end
      % configure columns and set headers
      {Grid columnconfigure(1 minsize:W weight:0 pad:0)}
      for N in 1..NColumn do
	 {Grid columnconfigure(N+1 minsize:W weight:0 pad:0)}
	 {Grid configure({Label N} row:1 column:N+1 sticky:wesn)}
      end
      % configure scoreboard
      {GridScore rowconfigure(1 minsize:50 weight:0 pad:5)}
      for N in 1..(Input.nbPlayer) do
	 {GridScore columnconfigure(N minsize:50 weight:0 pad:5)}
      end

      {DrawMap Grid}

      handle(grid:Grid score:GridScore)
   end


%%%%% Squares of water and island
   Squares = square(0:label(width:1 height:1 image:WaterImg)
		    1:label(width:1 height:1 relief:raised borderwidth:5 image:TerreImg bg:c(76 43 24))
		   )

%%%%% Labels for rows and columns
   fun{Label V}
      label(text:V borderwidth:5 relief:raised bg:c(24 83 178) ipadx:0 ipady:0)
   end

%%%%% Function to draw the map
   proc{DrawMap Grid}
      proc{DrawColumn Column M N}
	 case Column
	 of nil then skip
	 [] T|End then
	    {Grid configure(Squares.T row:M+1 column:N+1 sticky:wesn)}
	    {DrawColumn End M N+1}
	 end
      end
      proc{DrawRow Row M}
	 case Row
	 of nil then skip
	 [] T|End then
	    {DrawColumn T M 1}
	    {DrawRow End M+1}
	 end
      end
   in
      {DrawRow Map 1}
   end

%%%%% Init the submarine
   fun{DrawSubmarine Grid ID Position}
      Handle HandlePath HandleScore X Y Id Color LabelSub LabelScore
   in
      pt(x:X y:Y) = Position
      id(id:Id color:Color name:_) = ID

      LabelSub = label(handle:Handle width:1 height:1 image:SubmarineImg bg:Color)

      LabelScore = label(text:Input.maxDamage borderwidth:5 handle:HandleScore relief:solid bg:Color ipadx:5 ipady:5)
      HandlePath = {DrawPath Grid Color X Y}
      {Grid.grid configure(LabelSub row:X+1 column:Y+1 sticky:wesn)}
      {Grid.score configure(LabelScore row:1 column:Id sticky:wesn)}
      {HandlePath 'raise'()}
      {Handle 'raise'()}
      guiPlayer(id:ID score:HandleScore submarine:Handle mines:nil path:HandlePath|nil)
   end


   fun{MoveSubmarine Position}
      fun{$ Grid State}
	 ID HandleScore Handle Mine Path NewPath X Y
      in
	 guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path) = State
	 pt(x:X y:Y) = Position
	 NewPath = {DrawPath Grid ID.color X Y}
	 {Grid.grid remove(Handle)}
	 {Grid.grid configure(Handle row:X+1 column:Y+1 sticky:wesn)}
	 {NewPath 'raise'()}
	 {Handle 'raise'()}
	 guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:NewPath|Path)
      end
   end

   fun{DrawMine Position}
      fun{$ Grid State}
	 ID HandleScore Handle Mine Path LabelMine HandleMine X Y
      in
	 guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path) = State
	 pt(x:X y:Y) = Position
	 LabelMine = label(handle:HandleMine width:60 height:60 bg:ID.color image:MineImg)
	 {Grid.grid configure(LabelMine row:X+1 column:Y+1)}
	 {HandleMine 'raise'()}
	 {Handle 'raise'()}
	 guiPlayer(id:ID score:HandleScore submarine:Handle mines:mine(HandleMine Position)|Mine path:Path)
      end
   end

   local
      fun{RmMine Grid Position List}
	 case List
	 of nil then nil
	 [] H|T then
	    if (H.2 == Position) then
	       {RemoveItem Grid H.1}
	       T
	    else
	       H|{RmMine Grid Position T}
	    end
	 end
      end
   in
      fun{RemoveMine Position}
	 fun{$ Grid State}
	    ID HandleScore Handle Mine Path NewMine
	 in
	    guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path) = State
	    NewMine = {RmMine Grid Position Mine}
	    guiPlayer(id:ID score:HandleScore submarine:Handle mines:NewMine path:Path)
	 end
      end
   end

/*	proc{Play X}
		CommandMac = afplay
		CommandLinux = play
		Args
		Stdin Stdout Pid
		in
		
		case X of boom then Args = 'sound/boom.mp3'|nil
		[]drone then Args= 'sound/drone.mp3'|nil
		[]mine then Args = 'sound/sonar.mp3'|nil
		[]sonar then Args = 'sound/sonar.mp3'|nil
		[]endofgame then Args= 'sound/end.mp3'|nil
		[]start then Args = 'sound/start.mp3'|nil
		end


		{OS.pipe CommandMac Args Pid Stdin#Stdout}
		{OS.pipe CommandLinux Args Pid Stdin#Stdout}

	end
*/
   fun{DrawExplosion Position}
      fun{$ Grid State}
		
	 ID HandleScore Handle Mine Path LabelExplosion1 LabelExplosion2
   LabelExplosion3 LabelExplosion4 LabelExplosion5 LabelExplosion6
   LabelExplosion7 LabelExplosion8 LabelExplosion9 LabelExplosion10
   HandleExplosion1 HandleExplosion2 HandleExplosion3 HandleExplosion4
   HandleExplosion5 HandleExplosion6 HandleExplosion7 HandleExplosion8
   HandleExplosion9 HandleExplosion10 X Y
      in
		%{Play boom}
      guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path) = State
   	 pt(x:X y:Y) = Position
   	 LabelExplosion1 = label(handle:HandleExplosion1 width:60 height:60 image:ExplosionImg1 bg: c(46 110 145))
   	 {Grid.grid configure(LabelExplosion1 row:X+1 column:Y+1)}
   	 {HandleExplosion1 'raise'()}
   	 {Handle 'raise'()}
     {Delay 50}
     {Grid.grid forget(HandleExplosion1)}
     LabelExplosion2 = label(handle:HandleExplosion2 width:60 height:60 image:ExplosionImg2 bg: c(46 110 145))
   	 {Grid.grid configure(LabelExplosion2 row:X+1 column:Y+1)}
   	 {HandleExplosion2 'raise'()}
   	 {Handle 'raise'()}
     {Delay 50}
     {Grid.grid forget(HandleExplosion2)}
     LabelExplosion3 = label(handle:HandleExplosion3 width:60 height:60 image:ExplosionImg3 bg: c(46 110 145))
   	 {Grid.grid configure(LabelExplosion3 row:X+1 column:Y+1)}
   	 {HandleExplosion3 'raise'()}
   	 {Handle 'raise'()}
     {Delay 50}
     {Grid.grid forget(HandleExplosion3)}
     LabelExplosion4 = label(handle:HandleExplosion4 width:60 height:60 image:ExplosionImg4 bg: c(46 110 145))
   	 {Grid.grid configure(LabelExplosion4 row:X+1 column:Y+1)}
   	 {HandleExplosion4 'raise'()}
   	 {Handle 'raise'()}
     {Delay 50}
     {Grid.grid forget(HandleExplosion4)}
     LabelExplosion5 = label(handle:HandleExplosion5 width:60 height:60 image:ExplosionImg5 bg: c(46 110 145))
   	 {Grid.grid configure(LabelExplosion5 row:X+1 column:Y+1)}
   	 {HandleExplosion5 'raise'()}
   	 {Handle 'raise'()}
     {Delay 50}
     {Grid.grid forget(HandleExplosion5)}
     LabelExplosion6 = label(handle:HandleExplosion6 width:60 height:60 image:ExplosionImg6 bg: c(46 110 145))
   	 {Grid.grid configure(LabelExplosion6 row:X+1 column:Y+1)}
   	 {HandleExplosion6 'raise'()}
   	 {Handle 'raise'()}
     {Delay 50}
     {Grid.grid forget(HandleExplosion6)}
     LabelExplosion7 = label(handle:HandleExplosion7 width:60 height:60 image:ExplosionImg7 bg: c(46 110 145))
   	 {Grid.grid configure(LabelExplosion7 row:X+1 column:Y+1)}
   	 {HandleExplosion7 'raise'()}
   	 {Handle 'raise'()}
     {Delay 50}
     {Grid.grid forget(HandleExplosion7)}
     LabelExplosion8 = label(handle:HandleExplosion8 width:60 height:60 image:ExplosionImg8 bg: c(46 110 145))
   	 {Grid.grid configure(LabelExplosion8 row:X+1 column:Y+1)}
   	 {HandleExplosion8 'raise'()}
   	 {Handle 'raise'()}
     {Delay 50}
     {Grid.grid forget(HandleExplosion8)}
     LabelExplosion9 = label(handle:HandleExplosion9 width:60 height:60 image:ExplosionImg9 bg: c(46 110 145))
   	 {Grid.grid configure(LabelExplosion9 row:X+1 column:Y+1)}
   	 {HandleExplosion9 'raise'()}
   	 {Handle 'raise'()}
     {Delay 50}
     {Grid.grid forget(HandleExplosion9)}
     LabelExplosion10 = label(handle:HandleExplosion10 width:60 height:60 image:ExplosionImg10 bg: c(46 110 145))
   	 {Grid.grid configure(LabelExplosion10 row:X+1 column:Y+1)}
   	 {HandleExplosion10 'raise'()}
   	 {Handle 'raise'()}
     {Delay 50}
     {Grid.grid forget(HandleExplosion10)}
   	 guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path)

         end
      end




   fun{DrawPath Grid Color X Y}
      Handle LabelPath
   in
      LabelPath = label(text:" " font:FontPath handle:Handle bg:Color)
      {Grid.grid configure(LabelPath row:X+1 column:Y+1)}
      Handle
   end

   proc{RemoveItem Grid Handle}
      {Grid.grid forget(Handle)}
   end


   fun{RemovePath Grid State}
      ID HandleScore Handle Mine Path
   in
      guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path) = State
      for H in Path.2 do
	 {RemoveItem Grid H}
      end
      guiPlayer(id:ID score:HandleScore submarine:Handle mines:Mine path:Path.1|nil)
   end

   fun{UpdateLife Life}
      fun{$ Grid State}
	 HandleScore
      in
	 guiPlayer(id:_ score:HandleScore submarine:_ mines:_ path:_) = State
	 {HandleScore set(Life)}
	 State
      end
   end


   fun{StateModification Grid WantedID State Fun}
      case State
      of nil then nil
      [] guiPlayer(id:ID score:_ submarine:_ mines:_ path:_)|Next then
	 if (ID == WantedID) then
	    {Fun Grid State.1}|Next
	 else
	    State.1|{StateModification Grid WantedID Next Fun}
	 end
      end
   end


   fun{RemovePlayer Grid WantedID State}
      case State
      of nil then nil
      [] guiPlayer(id:ID score:HandleScore submarine:Handle mines:M path:P)|Next then
	 if (ID.id == WantedID.id) then
		{Handle set(image:SubmarineBrokenImg)}
		{Handle 'raise'()}
		{Delay 1000}
	    {HandleScore set(0)}
	    {RemoveItem Grid Handle}
	    for H in P do
	       {RemoveItem Grid H}
	    end
	    for H in M do
	       {RemoveItem Grid H.1}
	    end
		
		

	    Next
	 else
	    State.1|{RemovePlayer Grid WantedID Next}
	 end
      end
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun{StartWindow}
      Stream
      Port
   in
      {NewPort Stream Port}
      thread
	 {TreatStream Stream nil nil}
      end
      Port
   end

   proc{TreatStream Stream Grid State}
      case Stream
      of nil then skip
      [] buildWindow|T then NewGrid in
	 NewGrid = {BuildWindow}
	 {TreatStream T NewGrid State}
      [] initPlayer(ID Position)|T then NewState in
	 NewState = {DrawSubmarine Grid ID Position}
	 {TreatStream T Grid NewState|State}
      [] movePlayer(ID Position)|T then
	 {TreatStream T Grid {StateModification Grid ID State {MoveSubmarine Position}}}
      [] lifeUpdate(ID Life)|T then
	 {TreatStream T Grid {StateModification Grid ID State {UpdateLife Life}}}
	 {TreatStream T Grid State}
      [] putMine(ID Position)|T then
	 {TreatStream T Grid {StateModification Grid ID State {DrawMine Position}}}
      [] removeMine(ID Position)|T then
	 {TreatStream T Grid {StateModification Grid ID State {RemoveMine Position}}}
      [] surface(ID)|T then
	 {TreatStream T Grid {StateModification Grid ID State RemovePath}}
      [] removePlayer(ID)|T then
	 {TreatStream T Grid {RemovePlayer Grid ID State}}
      [] explosion(ID Position)|T then
	 {TreatStream T Grid {StateModification Grid ID State {DrawExplosion Position}}}
      [] drone(ID Drone)|T then
	 {TreatStream T Grid State}
      [] sonar(ID)|T then
	 {TreatStream T Grid State}
      [] _|T then
	 {TreatStream T Grid State}
      end
   end

end
