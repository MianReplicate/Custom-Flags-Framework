# Common Steps (Steps for both Flag and Mesh Packs)
**MESH PACK CREATORS READ: Please make sure YOU HAVE A BASIC IDEA OF HOW TO USE BLENDER, UV MAPS and MAKING CUSTOM SKINS OR ACCESSORIES FOR RAVENFIELD! The tutorial will proceed assuming you know the prerequisites! If you wish to learn these prerequisites, you can find messages of me learning myself with help from others in the [Ravenfield discord](https://discord.gg/ravenfield) starting [here](https://discord.com/channels/246612905762619393/327766162022596608/1334279804437925992). Make sure to scroll down to find more messages as there may be between time skips in between. The last message related to the topic is [here](https://discord.com/channels/246612905762619393/327766162022596608/1335151746753761282). This is not a perfect tutorial but may be a helpful guide. You can find more information to skin-making [here](https://discord.com/channels/246612905762619393/1068257130186027039).**

Step 1. If you are completely new to Ravenfield modding, [follow this](https://ravenfieldgame.com/modding.html) to set up a Unity project and install RFTools. You do not need to follow this step if you already know how to mod Ravenfield or have a Unity project set up already.

Step 2. Download a unity.package file from one the templates given for your pack.
[Flag Packs](https://github.com/MianReplicate/Political-Flags) or [Mesh Packs](https://github.com/MianReplicate/Flag-Accessories). Then import it as a package into your Unity exactly how the RFTools package is imported.

# How to make a Flag Pack

Step 1. Get images for flags (2:1 aspect ratio or 1024x512 resolution **recommended**), and place them inside the Textures folder. Delete any textures that are not needed. Name these short and consistent. Their names will be displayed to users to assign to flags.

Step 2. Click the prefab file (blue square lookin' file), and add a new texture in the "Texture" dropdown list within the "Data Container" section. Set the value to your texture. Ensure the ids are named in order with "Flag" preceding the number. Do the same thing for the "Color" dropdown list and assign a color to each specific flag. These colors determine team color which includes the actors and HUD. For example, if you assigned a red color to the Russian flag, then if a team had the Russian flag assigned to it, the actors would be red and the HUD for the team would be red colored as well. This does not change the color of the flag texture!

Step 3. Rename the mutator, change the description, and replace the cover. Make sure to also replace the cover in the "Textures" dropdown in the "Data Container" section with yours.

Step 4. Give the prefab file a unique name. Also change the name of the lua file to the same name. Then open the file and replace all instances of the file's old name to the new name you set. This is required since the framework keeps track of what mutators add what flags.

Step 5. Test out your mutator to make sure it works. Export the mutator by pressing Ctrl + E while the prefab is selected. Afterwards, start Ravenfield through Steam. If you have too many addons to where it becomes tedius to start up Ravenfield constantly, you can disable your addons via the properties menu when right clicking the game in your library, and selecting the "Workshop" tab. Afterwards, run the custom map "Flag Viewer" to see if your mutator shows up. Make sure you have the Custom Flags Framework installed, otherwise you will not see the map (let alone even use your flag pack lol).

Step 6. If the mutator works fine, publish to Steam Workshop, and make sure you make this framework a dependency! If your mutator does not work fine/does not show up in the map, open the console (PGUP button) to see what the logs say. Usually you will get an error alongside a reason which tells you what you did wrong. If not, join the discord below OR ping me in the Ravenfield discord in the appropriate channel for further assistance. My username is "mianreplicate."

Step 7. You are pretty much done. Good job for making a flag pack :). If you have any bugs, issues or questions, let me know via my [discord server](https://discord.gg/2h3pkECbdn) or the issues tracker here!

# How to make a Mesh Pack

Step 1. Rename the mutator, change the description and replace the cover in the blue prefab file (blue square looking file). Make sure to also replace the cover within the "Data Container"

Step 2. Open up Blender and start making a mesh on the armature. This can be a custom skin or the default skin. Just make sure you tell users if you are using a custom skin for the mesh as they appear weirdly for other skins. Ensure you have UV maps on the meshes to determine where textures will be placed.

Step 3. Export the mesh as an FBX file with the recommended Ravenfield settings. Make sure you have the "Armature" selected when exporting the mesh!

**Repeat the above FOR as many meshes as you are going to make. You can work on the same the same armature.**

Step 4. After exporting the mesh, place it in the "Meshes" folder. Remove any unneeded meshes that may be in there. Your exported mesh's contents should something like this: 

<img src=https://i.imgur.com/OKfO4ii.png>

Step 5. Go back to the prefab file and find the "Data Container" once more. Add a new mesh by adding a "Game Object" in the "Game Objects" section. You CANNOT set the value to a Mesh file here, what you will instead put is the game object RELATED to the mesh file in your FBX file. The game object should be in the FBX contents and to the left of the material and to the right of the armature. Ensure the ids have "Mesh" with a number in front of them. The numbers SHOULD be in order starting from 1, if not, fix them. Remove any unneeded meshes from this "Data Container".

Step 6. Give the prefab file a unique name. Also change the name of the lua file to the same name. Then open the file and replace all instances of the file's old name to the new name you set. This is required since the framework keeps track of what mutators add what meshes.

Step 7. Test out your mutator to make sure it works. Export the mutator by pressing Ctrl + E while the prefab is selected. Afterwards, start Ravenfield through Steam. If you have too many addons to where it becomes tedius to start up Ravenfield constantly, you can disable your addons via the properties menu when right clicking the game in your library, and selecting the "Workshop" tab. Afterwards, run the custom map "Flag Viewer" to see if your mutator shows up. Make sure you have the Custom Flags Framework installed, otherwise you will not see the map (let alone even use your mesh pack lol). You also need some sort of flag pack installed for obvious reasons.

Step 8. If the mutator works fine, publish to Steam Workshop, and make sure you make this framework a dependency! If your mutator does not work fine/does not show up in the map, open the console (PGUP button) to see what the logs say. Usually you will get an error alongside a reason which tells you what you did wrong. If not, join the discord below OR ping me in the Ravenfield discord in the appropriate channel for further assistance. My username is "mianreplicate."

Step 9. You are pretty much done. Good job for making a mesh pack :). If you have any bugs, issues or questions, let me know via my [discord server](https://discord.gg/2h3pkECbdn) or the issues tracker here!

## Tips and Tricks

- When making the mesh, ensure you have a set up UV map for the flag textures to be set properly.
- Actors (the bots) ingame will only have one MESH applied to them at all times for performance reasons. If you want to use multiple faces with a mesh, that is possible! Ctrl + J is used to join meshes together if needed. E.g., having a front part and a back part combined as one mesh.
- Be extremely conservative with your faces. Remember, THESE are getting applied on HUNDREDS of bots! Users will likely never be looking too closely at the meshes so DO not put much detail on them or use many faces.
- If the mesh is not moving with the rig/bones, make sure you are weight painting and rigging correctly.