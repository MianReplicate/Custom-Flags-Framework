Step 1. If you are completely new to Ravenfield modding, [follow this](https://ravenfieldgame.com/modding.html) to set up a Unity project and install RFTools. You do not need to follow this step if you already know how to mod Ravenfield or have a Unity project set up already.

Step 2. Download a unity.package file from one of my template. [Pride Flags](https://github.com/MianReplicate/Pride-Flags) or [Political Flags](https://github.com/MianReplicate/Political-Flags) will work. Then import it as a package into your Unity exactly how the RFTools package is imported.

Step 3. Get images for flags (1024x512 recommended), and place them inside the Textures folder. Delete any textures that are not needed. Name these short and consistent. Their names will be displayed to users to assign to flags.

Step 4. Click the prefab file (blue square lookin' file), and add a new texture in the "Texture" dropdown list within the "Data Container" section. Set the value to your texture. Ensure the ids are named in order with "Flag" preceding the number. Do the same thing for the "Color" dropdown list and assign a color to each specific flag. These colors determine team color which includes the actors and HUD. For example, if you assigned a red color to the Russian flag, then if a team had the Russian flag assigned to it, the actors would be red and the HUD for the team would be red colored as well. This does not change the color of the flag texture!

Step 5. Rename the mutator, change the description, and replace the cover. Make sure to also replace the cover in the "Textures" dropdown in the "Data Container" section with yours.

Step 6. Give the prefab file to a unique name. Also change the name of the lua file to the same name. Then open the file and replace all instances of the file's old name to the new name you set. This is required since the framework keeps track of what mutators add what flags.

Step 7. Test out your mutator to make sure it works. Export the mutator by pressing Ctrl + E while the prefab is selected. Afterwards, start Ravenfield through Steam. If you have too many addons to where it becomes tedius to start up Ravenfield constantly, you can disable your addons via the properties menu when right clicking the game in your library, and selecting the "Workshop" tab. Afterwards, run the custom map "Flag Viewer" to see if your mutator shows up. Make sure you have the Custom Flags Framework installed, otherwise you will not see the map (let alone even use your flag pack lol).

Step 8. If the mutator works fine, publish to Steam Workshop, and make sure you make this framework a dependency! If your mutator does not work fine/does not show up in the map, open the console (PGUP button) to see what the logs say. Usually you will get an error alongside a reason which tells you what you did wrong. If not, join the discord below OR ping me in the Ravenfield discord in the appropriate channel for further assistance. My username is "mianreplicate."

Step 9. You are pretty much done. Good job for making a flag mutator :). If you have any bugs, issues or questions, let me know via my [discord server](https://discord.gg/2h3pkECbdn) or the issues tracker here!
