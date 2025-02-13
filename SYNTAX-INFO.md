# Terminology (IMPORTANT)
1. Meshes ARE accessories. If I mention meshes, I really mean accessories.
2. When I say "data", I am talking about both FLAGS and MESHES/ACCESSORIES.

# How to Add Flags/Meshes to Teams

If you are adding flags, first start up the "Flag Viewer" map. Then press A once you've loaded in. Afterwards, read the following instructions.

If you are adding meshes, please learn how to add flags already if you haven't. This will be important because you will have to learn how to use commands to add meshes in this next part. If you are too lazy to learn, read the paragraph below this. Otherwise start up the "Flag Viewer" map and find your meshes. Then follow "Assigning by Commands" and learn the command syntax. Afterwards, read up on the "ACCESSORY" command in "More Information on Commands". You will be using this command within the "ACCESSORY" output to assign accessories to flags.

If you are too lazy to learn how to assign meshes properly, copy the following line WITHOUT the quotation marks in your ACCESSORIES output. This will make it so all your accessories are assigned to every flag you have installed in the game. "{ACCESSORY:{ALL:{ALLMUTATORS:FLAGS}}:{ALL:{ALLMUTATORS:MESHES}}}"

## Assigning by Name
Search for the data you want and click it. This will add it to your output to the top. Once you've finished configuring, copy your output. Then leave the game, go to the CONFIGURATION menu for the framework mutator, and paste your output into either Eagle or Raven. Meshes go in accessory outputs and flags go in flag outputs.

Keep in mind that you can add MULTIPLE flags to a team. Bots are randomly assigned flags to them upon spawning in. The capture points they capture will have its flag texture changed to whatever the bot's assigned flag is.

<img src="https://i.imgur.com/czXAVYu.png"> 

This assigns Belgium and Brazil to the team with this config.

## Assigning by Commands (OPTIONAL, ADVANCED)
**WARNING: This sort of configuration is advanced and you might get lost. This is not required to learn. However it CAN be super useful if you are a person looking to create some interesting configurations.**

So what are commands all about? Well, to begin with, they can let you RANDOMIZE the datas that you have for a team. They also let you override the team colors/names set up for a flag material. You could also use them to grab every single data from a pack that you have! Yes, that means you would NOT have to add every single data manually from a pack separated by commas IF you wanted every single data.

If the above has enticed you, then you are in the right spot! If not, you can back away from this configuration method. Otherwise, carry on.

To begin using a command, you want to press the one you want on the left. For the example I will be showing, I'll be getting every single flag from a pack and assigning it to one team.

To start with, press the "ALL" button. Notice how the command looks in the output? Commands start and end with brackets. This is how the framework knows you are using a command. You might also notice that first word in the brackets is "ALL." This tells the framework you are trying to use the "ALL" command. 

Additionally you'll notice there is a colon. The colon is there to separate what is known as ARGUMENTS. ARGUMENTS are information that is sent over to the command to tell it more on what to do and how to operate. In this case, the "ALL" command needs a list of mutators. Highlight the text after the colon and delete up **until** the end bracket. Then make sure your pointer (the blinking cursor) is located right after the colon. This matters because this tells the framework EXACTLY where to spawn your text at.

Next, you want to press the MUTATORS button at the top to swap over to a list of mutators. Afterwards, press on any mutator you want. Finally, you'll notice that the mutator ID is spawned where your cursor was.

<img src="https://i.imgur.com/LE9Q4Re.png">

Congralutations! You've successfully completed your first command. This will add all the flags from the flag pack to a select team. Note that every argument is treated as a list so you can add as MANY of a specific datatype as you want into an argument. E.g. since ALL takes a MUTATOR input, you can add MULTIPLE mutators and ALL will grab the flags from ALL of them. Here's a visualization of what this might look like:

Assigning by Name: "Russia,Germany,USA,UK,Turkey,North Korea,South Korea"
Assigning by Command: {ALL:MIANPOLITICALFLAGS} -> OUTPUTS "Russia,Germany,USA,UK,Turkey,North Korea,South Korea"

