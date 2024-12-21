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

- Find more information here on the [TEMPLATE INFO](https://github.com/MianReplicate/Mian-Custom-Flags-Framework/blob/main/TEMPLATE-INFO.md)