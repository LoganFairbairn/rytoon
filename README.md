# RyShade
Note: This shader is a work in progress, some features are currently missing, broken or incomplete.

RyShade is an [NPR](https://en.wikipedia.org/wiki/Non-photorealistic_rendering) (non-photo realistic) shader for stylized, anime and toon assets that attempts to render assets 'half-way' between [PBR](https://en.wikipedia.org/wiki/Physically_based_rendering) (physically based rendering) and toon shading. 

Rendering assets in this manner comes with a few benefits over rendering using a traditional toon shader, or PBR shader:
- Unlike in toon shaders, environment and indirect lighting is accumulated in the shader, resulting in good lighting in a variety of lighting conditions.
- The shader maintains detail better than many toon shaders.
- Optimized approximations can be used without being visually intrusive, such as in the case with subsurface scattering. This makes the shader more optimized than PBR shaders, which is especially useful for virtual reality games.

This shader attempts to create a 'standard' NPR shader format, similar to how there is a standard for PBR shaders. To achieve this goal this shader takes inspiration from numerous stylized and toon shaders used in games such as Valorant<sup>[[2]](#2)</sup>, Genshin Impact<sup>[[1]](#1)</sup>, and popular shaders such as the Poiyomi Toon Shader<sup>[[3]](#3)</sup>.

A main feature of this shader is that it has implementations for [Blender](https://www.blender.org/), [Unity](https://unity.com/) and [VRChat](https://hello.vrchat.com/) (Unity's built-in render pipeline) which allows users to see the final result while modelling Blender, then export their work seamlessly to Unity. This is possible because the shader is kept as simple as possible, without sacrificing functionality.

If you would like to help support this add-ons development you can...
- Donate to my [PayPal](https://paypal.me/RyverCA?country.x=CA&locale.x=en_US)
- Star and follow the repository on Github
- Share RyShade
- Report issues and give suggestions through the Github issues page

Cheers!

## Shader Breakdown

- The base lighting of this shader is calculated using the Half-Lambert<sup>[[7]](#7)</sup><sup>[[9]](#9)</sup> lighting model, which helps prevent the rear of objects from losing their shape and looking too flat. This lights assets in a stylied way with a more constant ambient lighting effect, thus providing a good middle-ground between realistic and toon lighting. This lighting technique, or a variation of it is used in many successful games such as Genshin Impact<sup>[[1]](#1)</sup>, Valorant<sup>[[2]](#2)</sup>, Team Fortress 2<sup>[[8]](#8)</sup> and popular shaders such as the Poiyomi<sup>[[3]](#3)</sup> shader.
![alt text](https://raw.githubusercontent.com/LoganFairbairn/RyToon/main/ShaderPreviews/RyToon_RoughMaterial.png?raw=true)

- Specular highlights are calculated using GGX microfacet distribution<sup>[[4]](#4)</sup>. This allows the shader to represent smooth and rough materials. The GGX normal distribution method was selected specifically because of it's compatability with Blenders material nodes<sup>[[12]](#12)</sup>, but it's also generally considered to be better than some alternatives like the Blinn-Phong<sup>[[13]](#13)</sup> method.
![alt text](https://raw.githubusercontent.com/LoganFairbairn/RyToon/main/ShaderPreviews/RyToon_SmoothMaterial.png?raw=true)

- Metalness is also calculated using GGX microfacet distribution<sup>[[4]](#4)</sup> where the result of the GGX calculation is multiplied into the shader output. This isn't a physically accurate way of calculating metalness<sup>[[5]](#5)</sup>, but provides good results in the toon shader. In a PBR approach users would mark metallic objects as 0 (not metallic) or 1 (fully metallic) and generally nothing in between for more physically accurate results. With this shader it would be correct to have a value between 0 and 1, to produce lighter shades of metallic looking materials. It may also be good to note that you could effectively think of the metallic property in this shader as reflectivity.
![alt text](https://raw.githubusercontent.com/LoganFairbairn/RyToon/main/ShaderPreviews/RyToon_MetallicMaterial.png?raw=true)

- The shader calculates artificial subsurface scattering by using a modified lambert lighting<sup>[[6]](#6)</sup><sup>[[10]](#10)</sup>, many games such as valorant<sup>[[2]](#2)</sup> and Uncharted 4<sup>[[11]](#11)</sup> use a version of this approach.
![alt text](https://raw.githubusercontent.com/LoganFairbairn/RyToon/main/ShaderPreviews/RyToon_SubsurfaceMaterial.png?raw=true)

- The shader supports emission (for glow).

- The shader supports transparency (cutout).

- The Unity implementation uses ORM (occlusion, roughness, metallic) channel packing to optimize texture memory optimization.

- The shader provides 'artist friendly' properties to create different material types, in a similar manner to PBR shaders.

- Lastly, I documented, commented and linked to references / learning resources to help users modify the shader if they need something custom.

## References

1. <a href="https://www.artstation.com/artwork/g0gGOm" target="_blank" name="1">Genshin Impact Shader UE5</a>
2. <a href="https://technology.riotgames.com/news/valorant-shaders-and-gameplay-clarity" target="_blank" name="2">Valorant Shaders and Gameplay Clarity</a>
3. <a href="https://github.com/poiyomi/PoiyomiToonShader" target="_blank" name="3">Poiyomi Shader</a>
4. Microfacet BRDF: Theory and Implementation of Basic PBR Materials [Shaders Monthly #9] - <a href="https://youtu.be/gya7x9H3mV0?si=Mvc9rkKFVvDJjx0d&t=930" target="_blank" name="4">GGX Microfacet Distribution</a>
5. Catlike coding <a href="https://catlikecoding.com/unity/tutorials/rendering/part-4/" target="_blank" name="5">Rendering Part 4</a> (covers PBR lighting calculations in Unity, and a fairly accurate approximation of metallic and specular workflow)
6. <a href="https://catlikecoding.com/unity/tutorials/rendering/part-4/" target="_blank" name="6">Fast Subsurface Scattering for Unity URP</a> by John Austin
7. <a href="https://developer.valvesoftware.com/wiki/Half_Lambert" target="_blank" name="7">Half Lambert</a> lighting from Valve
8. <a href="https://steamcdn-a.akamaihd.net/apps/valve/2008/GDC2008_StylizationWithAPurpose_TF2.pdf" target="_blank" name="8">Stylization with a Purpose</a> The Illustrative World of Team Fortress 2 by Jason Mitchell
9. <a href="https://www.jordanstevenstechart.com/lighting-models" target="_blank" name="9">Lighting Models</a> by Jordan Stevens
10. Unity documentation - <a href="https://docs.unity3d.com/Manual/SL-SurfaceShaderLightingExamples.html" target="_blank" name="10">Surface Shader Lighting Examples</a>
11. Advances in Realtime Rendering SigGraph 2016 <a href="https://advances.realtimerendering.com/s2010/Hable-Uncharted2(SIGGRAPH%202010%20Advanced%20RealTime%20Rendering%20Course).pdf" target="_blank" name="11">The Process of Creating Volumetric-based Materials in Uncharted 4</a> by Yibing Jiang (Naughty Dog) slide 22
12. Blender Manual for the <a href="https://docs.blender.org/manual/en/latest/render/shader_nodes/shader/glossy.html#glossy-bsdf" target="_blank" name="12">Glossy BSDF</a>
13. <a href="https://en.wikipedia.org/wiki/Blinn%E2%80%93Phong_reflection_model" target="_blank" name="13">Blinn-Phone Reflection Model</a>

## FAQ

Q: Why is this shader free?
<br>
I believe in [free and open-source software](https://www.gnu.org/philosophy/free-sw.html#four-freedoms) so everyone has the freedom to create!

Q: Why not use other existing shaders such as the Poiyomi shader for a Unity to Blender workflow?
<br>
Like many shaders the Poiyomi shader has only an implementation for one software, there is no implementation for Blender. This means it's not possible to see your model with the shader that will be used in the final product. Not having the shader in Blender also means your can't render promotional material or cinematics for your asset in Blender as the final result that would be exported into Unity would look visually different. RyShade has an implementation for both Blender and Unity, which makes the asset transition between the two software seamless.
