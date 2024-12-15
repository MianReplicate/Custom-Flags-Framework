# Introduction
Hello! if you popped here, chances are, you want to create your own custom flags! If not, then wtf are you doing here, otherwise, carry on!

This is a modified version of the [custom flag framework](https://steamcommunity.com/sharedfiles/filedetails/?id=2797568530) by Red for creating custom flags in Ravenfield

# Modifications from the Original
- Performance loss is negligible (If there are still fps drops with this mutator enabled, let me know!)
- Custom flags now show during capture
- Added a default fallback for when a material isn't detected
  - This allowed me to create the additional "DISABLED" flag option which lets players disable custom flags for a team
  - This was an attempt to add mix and match compatibility with other custom flag mutators, this may or may not work

# Tutorial
Step 1. Download the package file and import it into your Unity project (Must have RFTools for obvious reasons)

Step 2. Get a 1024x512 image, and place it inside the Flag Textures folder.

Step 3. Create a new material in the Flag Materials folder. You can just copy one of the template ones. Then replace the material's texture with your new image.

Step 4. Click the "Custom Flag Pack.prefab" within the "Assets/Custom Flags" folder and add a new material in the "Material" dropdown list within the "Data Container" script. Set the value to your material. Ensure the ids are named in order.

Step 5. Click the "Custom Flag Export.prefab" and add a new element to the dropdowns for both "EagleFlag" and "RavenFlag" (Or only one if you'd prefer). These elements are connected respective to the order of the materials in the "Custom Flag Pack.prefab" file you just modified. As such, the names of the elements DO not matter, only their place in the list. E.g., the "DISABLED" option is the first element, as such it is connected to "Flag1"'s material.

# FAQ
### How to export?

Select Custom Flag Export.prefab --> Ravenfield-Tools --> Click "Export Map or Content Mod"

### How to test?

Select Custom Flag Export.prefab --> Ravenfield-Tools --> Click "Test Map or Content Mod"