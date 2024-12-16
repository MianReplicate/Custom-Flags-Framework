# Introduction
Hello! if you popped here, chances are, you want to create your own custom flags or another flag mutator you are using depends on this! If not, then wtf are you doing here, otherwise, carry on!

This is a heavily modified version of the [custom flag framework](https://steamcommunity.com/sharedfiles/filedetails/?id=2797568530) by Red for creating custom flags in Ravenfield. Heavy thanks to them for making the original :)

# Modifications from the Original
- This by itself does not come with any flags. Only the options to change flag colors for both vanilla & other flag mutators. You need to install this + a flag mutator which utilizes this framework. Some flag mutators are [Pride Flags](https://steamcommunity.com/sharedfiles/filedetails/?id=3385314817) or [Political Flags](https://steamcommunity.com/sharedfiles/filedetails/?id=3385314194).
- Performance loss is negligible (If there are still fps drops with this mutator enabled, let me know!)
- Custom flags now show during capture
- Added a default fallback for when a flag material for a team isn't detected
  - This allowed me to create the additional "DISABLED" flag option which lets players disable custom flags for each team
- Works amazingly with multiple flag mutators using this framework. If you want to mix & match, you can do that!

# FAQ
### I found a bug using a flag mutator dependent on this framework

- Report it [here](https://github.com/MianReplicate/Mian-Custom-Flags-Framework/issues). There is a good chance this framework is bugging rather than the mutator itself.

### How to create my own flag mutators?

Step 1. Download a unity.package file from one of my template. [Pride Flags](https://github.com/MianReplicate/Pride-Flags) or [Political Flags](https://github.com/MianReplicate/Political-Flags) will work. Then import it into your Unity project (Must have RFTools for obvious reasons)

Step 2. Get a 1024x512 image, and place it inside the Flag Textures folder. Delete any textures that are not needed.

Step 3. Create a new material in the Flag Materials folder. You can just copy one of the default ones in there and remove the others. Afterwards, sure to replace the material's texture with your new image.

Step 4. Click the "Political Flags.prefab" and add a new material in the "Material" dropdown list within the "Data Container" section. Set the value to your material. Ensure the ids are named in order with "Flag" preceding the number.

Step 5. Then add a new element under "Mutators" to the dropdowns for both "EagleFlag" and "RavenFlag" (Or only one if you'd prefer). These elements are connected respective to the order of the materials in the "Data Container" section. As such, the names of the elements DO not matter, only their place in the list. E.g., the "DISABLED" option is the first element, as such it is connected to "Flag1" from "Data Container".

Step 6. Rename the mutator and change the description to your liking. Replace the cover with whatever you want too.

Step 7. Rename the prefab file itself so it is not "Political Flags." Preferably also rename the txt file next to it to something similar. Then open the txt file and replace all instances of the txt file's old name to the new name you set. This will make debugging easier in the future and helps separate your flag mutator from others.

Step 8. Test out your mutator to see if it all works. Since this mutator is dependent on this framework, we'll have to test it with the framework installed. Thus, we'll first export the mutator by pressing Ctrl + E while the prefab is selected. Afterwards, start Ravenfield through Steam. If you have too many addons to where it becomes tedius to start up Ravenfield constantly, Steam allows you to disable your addons via the properties menu in the "Workshop" tab for the game. Disable all addons if you have to but make sure the framework is enabled. When the game is finished loading, make sure to enable the framework before you enable your mutator. Otherwise the load order will not be correct and your mutator will error since it will not be able to find the framework!

Step 9. After confirming the mutator works fine, publish to Steam Workshop, and make sure you make this framework a dependency!

Step 10. You are pretty much done. Good job for making a flag mutator :). If you have any bugs, issues or questions, let me know via my [discord server](https://discord.gg/2h3pkECbdn) or the issues tracker here!