# GodotGoldSrcBSP

A plugin that allows you to laod GoldSrc BSP files into Godot

## Video Demo
[![](https://i.imgur.com/UbihCVB.png)](https://www.youtube.com/watch?v=-gloaTbZxmU)

## Installation
Copy the "addons" folder into the root directory of the Godot Project

Go to Project->Project Settings->Plugins and set the plugins status to "Active"

## Usage

**Note that this isn't finished yet and is only here for testing purposes. Currently it only works by linkng the external GoldSrc game directory and as such can't yet be included into your Godot Project Directory**

![](https://i.imgur.com/FINHIjn.png)

Drag the BSP_Map.tscn file from the addons/gldsrcBSP folder into the scene tree.

Enter thet path to the bsp in "Path" field and Press "Create Map"

If you want the map to generate on runtime don't press "Create Map" and it will automatically be created on launch.

## Entities

This plugin supports various but not all entities.
If you want a body to trigger/interact with the entities add it to the "hlTrigger" group.

## Lightmaps

You can import lightmaps from the BSP file but you will need to set your enviroment to "Clear Color" and up the ambient light.

## Real-time lights and global illumination

As an alternative or as a complement to lightmaps stored in the map file,
you can use real-time lighting and global illumination. Real-time lighting can provide a better
appearance and allows for lights to change during gameplay,
but it's much slower to render compared to lightmaps.

The resulting MeshInstances are configured to cast double-sided shadows.
This allows real-time lights to cast mostly correct shadows, but peter-panning may still be present due to
faces being hollow.
Tweaking the lights' shadow bias values may help, but it's not always sufficient to hide shadow peter-panning.
If tweaking the lights' shadow bias values doesn't suffice, try adding solid MeshInstances behind hollow walls
manually to act as shadow casters.

For global illumination, GIProbe can be used as the resulting MeshInstances are set to be used in baked light.
However, BakedLightmap will not work correctly as UV2 isn't generated properly for the generated meshes.

## Material appearance

By default, Metallic Specular is set to 0.0 on generated materials to make reflections from the sky
much less visible. This is good for retro-looking games, but the physically correct setting is 0.5
(which is also the default in SpatialMaterial). If you wish to have a more realistic appearance,
adjust the Materials Metallic Specular property in the BSP_Map scene in the inspector.

## Media

![](https://i.imgur.com/STAOPjS.jpg)
![](https://i.imgur.com/UtKyFi5.png)
