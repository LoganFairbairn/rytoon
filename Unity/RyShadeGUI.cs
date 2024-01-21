// Script that alters the graphical user interface inside the Unity editor for the RyShade shader.

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class RyShadeGUI : ShaderGUI {
    MaterialEditor editor;
	MaterialProperty[] properties;

	public override void OnGUI (MaterialEditor editor, MaterialProperty[] properties) {
        this.editor = editor;
        this.properties = properties;

        // Textures
        GUILayout.Label("Textures", EditorStyles.boldLabel);

        MaterialProperty albedoTextureProperty = FindProperty("_ColorTexture");
        MaterialProperty colorTint = FindProperty("_Tint");
        editor.TexturePropertySingleLine(MakeLabel(albedoTextureProperty.displayName, "Albedo (RGBA)"), albedoTextureProperty, colorTint);
        
        MaterialProperty ORMTextureProperty = FindProperty("_ORMTexture");
        editor.TexturePropertySingleLine(MakeLabel(ORMTextureProperty.displayName, "Occlusion, Roughness, Metalness Channel Packed Texture"), ORMTextureProperty);

        MaterialProperty normalMap = FindProperty("_NormalMap");
        editor.TexturePropertySingleLine(MakeLabel(normalMap.displayName, "Normal Map"), normalMap);

        MaterialProperty subsurfaceTexture = FindProperty("_SubsurfaceTexture");
        MaterialProperty subsurfaceTintProperty = FindProperty("_SubsurfaceTint");
        editor.TexturePropertySingleLine(MakeLabel(subsurfaceTexture.displayName), subsurfaceTexture, subsurfaceTintProperty);

        MaterialProperty emissionTextureProperty = FindProperty("_EmissionTexture");
        MaterialProperty emissionColor = FindProperty("_EmissionColor");
        editor.TexturePropertySingleLine(MakeLabel(emissionTextureProperty.displayName, "Emission (glow) color."), emissionTextureProperty, emissionColor);

        // Adjustments
        GUILayout.Label("Adjustments", EditorStyles.boldLabel);

        MaterialProperty roughness = FindProperty("_Roughness");
        editor.ShaderProperty(roughness, MakeLabel(roughness.displayName));

        MaterialProperty metallic = FindProperty("_Metallic");
        editor.ShaderProperty(metallic, MakeLabel(metallic.displayName));

        MaterialProperty subsurfaceIntensityProperty = FindProperty("_SubsurfaceIntensity");
        editor.ShaderProperty(subsurfaceIntensityProperty, MakeLabel(subsurfaceIntensityProperty.displayName));

        MaterialProperty subsurfaceRadiusProperty = FindProperty("_SubsurfaceRadius");
        editor.ShaderProperty(subsurfaceRadiusProperty, MakeLabel(subsurfaceRadiusProperty.displayName));

        MaterialProperty emissionStrengthProperty = FindProperty("_EmissionStrength");
        editor.ShaderProperty(emissionStrengthProperty, MakeLabel(emissionStrengthProperty.displayName));

        // Projection
        GUILayout.Label("Projection", EditorStyles.boldLabel);
        editor.TextureScaleOffsetProperty(albedoTextureProperty);
	}

    // Convenience function for finding a material property from within the shader.
    MaterialProperty FindProperty (string name) {
        return FindProperty(name, properties);
    }

    // Convenience method for making a GUI label.
    static GUIContent staticLabel = new GUIContent();
    static GUIContent MakeLabel(string text, string tooltip = null) {
        staticLabel.text = text;
        staticLabel.tooltip = tooltip;
        return staticLabel;
    }
}
