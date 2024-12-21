# Introduction
Hello! if you popped here, chances are, you want to create your own custom flags or another flag mutator you are using depends on this! If not, then wtf are you doing here, otherwise, carry on!

This is a heavily modified version of the [custom flag framework](https://steamcommunity.com/sharedfiles/filedetails/?id=2797568530) by Red for creating custom flags in Ravenfield. Heavy thanks to them for making the original :)

# Modifications from the Original
- This by itself does not come with any flags. You need to install this + a flag mutator which utilizes this framework. Some flag mutators are [Pride Flags](https://steamcommunity.com/sharedfiles/filedetails/?id=3385314817) or [Political Flags](https://steamcommunity.com/sharedfiles/filedetails/?id=3385314194).
  - When making your custom flag mutators using this framework, they will have to depend on this framework. This makes it easier to mass fix bugs across all flag mutators and allows for seamless compatibility 
- Much more performance friendly than the original and other flag mutators (100-200 FPS average compared to usual 200-250 FPS average on my computer)
- Custom flags now show during capture
- Edit which team has what flags using custom syntax and flag ids in the mutator config! No having to go through different mutators to select what flag goes to where.
- You can view installed mutators and their added flags by using the new "Flag Viewer" map. This lets you view the id and name of each flag and mutator.

# Customizability
- If you want to mix & match flag materials from other mutators that use this framework, you can do that!
- You can have multiple flag materials for a team in one round! For example, Eagle could have two flag materials assigned to it, say Germany and Russia, that would mean that when capturing a flag, there is a random chance that either Germany or Russia will pop up as the flag.
- Randomize a count of flag materials for a team. If you don't want to select the materials yourself, you can instead set a number for the amount of random flag materials the framework will assign to the specified team!
- Customize the color of a flag texture.
- Automatically change a team's name to the name of its specified flag material. If you have multiple flag materials, it will use the first given flag's name with an additional "ALLIES" text.
- Automatically change a team's color depending on the specified flag material. This is not to be confused with the flag's color. Authors of the mutators set this manually based on what they think best fits the flag. If you want to set colors manually, use "Team Config." If there are multiple flag materials for a team, the first one will be used for the team.

# Syntax/How to add flags to teams
- Find more information here on the [SYNTAX INFO](https://github.com/MianReplicate/Mian-Custom-Flags-Framework/blob/main/SYNTAX-INFO.md)

# FAQ
### I found a bug/I wanna suggest a new idea!

- Tell us [here](https://github.com/MianReplicate/Mian-Custom-Flags-Framework/issues)!

### How to create my own flag mutators?

<<<<<<< HEAD
- Find more information here on the [TEMPLATE INFO](https://github.com/MianReplicate/Mian-Custom-Flags-Framework/blob/main/TEMPLATE-INFO.md)
=======
Step 1. Download a unity.package file from one of my template. [Pride Flags](https://github.com/MianReplicate/Pride-Flags) or [Political Flags](https://github.com/MianReplicate/Political-Flags) will work. Then import it into your Unity project (Must have RFTools for obvious reasons)

Step 2. Get an image (1024x512 recommended), and place it inside the Textures folder. Delete any textures that are not needed. Name these short, unique and consistent. Their names will be displayed to users to assign to teams. Avoid common names as the framework will not accept multiple textures that have the same names. This applies across other mutators as well.

Step 3. Click the prefab file (blue square lookin' file), and add a new texture in the "Texture" dropdown list within the "Data Container" section. Set the value to your texture. Ensure the ids are named in order with "Flag" preceding the number. Do the same thing for the "Color" dropdown list and assign a color to each specific flag. Use the color picker to grab a color from the flag or choose a color you think best fits. The colors are an optional addition, but I recommend them so each flag has a color that the team color scheme can be set to.

Step 4. Rename the mutator, change the description, and replace the cover. Make sure to also replace the cover in the "Textures" dropdown in the "Data Container" section with yours.

Step 5. Give the prefab file to a unique name. Also change the name of the lua file to the same name. Then open the lua file and replace all instances of the file's old name to the new name you set. This is required since the framework keeps track of what mutators add what flags.

Step 6. Test out your mutator to see if it all works. Export the mutator by pressing Ctrl + E while the prefab is selected. Afterwards, start Ravenfield through Steam. If you have too many addons to where it becomes tedius to start up Ravenfield constantly, Steam allows you to disable your addons via the properties menu in the "Workshop" tab for the game. Then run the custom map "Flag Viewer" to see if your mutator pops up.

Step 7. After confirming the mutator works fine, publish to Steam Workshop, and make sure you make this framework a dependency! If your mutator does not work fine, open the console (PGUP button) to see what the logs say. Usually you will get an error alongside a reason which tells you what you did wrong. If not, join the discord below.

Step 8. You are pretty much done. Good job for making a flag mutator :). If you have any bugs, issues or questions, let me know via my [discord server](https://discord.gg/2h3pkECbdn) or the issues tracker here!
>>>>>>> fafa4def23784b6e075c320fa9bd431227be3e68
