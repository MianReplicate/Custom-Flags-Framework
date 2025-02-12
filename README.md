# Introduction
A framework that allows you to change the textures for flags on each team. If you wanted to ever fight Russians or some other team instead of RAVEN or EAGLE, you can now do that using this framework!

This is a heavily modified version of the [custom flag framework](https://steamcommunity.com/sharedfiles/filedetails/?id=2797568530) by Red for creating custom flags in Ravenfield. Heavy thanks to them for making the original :)

# Customizability
- If you want to mix & match flag materials from other mutators that use this framework, you can do that!
- Customize the color of a flag texture.
- Automatically change a team's name to the name of its specified flag material.
- Automatically change the color of the team depending on the selected flag.
- Use commands to customize flags, accessories and teams! Wanna override the team name or color for a flag? Wanna randomize which flags get placed into each team? You can do that :)
- You can assign multiple flags to a team, which in turn assigns bots their own flag. When a bot starts capturing a point, the texture on the flag will be changed to represent the bot's assigned flag. This allows for historical scenarios if you wanted to recreate allies within WW2 for example.
- You can let bots feel prideful of the flag they were assigned by installing and using accessory packs! [Here's one I created](https://steamcommunity.com/sharedfiles/filedetails/?id=3418664311). If you are interested, feel free to create your own accessory packs within the tutorial in the FAQ. This is super helpful if you wanna know what flag a bot has been assigned.
- Custom vehicles with materials named "FLAG" get textured automatically with the flag assigned to the bot that is driving!

# Modifications from the Original
- This by itself does not come with any flags. You need to install this alongside another flag pack that uses this framework.
- When making custom flag packs using this framework, they will have to depend on this framework. This makes it easier to mass fix bugs across all flag mutators, allows for new features to be added and allows for seamless compatibility with one another 
- Much more performance friendly than the original and other flag mutators. Almost no performance hit at all.
- Custom flags now show during capture
- Edit which team has what flags using the name of flags in the mutator config! No more having to go through different mutators to select what flag goes to where.
- You can view installed mutators and their added flags by using the new "Flag Viewer" map. This lets you view the id and name of each flag and mutator.

# How to add flags/accessories to teams
- Find more information here on the [SYNTAX INFO](https://github.com/MianReplicate/Mian-Custom-Flags-Framework/blob/stable/SYNTAX-INFO.md)

# FAQ
### Can I replace textures on my vehicles with flags?
- Yes! If you rename any materials on your custom vehicle to "CFF_FLAG", any bot with a flag assigned to them that drives that vehicle will automatically replace the vehicle's FLAG material textures to the flag texture!

### How do bots get assigned flags?
- When bots spawned, they are usually assigned the flag that the capture point represents. Sometimes however, this is not the case and they are assigned a different flag belonging to the team. If this happens, that bot then encourages bots after it to spawn as that bot's flag. This encourages bots to spawn in groups of assigned flags rather than every single bot having a different flag. Though it does still have a chance of randomizing again which allows for more diversity!

### I found a bug/I wanna suggest a new idea!

- First, make sure you are running on the Beta branch. If not, please try that first and see if the bug still happens. If it does, report it [here](https://github.com/MianReplicate/Mian-Custom-Flags-Framework/issues)!

### How to create my own flag/accessory packs?

- Find more information here on the [TEMPLATE INFO](https://github.com/MianReplicate/Mian-Custom-Flags-Framework/blob/stable/TEMPLATE-INFO.md)

# Credits
Special thanks to Wingnut for letting me use their WIP vehicles for testing out the new Pride Update involving extending flag textures to vehicles.
