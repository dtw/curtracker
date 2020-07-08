Currency Tracker

This was the first ffxi lua I wrote years ago, decided to do a small update to it and release it.
I'll add some more options later to bring it up to current standards.

After you load the lua for the first time just edit the settings.xml from /data and reload the lua 
to have your new fields displayed.  Curlines dictates how many fields you would like per line on your box.

	** Commands **
  	//curt on|off
	//curt add <search term>
  	//curt del <search term>
    //curt field_color <red> <green> <blue>
    //curt value_color <red> <green> <blue>
    //curt size <text size>
    //curt refresh <Seconds to refresh currencies>
    //curt alpha <background transparency> 0-255

 ex.   //curt add Snowdim 

Returns that this matched multiple results
		 
 ex.   //curt add Snowdim 2

Will add just one item.

 ex.   //curt add Snowdim *

Adds multiple entries matching Snowdim

 ** Version History **
 
 
v1.0 - Rewrote the saving and loading of currency types to just use whatever is found
       in the packets library so no updates are needed.
       
v0.4 - Add commands to disable refresh, search and change fields from addon command

v0.3 - Add all fields to a table which can just be enabled/disabled through settings.xml

v0.2 - Fix Windower fields.lua to correct Unity Accolades memory location

v0.1 - Initial Test Release