See how much easier it is to add in all your flags because of the "ALL" command?

You can also use commands within commands. Here's an example: {ALL:{ALLMUTATORS:Flags}}
This command adds ALL flags from ALL of the flag packs that are installed. Note how there are more brackets within the "ALL" command. This is to indicate the next command which will then have its own set of arguments you need to define. In this case, we call "ALLMUTATORS:Flags" which outputs every single flag pack installed, then it passes it to the "ALL" command which then uses all those flag packs to then output every single flag from those flag packs. Here's a visualization:

{ALL:{ALLMUTATORS:Flags}} -> {ALL:MIANPOLITICALFLAGS,MIANPRIDEFLAGS,EXAMPLEPACK2,EXAMPLEPACK3}

Notice how this command simplified the entire process and made it less tedious.

This is about it for the command structure. If you want to learn the rest of commands (which I recommend) or want more examples, you can see below in "More Information on Commands:" and "Example Configs"

### More Information On Commands:
```
-- The below are commands that can be run in ANY output

LIST = "LIST:ADD_OR_GET:ADD_NAMES_HERE"
Can be used to add or get a user-defined list filled with names
Example: {LIST:ADD:Super Powers:Russia,UK,US} -- Adds a user-defined list named "Super Powers" which includes Russia, UK, and the US
Example 2: {LIST:GET:Super Powers} -- Returns the list "Super Powers" which consists of Russia, UK, and the US

COUNT = "COUNT:SOME_LIST"
When given a list, COUNT will return how many values is in it.
Example: {COUNT:USA,Germany,Russia} -- Returns three because there are three in the list.
Example 2: {COUNT:{ALL:MIANPOLITICALFLAGS}} -- Returns the amount of flags within the Political Flags pack.
Example 3: {COUNT:{LIST:GET:Super Powers}} -- Returns three flags which are Russia, UK and the US because they are part of the "Super Powers" list

OPERATOR = "OPERATOR:OPERATION_TO_USE:A_NUMBER_TO_START:NUMBERS"
Returns a number modified by a certain operation and a list of numbers.
Example: {OPERATOR:ADD:2:5,10,13} -- Returns 30 because the starting number is 2, and the numbers to add onto 2 are 5, 10, and 13. This gives a sum of 30.

ALLMUTATORS = "ALLMUTATORS:FLAGS_OR_MESHES"
Returns all the mutator ids
Example: {ALLMUTATORS:FLAGS} -- Returns every single flag pack in a list. This could be used in the ALL command to retrieve every single flag from the given packs.
Example: {ALLMUTATORS:MESHES} -- Returns every single mesh pack in a list. This can be used in the ALL command to retrieve every single mesh from the given packs.

ALL = "ALL:MUTATOR_IDS"
Returns all the flags from select mutator(s)
Example: {ALL:MIANPOLITICALFLAGS} -- Returns all the flags from the Political Flags pack

RANDOMIZE = "RANDOMIZE:DATAS:A_NUMBER"
Gets a random specific number of data(s) from a given list.
Example: {RANDOMIZE:USA,Russia,Germany,UK:2} -- This would give me two random datas from the datas I chose: USA, Russia, Germany, UK.

PLAYER = "PLAYER:FLAGS_OR_MESHES:ADD_NAMES_HERE"
If you wanna be special, you can assign flags/accessories to yourself here. This is a separate list that is unique to you. Thus you will only get flags/accessories from this list and nobody else. If you wanted to be the only British person on your team, you could do that.
Example: {PLAYER:FLAGS:USA} -- Assigns the USA flag to the player actor
Example 2: {PLAYER:MESHES:Vest,Front Helmet} -- Assigns the vest and front helmet accessories to the player actor
Example 3: {PLAYER:FLAGS:Russia,Germany} -- Assigns the Russia and Germany flag to the player actor 

-- The below are commands ONLY for the accessories/meshes output
ACCESSORY = "ACCESSORY:FLAGS:MESHES"
Assigns accessories to a list of flag(s). This is required if you want to set up accessories in your game.
Example: {ACCESSORY:USA,Germany:Side Helmet,Front and Back} -- Assigns the Side Helmet and Front and Back accessories to the USA and Germany flag. Any actors that spawn with these flags assigned WILL be given these meshes.

-- The below are commands ONLY for the flag outputs.
TEAMNAME = "TEAMNAME:FLAGS:EXAMPLE_NAME",
Changes the team name for a list of flag(s)
Example: {TEAMNAME:USA:United States} -- This would change the USA flag's team name to the "United States" in game. Keep in mind, this DOES not add the flags to the team. This only changes its team name. If you want to add the flag, you need to add its name into the output as usual.

TEAMCOLOR = "TEAMCOLOR:FLAGS:255,255,255",
Changes the team color for a list of flag(s)
Example: {TEAMCOLOR:Russia,Britain:0,0,0} -- This would change the team colors for Russia and Britain to the black color. Keep in mind, this DOES not add the flags to the team. This only changes its team color. If you want to add the flag, you need to add its name into the output as usual.

FLAGCOLOR = "FLAGCOLOR:FLAGS:255,255,255"
Changes the flag color for a list of flag(s)
Example: {FLAGCOLOR:Britain:255,255,255} -- This would make the United Kingdoms flag extremely white. Keep in mind, this DOES not add the flags to the team. This only changes its flag color. If you want to add the flag, you need to add its name into the output as usual.


More commands may be added in the future! If you want have a command suggestion, reach out and I may add it!
```
## Example Configs
```
-- In the FLAGS output
Example 1: RUSSIA,Germany,USA,UK
This assigns Russia, Germany, USA, and the UK flags.

Example 2: RUSSIA,{TEAMCOLOR:{ALL:{ALLMUTATORS:FLAGS}}:255,0,0}
This assigns RUSSIA to the team and changes colors of all team colors for every flag to RED.

Example 3: {RANDOMIZE:{ALL:{ALLMUTATORS:FLAGS}}:20}
This assigns 20 random flags from all installed flag packs.

Example 4: BRAZIL,CANADA,{ALL:MIANPOLITICALFLAGS}
This assigns Brazil, Canada and then ALL the flags from the Political Flags pack afterwards.

EXAMPLE 5: {RANDOMIZE:{ALL:MIANPRIDEFLAGS}:{OPERATOR:DIVIDE:{COUNT:{ALL:MIANPRIDEFLAGS}}:2}}
This randomizes HALF of the flags within the MIANPRIDEFLAGS flag pack.

-- In the ACCESSORIES output
EXAMPLE 6: {ACCESSORY:{ALL:{ALLMUTATORS:FLAGS}}:{ALL:{ALLMUTATORS:MESHES}}}
This assigns ALL accessories you have installed to ALL flags you have installed

EXAMPLE 7: {ACCESSORY:{ALL:{ALLMUTATORS:FLAGS}}:{RANDOMIZE:{ALL:{ALLMUTATORS:MESHES}}:10}}
This assigns 10 RANDOM ACCESSORIES out of ALL accessories you have installed to ALL flags you have installed

```
## Some Tips
Nothing is case-sensitive. Do not worry about capitalization whatsoever.

You can add multiple datas and commands to any team as long as they are separated by commas.

The order of the output matters! If you want the framework to use a color and name from a specified flag for your team, that FLAG must be typed first in the configuration!

ACCESSORIES can only be added to flags in the ACCESSORIES output
FLAGS can only be added to teams in the FLAG outputs

**THE FOLLOWING PARAGRAPHS DO NOT APPLY FOR MESHES:** If using commands, it is important to note that the framework deliberately avoids adding in flags already assigned to a team for each command. For example, if you use the ALL command to add all flags to one team, and then use it on the other team, you will find that the other team WILL not have the flags given BECAUSE the other team already has those flags. This is to avoid giving teams the same flags in order to prevent players from getting confused on what team owns a capture point.

There is an option to choose whether EAGLE or RAVEN is assigned first in the CONFIGURATION menu. This likely matters to you if you use commands because of the given tip above (this doesn't matter for meshes). You can also choose if the framework should randomly decide for you if you are crazy like that.
