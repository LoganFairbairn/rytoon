# rytoon
RyToon is an NPR (non-photo-realistic) shader for toon / anime characters with an implementation for Blender and Unity's built-in rendering pipeline (works in VRChat).

Shader Features:
[] Produces similar results in both Unity and Blender.
[] Uses identical parameters for both the Blender and Unity shader implementation.
[] Works with Unity's built-in rendering pipeline and VRChat.
[] Lights toon and anime characters in a semi-realistic way that produces good results in most lighting conditions.
[] Calculates specular lighting to simulate smooth and rough materials.
[] Calculates artifical metalness as a matcap, which is similar to how the Genshin Impact anime shader calculates metalness.
[] Uses ORM (occlusion, roughness, metallness) channel packing for texture memory optimization.
[] Calculates artificial subsurface scattering to simulate light distribution as it passed through objects.
[] Allows using a thickness map to define more accurate subsurface scattering.
[] Calculates 'coat' specular lighting for simulating lacqurt or car paint.
[] Calculates sheen for simulating small fibers for cloth and fabric, but can also be used to simulate dust.
[] Supports emission for adding glow.
[] Alpha for simulating transparency and glass.
[] Well commented code and links to relevant shader documentation to allow for easier user modifications.