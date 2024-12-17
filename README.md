# Introduction
Hello! if you popped here, chances are, you want to create your own custom flags or another flag mutator you are using depends on this! If not, then wtf are you doing here, otherwise, carry on!

This is a heavily modified version of the [custom flag framework](https://steamcommunity.com/sharedfiles/filedetails/?id=2797568530) by Red for creating custom flags in Ravenfield. Heavy thanks to them for making the original :)

# Modifications from the Original
- This by itself does not come with any flags. You need to install this + a flag mutator which utilizes this framework. Some flag mutators are [Pride Flags](https://steamcommunity.com/sharedfiles/filedetails/?id=3385314817) or [Political Flags](https://steamcommunity.com/sharedfiles/filedetails/?id=3385314194).
  - When making your custom flag mutators using this framework, they will have to depend on this framework. This makes it easier to mass fix bugs across all flag mutators and allows for seamless compatibility 
- Much more performance friendly than the original and other flag mutators (100-200 FPS average compared to usual 200-250 FPS average on my computer)
- Custom flags now show during capture

# Customizability
- If you want to mix & match flag mutators that use this framework, you can do that!
- You can have multiple flag materials for a team in one round! For example, Eagle could have two flag materials assigned to it, say Germany and Russia, that would mean that when capturing a flag, there is a random chance that either Germany or Russia will pop up as the flag.
- Randomize a count of flag materials for a team. If you don't want to select the materials yourself, you can instead set a number for the amount of random flag materials the framework will assign to the specified team!
- Customize the color of a flag. This works for both vanilla flags and custom flags.
- Automatically change a team's name to the name of its specified flag material. If you have multiple flag materials, it will use the first given flag's name with an additional "ALLIES" text.
- Automatically change a team's color depending on the specified flag material. This is not to be confused with the flag's color. Authors of the mutators set this manually based on what they think best fits the flag. If you want to set colors manually, use "Team Config." If there are multiple flag materials for a team, the first one will be used for the team. 

# FAQ
### I found a bug/I wanna suggest a new idea!

- Tell us [here](https://github.com/MianReplicate/Mian-Custom-Flags-Framework/issues)!

### How to create my own flag mutators?

Step 1. Download a unity.package file from one of my template. [Pride Flags](https://github.com/MianReplicate/Pride-Flags) or [Political Flags](https://github.com/MianReplicate/Political-Flags) will work. Then import it into your Unity project (Must have RFTools for obvious reasons)

Step 2. Get an image (1024x512 recommended), and place it inside the Flag Textures folder. Delete any textures that are not needed.

Step 3. Create a new material in the Flag Materials folder. You can copy one of the default ones in there as a template. Afterwards, sure to replace the material's texture with your new image. Be sure to be consistent with material names since these are used for team names. Remove any unneeded materials. Repeat for additional flag images.

Step 4. Click the prefab file (blue square lookin' file) and add a new material in the "Material" dropdown list within the "Data Container" section. Set the value to your material. Ensure the ids are named in order with "Flag" preceding the number. Do the same thing for the "Color" dropdown list and put in a color that best fits the material or flag. Repeat for additional flag materials.

Step 5. Then add a new element under "Mutators" to the dropdowns for "AvailableFlags." Name this the SAME as your flag material's name. Players will be using these names to type in to the framework's config to select the flag. Repeat for additional flag materials.

Step 6. Rename the mutator and change the description to your liking. Replace the cover with whatever you want too.

Step 7. Rename the prefab file itself so it is unique. Also rename the script txt file (not the README) to the same thing. Then open the txt file and replace all instances of the txt file's old name to the new name you set. This is required since the framework keeps track of what mutators add what flags.

Step 8. Test out your mutator to see if it all works. Since this mutator is dependent on this framework, we'll have to test it with the framework installed. Thus, we'll first export the mutator by pressing Ctrl + E while the prefab is selected. Afterwards, start Ravenfield through Steam. If you have too many addons to where it becomes tedius to start up Ravenfield constantly, Steam allows you to disable your addons via the properties menu in the "Workshop" tab for the game. Disable all addons if you have to but make sure the framework is enabled. Make sure to also enable the framework mutator in-game.

Step 9. After confirming the mutator works fine, publish to Steam Workshop, and make sure you make this framework a dependency!

Step 10. You are pretty much done. Good job for making a flag mutator :). If you have any bugs, issues or questions, let me know via my [discord server](https://discord.gg/2h3pkECbdn) or the issues tracker here!