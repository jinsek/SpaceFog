using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class Create3DTextures : EditorWindow
{
    private int textureSize = 32;
    private Texture2D HeightTex;
    private AnimationCurve HeightCurve = new AnimationCurve();
    private Vector2 offset = new Vector2(0, 1f);
    [MenuItem("VolumeFog/3DTexture")]
    static void Init()
    {
        // Get existing open window or if none, make a new one:
        Create3DTextures window = (Create3DTextures)EditorWindow.GetWindow(typeof(Create3DTextures));
        window.Show();
        
    }
    private void OnGUI()
    {
        // Configure the texture
        textureSize = EditorGUILayout.IntField("3D Texture Size", textureSize);
        textureSize = Mathf.NextPowerOfTwo(textureSize);
        textureSize = Mathf.Clamp(textureSize, 16, 256);
        HeightTex = EditorGUILayout.ObjectField("Height Texture", HeightTex, 
            typeof(Texture2D), true) as Texture2D;
        HeightCurve = EditorGUILayout.CurveField("Height Curve", HeightCurve);

        if (GUILayout.Button("Create"))
        {
            Create3DTexture(textureSize);
        }
    }
    private void Create3DTexture(int size)
    {
        TextureFormat format = TextureFormat.RGBA32;
        TextureWrapMode wrapMode = TextureWrapMode.Clamp;

        // Create the texture and apply the configuration
        Texture3D texture = new Texture3D(size, size, size, format, false);
        texture.wrapMode = wrapMode;

        // Create a 3-dimensional array to store color data
        Color[] colors = new Color[size * size * size];

        for (int z = 0; z < size; z++)
        {
            int zOffset = z * size * size;
            for (int y = 0; y < size; y++)
            {
                int yOffset = y * size;
                for (int x = 0; x < size; x++)
                {
                    float fx = (float)x / size;
                    float fy = (float)y / size;
                    float fz = (float)z / size;
                    float density = HeightTex.GetPixelBilinear(fx, fz).r;
                    float height = HeightCurve.Evaluate(fy);
                    float val = density * height;
                    colors[x + yOffset + zOffset] = new Color(val, val, val, val);
                }
            }
        }

        // Copy the color values to the texture
        texture.SetPixels(colors);

        // Apply the changes to the texture and upload the updated texture to the GPU
        texture.Apply();

        // Save the texture to your Unity Project
        var path = AssetDatabase.GenerateUniqueAssetPath("Assets/Example3DTexture.asset");
        AssetDatabase.CreateAsset(texture, path);
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }
}

