# Syntax/How to add flags to teams
Here is some information to note before adding flags to your teams

Everything is separated by commas! You'll see an example at the end of this category if you do not know what I mean.

The syntax is NOT case sensitive! It will not matter whether you capitalize a word or not in any shape or form.

The order of the list matters! If you want the framework to use a color and name from a certain flag material for your team, that FLAG must be typed first!

Make sure the flag mutators you want to use are ENABLED! You can confirm this by using the "Flag Viewer" map.

Use the "Flag Viewer" map if you do not know the name/id of a flag or mutator!

## Assigning by name
When assigning a flag to a team, type in its name/id. Make sure to not have spaces in places that are unneeded.

**Example**

Eagle Flag(s): USA,UK,germany,rUssiA -- This will assign USA, UK, Germany, and Russia flags to the Eagle team! Since USA is first, it will be used for determining team color and name if the option is enabled.

## Assigning via commands
To tell the framework you are going to use a command, start your string with a "{" and end it with a "}" when finished writing it.

In order for the framework to know what command you want to use, you have to write its name. In this case, we can use the command "MUTATOR", This command will let you mass add flags from a mutator or randomize them.

Then, you need to write any parameters after the command that it may need, separated with a ":" in between each. In this example, "MUTATOR" needs a mutator id, a decision of what to do with that mutator, and an additional parameter that changes depending on what you are doing with the mutator.

**Example**

Eagle Flags(s): {MUTATOR:MIANPOLITICALFLAGS:RANDOMIZE:10} -- This will get 10 random flags from the Political Flags mutator and assign them randomly in your list

Eagle Flags(s): {MUTATOR:MIANPOLITICALFLAGS:ALL} -- This will get ALL flags from the Political Flags Mutator


### Commands List:

**MUTATOR** (mutatorid,decision,amount)

*mutatorid*: The id of the mutator

*decision*: RANDOMIZE or ALL or FIRST or LAST. RANDOMIZE will randomize an amount of flags from the mutator and assign them to the team. ALL will assign all flags to the team. FIRST will assign an amount of flags from the beginning of the mutator's flag list. LAST is the same but from the ending.

*amount*: If using RANDOMIZE, FIRST, or LAST, this will determine the amount that they use.

## Using commands and names to add flags
Like before, all you need to do is use commas to separate names and commands when assigning flags!

**Example**

Eagle Flag(s): USA,Russia,{MUTATOR:MIANPRIDEFLAGS:RANDOMIZE:2} -- This assigns USA and Russia to Eagle first, and then gets two random flags from the Pride Flags mutator.

Eagle Flag(s): {MUTATOR:MIANPRIDEFLAGS:RANDOMIZE:5},GERMANY,UK -- This gets five random flags from the Pride Flags mutator, AND then assigns Germany, and UK afterwards to the team.

Eagle Flag(s): {MUTATOR:MIANPOLTICALFLAGS:RANDOMIZE:2},{MUTATOR:MIANPRIDEFLAGS:ALL} -- This gets two random flags from the Political Flags mutator and then gets all the flags from the Pride Flags mutator.