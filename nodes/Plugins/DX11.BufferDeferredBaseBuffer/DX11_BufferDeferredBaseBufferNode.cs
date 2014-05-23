using System;
using System.Collections.Generic;
using System.Text;
using System.ComponentModel.Composition;
using System.Runtime.InteropServices;

using SlimDX;
using SlimDX.Direct3D11;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.DX11;
using VVVV.DX11.Nodes;
using VVVV.Utils;
using VVVV.Utils.VMath;

using FeralTic.DX11.Geometry;
using FeralTic.DX11.Resources;
using FeralTic.DX11;


namespace VVVV.Nodes.DX11
{
	#region management
	#region scene
    [StructLayout(LayoutKind.Sequential)]
    public struct DeferredBase
    {
    	public Matrix tW;
    	public Matrix ptW;
    	public Matrix tTex;
    	public float DiffAmount;
    	public Vector4 DiffCol;
    	public float VelocityGain;
    	public float BumpAmount;
    	public float DispAmount;
    	public float pDispAmount;
    	public uint MatID;
    	public int ObjID0;
    	public int ObjID1;
    	public int ObjID2;
    }
	
    [StructLayout(LayoutKind.Sequential)]
    public struct DeferredBaseProperties
    {
    	public float DiffAmount;
    	public Vector4 DiffCol;
    	public float VelocityGain;
    	public float BumpAmount;
    	public float DispAmount;
    	public float pDispAmount;
    	public uint MatID;
    }
	#endregion scene
	#region materials
    [StructLayout(LayoutKind.Sequential)]
    public struct MaterialProp
    {
    	public Vector3 Atten;
    	public float Power;
    	public Vector4 AmbCol;
    	public Vector4 SpecCol;
    	public float SpecAmount;
    	public Vector4 EmCol;
    	public float EmAmount;
    	public float SSSAmount;
    	public float SSSPower;
    	public float MatThick;
    	public float RimLAmount;
    	public float RimLPower;
    	public Vector4 SSSExtCoeff;
    	public float Reflection;
    	public float Refraction;
		public uint ReflectRefractTexID;
    }
	public class MaterialObject
    {
    	public Vector3 Atten;
    	public float Power;
    	public Vector4 AmbCol;
    	public Vector4 SpecCol;
    	public float SpecAmount;
    	public Vector4 EmCol;
    	public float EmAmount;
    	public float SSSAmount;
    	public float SSSPower;
    	public float MatThick;
    	public float RimLAmount;
    	public float RimLPower;
    	public Vector4 SSSExtCoeff;
    	public float Reflection;
    	public float Refraction;
		public uint ReflectRefractTexID;
    	public MaterialObject()
    	{
	    	this.Atten.X = 0;
	    	this.Atten.Y = 0;
	    	this.Atten.Z = 0;
	    	this.Power = 0;
	    	this.AmbCol.X = 0;
	    	this.AmbCol.Y = 0;
	    	this.AmbCol.Z = 0;
	    	this.AmbCol.W = 1;
	    	this.SpecCol.X = 0;
	    	this.SpecCol.Y = 0;
	    	this.SpecCol.Z = 0;
	    	this.SpecCol.W = 1;
	    	this.SpecAmount = 0;
	    	this.EmCol.X = 0;
	    	this.EmCol.Y = 0;
	    	this.EmCol.Z = 0;
	    	this.EmCol.W = 1;
	    	this.EmAmount = 0;
	    	this.SSSAmount = 0;
	    	this.SSSPower = 0;
	    	this.MatThick = 0;
	    	this.RimLAmount = 0;
	    	this.RimLPower = 0;
	    	this.SSSExtCoeff.X = 0;
	    	this.SSSExtCoeff.Y = 0;
	    	this.SSSExtCoeff.Z = 0;
	    	this.SSSExtCoeff.W = 1;
	    	this.Reflection = 0;
	    	this.Refraction = 0;
    		this.ReflectRefractTexID = 0;
    	}
    }
    public class MaterialServer
    {
    	public List<MaterialObject> Materials;
    	public List<int> ID;
    	public List<string> Custom;
    	public MaterialServer()
    	{
	    	this.Materials = new List<MaterialObject>();
	    	this.ID = new List<int>();
	    	this.Custom = new List<string>();
    	}
    }
	#region PluginInfo
	[PluginInfo(Name = "MaterialServer",
	            Category = "MaterialManager",
	            Tags = "")]
	#endregion PluginInfo
	public class MaterialManagerMaterialServerNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Clear", IsBang = true, IsSingle = true)]
        public ISpread<bool> FClear;
		[Output("Output")]
        public ISpread<MaterialServer> FOutput;
		[Output("ID")]
		ISpread<int> FID;
		[Output("Custom")]
		ISpread<string> FCustom;
		[Output("Attenuation")]
        ISpread<Vector3> FAtten;
        [Output("Specular Power")]
        ISpread<float> FPow;
        [Output("Ambient Color")]
        ISpread<Color4> FAmbCol;
        [Output("Specular Color")]
        ISpread<Color4> FSpecCol;
        [Output("Specular Amount")]
        ISpread<float> FSpecAmount;
        [Output("Emission Color")]
        ISpread<Color4> FEmCol;
        [Output("Emission Amount")]
        ISpread<float> FEmAmount;
        [Output("SSS Amount")]
        ISpread<float> FSSSAmount;
        [Output("SSS Power")]
        ISpread<float> FSSSPower;
        [Output("SSS Material Thickness")]
        ISpread<float> FMatThick;
        [Output("Rim Light Amount")]
        ISpread<float> FRimLAmount;
        [Output("Rim Light Power")]
        ISpread<float> FRimLPower;
        [Output("Extinction Coefficient")]
        ISpread<Color4> FSSSExtCoeff;
        [Output("Reflection")]
        ISpread<float> FReflection;
        [Output("Refraction")]
        ISpread<float> FRefraction;
        [Output("ReflectRefractTexID")]
        ISpread<int> FReflectRefractTexID;
		
		private MaterialServer Everything;
		#endregion fields & pins
 
		[ImportingConstructor]
		public MaterialManagerMaterialServerNode()
		{
			this.Everything = new MaterialServer();
		}
		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{ 
			FOutput.SliceCount = 1;

			FOutput[0] = Everything;
			int MaxID = 0;
			if(FClear[0])
			{
				Everything.Custom.Clear();
				Everything.ID.Clear();
				Everything.Materials.Clear();
			}
			for(int i=0; i<Everything.ID.Count; i++)
			{
				MaxID = Math.Max(MaxID,Everything.ID[i])+1;
			}

			FCustom.SliceCount = Math.Max(MaxID,1);
			FID.SliceCount = Math.Max(Everything.ID.Count,1);
	        FAtten.SliceCount = Math.Max(MaxID,1);
	        FPow.SliceCount = Math.Max(MaxID,1);
	        FAmbCol.SliceCount = Math.Max(MaxID,1);
	        FSpecCol.SliceCount = Math.Max(MaxID,1);
	        FSpecAmount.SliceCount = Math.Max(MaxID,1);
	        FEmCol.SliceCount = Math.Max(MaxID,1);
	        FEmAmount.SliceCount = Math.Max(MaxID,1);
	        FSSSAmount.SliceCount = Math.Max(MaxID,1);
	        FSSSPower.SliceCount = Math.Max(MaxID,1);
	        FMatThick.SliceCount = Math.Max(MaxID,1);
	        FRimLAmount.SliceCount = Math.Max(MaxID,1);
	        FRimLPower.SliceCount = Math.Max(MaxID,1);
	        FSSSExtCoeff.SliceCount = Math.Max(MaxID,1);
	        FReflection.SliceCount = Math.Max(MaxID,1);
	        FRefraction.SliceCount = Math.Max(MaxID,1);
	        FReflectRefractTexID.SliceCount = Math.Max(MaxID,1);
	        
			for(int i=0; i<Everything.Materials.Count; i++)
			{
				FID[i] = Everything.ID[i];
				FCustom[Everything.ID[i]] = Everything.Custom[i];
		        FAtten[Everything.ID[i]] = Everything.Materials[i].Atten;
		        FPow[Everything.ID[i]] = Everything.Materials[i].Power;
		        FAmbCol[Everything.ID[i]] = (Color4)Everything.Materials[i].AmbCol;
		        FSpecCol[Everything.ID[i]] = (Color4)Everything.Materials[i].SpecCol;
		        FSpecAmount[Everything.ID[i]] = Everything.Materials[i].SpecAmount;
		        FEmCol[Everything.ID[i]] = (Color4)Everything.Materials[i].EmCol;
		        FEmAmount[Everything.ID[i]] = Everything.Materials[i].EmAmount;
		        FSSSAmount[Everything.ID[i]] = Everything.Materials[i].SSSAmount;
		        FSSSPower[Everything.ID[i]] = Everything.Materials[i].SSSPower;
		        FMatThick[Everything.ID[i]] = Everything.Materials[i].MatThick;
		        FRimLAmount[Everything.ID[i]] = Everything.Materials[i].RimLAmount;
		        FRimLPower[Everything.ID[i]] = Everything.Materials[i].RimLPower;
		        FSSSExtCoeff[Everything.ID[i]] = (Color4)Everything.Materials[i].SSSExtCoeff;
		        FReflection[Everything.ID[i]] = Everything.Materials[i].Reflection;
		        FRefraction[Everything.ID[i]] = Everything.Materials[i].Refraction;
		        FReflectRefractTexID[Everything.ID[i]] = (int)Everything.Materials[i].ReflectRefractTexID;
			}
			//FLogger.Log(LogType.Debug, "hi tty!");
		}
	}
	
	#region PluginInfo
	[PluginInfo(Name = "Material",
	            Category = "MaterialManager",
	            Tags = "",
				AutoEvaluate = true)]
	#endregion PluginInfo
	public class MaterialManagerMaterialNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Material Server")]
		IDiffSpread<MaterialServer> FServer;
		[Input("ID")]
		ISpread<int> FID;
		[Input("Custom")]
		ISpread<string> FCustom;
		[Input("Attenuation")]
        ISpread<Vector3> FAtten;
        [Input("Specular Power")]
        ISpread<float> FPow;
        [Input("Ambient Color")]
        ISpread<Color4> FAmbCol;
        [Input("Specular Color")]
        ISpread<Color4> FSpecCol;
        [Input("Specular Amount")]
        ISpread<float> FSpecAmount;
        [Input("Emission Color")]
        ISpread<Color4> FEmCol;
        [Input("Emission Amount")]
        ISpread<float> FEmAmount;
        [Input("SSS Amount")]
        ISpread<float> FSSSAmount;
        [Input("SSS Power")]
        ISpread<float> FSSSPower;
        [Input("SSS Material Thickness")]
        ISpread<float> FMatThick;
        [Input("Rim Light Amount")]
        ISpread<float> FRimLAmount;
        [Input("Rim Light Power")]
        ISpread<float> FRimLPower;
        [Input("Extinction Coefficient")]
        ISpread<Color4> FSSSExtCoeff;
        [Input("Reflection")]
        ISpread<float> FReflection;
        [Input("Refraction")]
        ISpread<float> FRefraction;
        [Input("ReflectRefractTexID")]
        ISpread<int> FReflectRefractTexID;
		#endregion fields & pins
		
		
		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			for(int i = 0; i<SpreadMax; i++)
			{
				bool exists = false;
				int FoundID = 0;
				for(int j = 0; j<FServer[0].Materials.Count; j++)
				{
					if(FServer[0].ID[j] == FID[i])
					{
						exists = true;
						FoundID = j;
					}
				}
				if(exists)
				{
					FServer[0].Custom[FoundID] = FCustom[i];
			        FServer[0].Materials[FoundID].Atten = FAtten[i];
			        FServer[0].Materials[FoundID].Power = FPow[i];
			        FServer[0].Materials[FoundID].AmbCol = (Vector4)FAmbCol[i];
			        FServer[0].Materials[FoundID].SpecCol = (Vector4)FSpecCol[i];
			        FServer[0].Materials[FoundID].SpecAmount = FSpecAmount[i];
			        FServer[0].Materials[FoundID].EmCol = (Vector4)FEmCol[i];
			        FServer[0].Materials[FoundID].EmAmount = FEmAmount[i];
			        FServer[0].Materials[FoundID].SSSAmount = FSSSAmount[i];
			        FServer[0].Materials[FoundID].SSSPower = FSSSPower[i];
			        FServer[0].Materials[FoundID].MatThick = FMatThick[i];
			        FServer[0].Materials[FoundID].RimLAmount = FRimLAmount[i];
			        FServer[0].Materials[FoundID].RimLPower = FRimLPower[i];
			        FServer[0].Materials[FoundID].SSSExtCoeff = (Vector4)FSSSExtCoeff[i];
			        FServer[0].Materials[FoundID].Reflection = FReflection[i];
			        FServer[0].Materials[FoundID].Refraction = FRefraction[i];
			        FServer[0].Materials[FoundID].ReflectRefractTexID = (uint)FReflectRefractTexID[i];
				}
				else
				{
					MaterialObject tmp = new MaterialObject();
			        tmp.Atten = FAtten[i];
			        tmp.Power = FPow[i];
			        tmp.AmbCol = (Vector4)FAmbCol[i];
			        tmp.SpecCol = (Vector4)FSpecCol[i];
			        tmp.SpecAmount = FSpecAmount[i];
			        tmp.EmCol = (Vector4)FEmCol[i];
			        tmp.EmAmount = FEmAmount[i];
			        tmp.SSSAmount = FSSSAmount[i];
			        tmp.SSSPower = FSSSPower[i];
			        tmp.MatThick = FMatThick[i];
			        tmp.RimLAmount = FRimLAmount[i];
			        tmp.RimLPower = FRimLPower[i];
			        tmp.SSSExtCoeff = (Vector4)FSSSExtCoeff[i];
			        tmp.Reflection = FReflection[i];
			        tmp.Refraction = FRefraction[i];
			        tmp.ReflectRefractTexID = (uint)FReflectRefractTexID[i];
					FServer[0].Materials.Add(tmp);
					FServer[0].Custom.Add(FCustom[i]);
					FServer[0].ID.Add(FID[i]);
				}
			}
		}
	}
	#endregion materials
	#region pointlight
    [StructLayout(LayoutKind.Sequential)]
    public struct PointLightProp
    {
    	public Vector3 Position;
    	public float Range;
    	public float RangePow;
    	public Vector4 LightCol;
    	public float LightStrength;
    }
	public class PointLightObject
    {
    	public Vector3 Position;
    	public float Range;
    	public float RangePow;
    	public Vector4 LightCol;
    	public float LightStrength;
    	public PointLightObject()
    	{
	    	this.Position.X = 0;
	    	this.Position.Y = 0;
	    	this.Position.Z = 0;
    		this.Range = 0;
    		this.RangePow = 0;
	    	this.LightCol.X = 0;
	    	this.LightCol.Y = 0;
	    	this.LightCol.Z = 0;
	    	this.LightCol.W = 1;
	    	this.LightStrength = 0;
    	}
    }
    public class PointLightServer
    {
    	public List<PointLightObject> PointLights;
    	public List<string> Custom;
    	public PointLightServer()
    	{
	    	this.PointLights = new List<PointLightObject>();
	    	this.Custom = new List<string>();
    	}
    }
	#region PluginInfo
	[PluginInfo(Name = "PointLightServer",
	            Category = "PointLightManager",
	            Tags = "")]
	#endregion PluginInfo
	public class PointLightManagerPointLightServerNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Clear", IsBang = true, IsSingle = true)]
        ISpread<bool> FClear;
		[Output("Output")]
        ISpread<PointLightServer> FOutput;
		[Output("Custom")]
		ISpread<string> FCustom;
		[Output("Position")]
        ISpread<Vector3> FPosition;
        [Output("Range")]
        ISpread<float> FRange;
        [Output("Range Power")]
        ISpread<float> FRangePow;
        [Output("Light Color")]
        ISpread<Color4> FLightCol;
        [Output("Light Strength")]
        ISpread<float> FLightStrength;
		
		private PointLightServer Everything;
		#endregion fields & pins
 
		[ImportingConstructor]
		public PointLightManagerPointLightServerNode()
		{
			this.Everything = new PointLightServer();
		}
		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{ 
			FOutput.SliceCount = 1;

			FOutput[0] = Everything;
			int MaxID = Everything.Custom.Count;

			FCustom.SliceCount = Math.Max(MaxID,1);
	        FPosition.SliceCount = Math.Max(MaxID,1);
	        FRange.SliceCount = Math.Max(MaxID,1);
	        FRangePow.SliceCount = Math.Max(MaxID,1);
	        FLightCol.SliceCount = Math.Max(MaxID,1);
	        FLightStrength.SliceCount = Math.Max(MaxID,1);
			
			if(FClear[0])
			{
				Everything.Custom.Clear();
				Everything.PointLights.Clear();
			}
	        
			for(int i=0; i<Everything.PointLights.Count; i++)
			{
				FCustom[i] = Everything.Custom[i];
		        FPosition[i] = Everything.PointLights[i].Position;
		        FRange[i] = Everything.PointLights[i].Range;
		        FRangePow[i] = Everything.PointLights[i].RangePow;
		        FLightCol[i] = (Color4)Everything.PointLights[i].LightCol;
		        FLightStrength[i] = Everything.PointLights[i].LightStrength;
			//FLogger.Log(LogType.Debug, "hi tty!");
				
			}
		}
	}
	
	#region PluginInfo
	[PluginInfo(Name = "GetPointLight",
	            Category = "PointLightManager",
	            Tags = "")]
	#endregion PluginInfo
	public class PointLightManagerGetPointLightNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("PointLightServer", IsSingle = true)]
        ISpread<PointLightServer> FEverything;
		[Input("Custom")]
		ISpread<string> FCustom;
		[Output("Position")]
        ISpread<Vector3> FPosition;
        [Output("Range")]
        ISpread<float> FRange;
        [Output("Range Power")]
        ISpread<float> FRangePow;
        [Output("Light Color")]
        ISpread<Color4> FLightCol;
        [Output("Light Strength")]
        ISpread<float> FLightStrength;
		
		#endregion fields & pins
 
		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{ 
			PointLightServer Everything = FEverything[0];

			int MaxID = Everything.Custom.Count;

	        FPosition.SliceCount = 0;
	        FRange.SliceCount = 0;
	        FRangePow.SliceCount = 0;
	        FLightCol.SliceCount = 0;
	        FLightStrength.SliceCount = 0;
	        
			for(int i=0; i<Everything.PointLights.Count; i++)
			{
				if(Everything.Custom[i].Contains(FCustom[0]))
				{
			        FPosition.Add(Everything.PointLights[i].Position);
			        FRange.Add(Everything.PointLights[i].Range);
			        FRangePow.Add(Everything.PointLights[i].RangePow);
			        FLightCol.Add((Color4)Everything.PointLights[i].LightCol);
			        FLightStrength.Add(Everything.PointLights[i].LightStrength);
				}
			//FLogger.Log(LogType.Debug, "hi tty!");
				
			}
		}
	}
	
	#region PluginInfo
	[PluginInfo(Name = "PointLight",
	            Category = "PointLightManager",
	            Tags = "",
				AutoEvaluate = true)]
	#endregion PluginInfo
	public class PointLightManagerPointLightNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("PointLight Server")]
		IDiffSpread<PointLightServer> FServer;
		[Input("Custom")]
		ISpread<string> FCustom;
		[Input("Position")]
        ISpread<Vector3> FPosition;
        [Input("Range")]
        ISpread<float> FRange;
        [Input("Range Power")]
        ISpread<float> FRangePow;
        [Input("Light Color")]
        ISpread<Color4> FLightCol;
        [Input("Light Strength")]
        ISpread<float> FLightStrength;
		
		#endregion fields & pins
		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			for(int i = 0; i<SpreadMax; i++)
			{
				
				bool exists = false;
				int FoundID = 0;
				for(int j = 0; j<FServer[0].PointLights.Count; j++)
				{
					if(FServer[0].Custom[j] == FCustom[i])
					{
						exists = true;
						FoundID = j;
					}
				}
				if(exists)
				{
					FServer[0].Custom[FoundID] = FCustom[i];
			        FServer[0].PointLights[FoundID].Position = FPosition[i];
			        FServer[0].PointLights[FoundID].Range = FRange[i];
			        FServer[0].PointLights[FoundID].RangePow = FRangePow[i];
			        FServer[0].PointLights[FoundID].LightCol = (Vector4)FLightCol[i];
			        FServer[0].PointLights[FoundID].LightStrength = FLightStrength[i];
					
				}
				else
				{
					if(FCustom[i]!="")
					{
						PointLightObject tmp = new PointLightObject();
				        tmp.Position = FPosition[i];
				        tmp.Range = FRange[i];
				        tmp.RangePow = FRangePow[i];
				        tmp.LightCol = (Vector4)FLightCol[i];
				        tmp.LightStrength = FLightStrength[i];
						FServer[0].PointLights.Add(tmp);
						FServer[0].Custom.Add(FCustom[i]);
					}
				}
			}
		}
	}
	#endregion pointlight
	#region spotlight
    [StructLayout(LayoutKind.Sequential)]
    public struct SpotLightProp
    {
    	public Vector3 Position; // Source
    	public float Range; // Distance
    	public float RangePow; // Fade
    	public Vector4 LightCol;
    	public float LightStrength;
    	public Matrix lProjection;
    	public Matrix lView;
    	public uint TexID;
    }
	public class SpotLightObject
    {
    	public Vector3 Position;
    	public float Range;
    	public float RangePow;
    	public Vector4 LightCol;
    	public float LightStrength;
    	public Matrix lProjection;
    	public Matrix lView;
    	public uint TexID;
    	public SpotLightObject()
    	{
	    	this.Position.X = 0;
	    	this.Position.Y = 0;
	    	this.Position.Z = 0;
    		this.Range = 0;
    		this.RangePow = 0;
	    	this.LightCol.X = 0;
	    	this.LightCol.Y = 0;
	    	this.LightCol.Z = 0;
	    	this.LightCol.W = 1;
	    	this.LightStrength = 0;
    		this.lProjection = Matrix.Identity;
    		this.lView = Matrix.Identity;
    		this.TexID = 0;
    	}
    }
    public class SpotLightServer
    {
    	public List<SpotLightObject> SpotLights;
    	public List<string> Custom;
    	public SpotLightServer()
    	{
	    	this.SpotLights = new List<SpotLightObject>();
	    	this.Custom = new List<string>();
    	}
    }
	#region PluginInfo
	[PluginInfo(Name = "SpotLightServer",
	            Category = "SpotLightManager",
	            Tags = "")]
	#endregion PluginInfo
	public class SpotLightManagerSpotLightServerNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Clear", IsBang = true, IsSingle = true)]
        ISpread<bool> FClear;
		[Output("Output")]
        ISpread<SpotLightServer> FOutput;
		[Output("Custom")]
		ISpread<string> FCustom;
		[Output("Position")]
        ISpread<Vector3> FPosition;
        [Output("Range")]
        ISpread<float> FRange;
        [Output("Range Power")]
        ISpread<float> FRangePow;
        [Output("Light Color")]
        ISpread<Color4> FLightCol;
        [Output("Light Strength")]
        ISpread<float> FLightStrength;
        [Output("View")]
        ISpread<Matrix> FView;
        [Output("Projection")]
        ISpread<Matrix> FProjection;
        [Output("TexID")]
        ISpread<int> FTexID;
		
		private SpotLightServer Everything;
		#endregion fields & pins
 
		[ImportingConstructor]
		public SpotLightManagerSpotLightServerNode()
		{
			this.Everything = new SpotLightServer();
		}
		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{ 
			FOutput.SliceCount = 1;

			FOutput[0] = Everything;
			int MaxID = Everything.Custom.Count;

			FCustom.SliceCount = Math.Max(MaxID,1);
	        FPosition.SliceCount = Math.Max(MaxID,1);
	        FRange.SliceCount = Math.Max(MaxID,1);
	        FRangePow.SliceCount = Math.Max(MaxID,1);
	        FLightCol.SliceCount = Math.Max(MaxID,1);
	        FLightStrength.SliceCount = Math.Max(MaxID,1);
			FView.SliceCount = Math.Max(MaxID,1);
			FProjection.SliceCount = Math.Max(MaxID,1);
			FTexID.SliceCount = Math.Max(MaxID,1);
			
			if(FClear[0])
			{
				Everything.Custom.Clear();
				Everything.SpotLights.Clear();
			}
	        
			for(int i=0; i<Everything.SpotLights.Count; i++)
			{
				FCustom[i] = Everything.Custom[i];
		        FPosition[i] = Everything.SpotLights[i].Position;
		        FRange[i] = Everything.SpotLights[i].Range;
		        FRangePow[i] = Everything.SpotLights[i].RangePow;
		        FLightCol[i] = (Color4)Everything.SpotLights[i].LightCol;
		        FLightStrength[i] = Everything.SpotLights[i].LightStrength;
				FProjection[i] = Everything.SpotLights[i].lProjection;
				FView[i] = Everything.SpotLights[i].lView;
				FTexID[i] = (int)Everything.SpotLights[i].TexID;
			//FLogger.Log(LogType.Debug, "hi tty!");
				
			}
		}
	}
	#region PluginInfo
	[PluginInfo(Name = "GetSpotLight",
	            Category = "SpotLightManager",
	            Tags = "")]
	#endregion PluginInfo
	public class SpotLightManagerGetSpotLightNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("SpotLightServer", IsSingle = true)]
        ISpread<SpotLightServer> FEverything;
		[Input("Custom")]
		ISpread<string> FCustom;
		[Output("Position")]
        ISpread<Vector3> FPosition;
        [Output("Range")]
        ISpread<float> FRange;
        [Output("Range Power")]
        ISpread<float> FRangePow;
        [Output("Light Color")]
        ISpread<Color4> FLightCol;
        [Output("Light Strength")]
        ISpread<float> FLightStrength;
        [Output("View")]
        ISpread<Matrix> FView;
        [Output("Projection")]
        ISpread<Matrix> FProjection;
        [Output("TexID")]
        ISpread<int> FTexID;
		
		#endregion fields & pins
 
		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{ 
			SpotLightServer Everything = FEverything[0];

			int MaxID = Everything.Custom.Count;

	        FPosition.SliceCount = 0;
	        FRange.SliceCount = 0;
	        FRangePow.SliceCount = 0;
	        FLightCol.SliceCount = 0;
	        FLightStrength.SliceCount = 0;
			FView.SliceCount = 0;
			FProjection.SliceCount = 0;
			FTexID.SliceCount = 0;
	        
			for(int i=0; i<Everything.SpotLights.Count; i++)
			{
				if(Everything.Custom[i].Contains(FCustom[0]))
				{
			        FPosition.Add(Everything.SpotLights[i].Position);
			        FRange.Add(Everything.SpotLights[i].Range);
			        FRangePow.Add(Everything.SpotLights[i].RangePow);
			        FLightCol.Add((Color4)Everything.SpotLights[i].LightCol);
			        FLightStrength.Add(Everything.SpotLights[i].LightStrength);
					FProjection.Add(Everything.SpotLights[i].lProjection);
					FView.Add(Everything.SpotLights[i].lView);
					FTexID.Add((int)Everything.SpotLights[i].TexID);
				}
			//FLogger.Log(LogType.Debug, "hi tty!");
				
			}
		}
	}
	
	#region PluginInfo
	[PluginInfo(Name = "SpotLight",
	            Category = "SpotLightManager",
	            Tags = "",
				AutoEvaluate = true)]
	#endregion PluginInfo
	public class SpotLightManagerSpotLightNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("SpotLight Server")]
		IDiffSpread<SpotLightServer> FServer;
		[Input("Custom")]
		ISpread<string> FCustom;
		[Input("Position")]
        ISpread<Vector3> FPosition;
        [Input("Range")]
        ISpread<float> FRange;
        [Input("Range Power")]
        ISpread<float> FRangePow;
        [Input("Light Color")]
        ISpread<Color4> FLightCol;
        [Input("Light Strength")]
        ISpread<float> FLightStrength;
        [Input("View")]
        ISpread<Matrix> FView;
        [Input("Projection")]
        ISpread<Matrix> FProjection;
        [Input("TexID")]
        ISpread<int> FTexID;
		
		#endregion fields & pins
		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			for(int i = 0; i<SpreadMax; i++)
			{
				
				bool exists = false;
				int FoundID = 0;
				for(int j = 0; j<FServer[0].SpotLights.Count; j++)
				{
					if(FServer[0].Custom[j] == FCustom[i])
					{
						exists = true;
						FoundID = j;
					}
				}
				if(exists)
				{
					FServer[0].Custom[FoundID] = FCustom[i];
			        FServer[0].SpotLights[FoundID].Position = FPosition[i];
			        FServer[0].SpotLights[FoundID].Range = FRange[i];
			        FServer[0].SpotLights[FoundID].RangePow = FRangePow[i];
			        FServer[0].SpotLights[FoundID].LightCol = (Vector4)FLightCol[i];
			        FServer[0].SpotLights[FoundID].LightStrength = FLightStrength[i];
			        FServer[0].SpotLights[FoundID].lProjection = FProjection[i];
			        FServer[0].SpotLights[FoundID].lView = FView[i];
			        FServer[0].SpotLights[FoundID].TexID = (uint)FTexID[i];
					
				}
				else
				{
					if(FCustom[i]!="")
					{
						SpotLightObject tmp = new SpotLightObject();
				        tmp.Position = FPosition[i];
				        tmp.Range = FRange[i];
				        tmp.RangePow = FRangePow[i];
				        tmp.LightCol = (Vector4)FLightCol[i];
				        tmp.LightStrength = FLightStrength[i];
				        tmp.lProjection = FProjection[i];
				        tmp.lView = FView[i];
				        tmp.TexID = (uint)FTexID[i];
						FServer[0].SpotLights.Add(tmp);
						FServer[0].Custom.Add(FCustom[i]);
					}
				}
			}
		}
	}
	#endregion spotlight
	#region sunlight
    [StructLayout(LayoutKind.Sequential)]
    public struct SunLightProp
    {
    	public Vector3 Direction; // Source
    	public Vector4 LightCol;
    	public float LightStrength;
    }
	public class SunLightObject
    {
    	public Vector3 Direction;
    	public Vector4 LightCol;
    	public float LightStrength;
    	public SunLightObject()
    	{
	    	this.Direction.X = 0;
	    	this.Direction.Y = 0;
	    	this.Direction.Z = 0;
	    	this.LightCol.X = 0;
	    	this.LightCol.Y = 0;
	    	this.LightCol.Z = 0;
	    	this.LightCol.W = 1;
	    	this.LightStrength = 0;
    	}
    }
    public class SunLightServer
    {
    	public List<SunLightObject> SunLights;
    	public List<string> Custom;
    	public SunLightServer()
    	{
	    	this.SunLights = new List<SunLightObject>();
	    	this.Custom = new List<string>();
    	}
    }
	#region PluginInfo
	[PluginInfo(Name = "SunLightServer",
	            Category = "SunLightManager",
	            Tags = "")]
	#endregion PluginInfo
	public class SunLightManagerSunLightServerNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Clear", IsBang = true, IsSingle = true)]
        ISpread<bool> FClear;
		[Output("Output")]
        ISpread<SunLightServer> FOutput;
		[Output("Custom")]
		ISpread<string> FCustom;
		[Output("Direction")]
        ISpread<Vector3> FDirection;
        [Output("Light Color")]
        ISpread<Color4> FLightCol;
        [Output("Light Strength")]
        ISpread<float> FLightStrength;
		
		private SunLightServer Everything;
		#endregion fields & pins
 
		[ImportingConstructor]
		public SunLightManagerSunLightServerNode()
		{
			this.Everything = new SunLightServer();
		}
		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{ 
			FOutput.SliceCount = 1;

			FOutput[0] = Everything;
			int MaxID = Everything.Custom.Count;

			FCustom.SliceCount = Math.Max(MaxID,1);
	        FDirection.SliceCount = Math.Max(MaxID,1);
	        FLightCol.SliceCount = Math.Max(MaxID,1);
	        FLightStrength.SliceCount = Math.Max(MaxID,1);
			
			if(FClear[0])
			{
				Everything.Custom.Clear();
				Everything.SunLights.Clear();
			}
	        
			for(int i=0; i<Everything.SunLights.Count; i++)
			{
				FCustom[i] = Everything.Custom[i];
		        FDirection[i] = Everything.SunLights[i].Direction;
		        FLightCol[i] = (Color4)Everything.SunLights[i].LightCol;
		        FLightStrength[i] = Everything.SunLights[i].LightStrength;
			//FLogger.Log(LogType.Debug, "hi tty!");
				
			}
		}
	}
	
	#region PluginInfo
	[PluginInfo(Name = "SunLight",
	            Category = "SunLightManager",
	            Tags = "",
				AutoEvaluate = true)]
	#endregion PluginInfo
	public class SunLightManagerSunLightNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("SunLight Server")]
		IDiffSpread<SunLightServer> FServer;
		[Input("Custom")]
		ISpread<string> FCustom;
		[Input("Direction")]
        ISpread<Vector3> FDirection;
        [Input("Light Color")]
        ISpread<Color4> FLightCol;
        [Input("Light Strength")]
        ISpread<float> FLightStrength;
		
		#endregion fields & pins
		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			for(int i = 0; i<SpreadMax; i++)
			{
				
				bool exists = false;
				int FoundID = 0;
				for(int j = 0; j<FServer[0].SunLights.Count; j++)
				{
					if(FServer[0].Custom[j] == FCustom[i])
					{
						exists = true;
						FoundID = j;
					}
				}
				if(exists)
				{
					FServer[0].Custom[FoundID] = FCustom[i];
			        FServer[0].SunLights[FoundID].Direction = FDirection[i];
			        FServer[0].SunLights[FoundID].LightCol = (Vector4)FLightCol[i];
			        FServer[0].SunLights[FoundID].LightStrength = FLightStrength[i];
					
				}
				else
				{
					if(FCustom[i]!="")
					{
						SunLightObject tmp = new SunLightObject();
				        tmp.Direction = FDirection[i];
				        tmp.LightCol = (Vector4)FLightCol[i];
				        tmp.LightStrength = FLightStrength[i];
						FServer[0].SunLights.Add(tmp);
						FServer[0].Custom.Add(FCustom[i]);
					}
				}
			}
		}
	}
	#endregion sunlight
	#region reflectrefract
	/*
    [StructLayout(LayoutKind.Sequential)]
    public struct ReflectRefractProp
    {
    	public Vector3 Direction; // Source
    	public Vector4 LightCol;
    	public float LightStrength;
    }
	public class ReflectRefractObject
    {
    	public Vector3 Direction;
    	public Vector4 LightCol;
    	public float LightStrength;
    	public ReflectRefractObject()
    	{
	    	this.Direction.X = 0;
	    	this.Direction.Y = 0;
	    	this.Direction.Z = 0;
	    	this.LightCol.X = 0;
	    	this.LightCol.Y = 0;
	    	this.LightCol.Z = 0;
	    	this.LightCol.W = 1;
	    	this.LightStrength = 0;
    	}
    }
    public class ReflectRefractServer
    {
    	public List<ReflectRefractObject> ReflectRefractObjects
    	public List<string> Custom;
    	public ReflectRefractServer()
    	{
	    	this.ReflectRefractObjects = new List<ReflectRefractObject>();
	    	this.Custom = new List<string>();
    	}
    }
	#region PluginInfo
	[PluginInfo(Name = "ReflectRefractServer",
	            Category = "ReflectRefractManager",
	            Tags = "")]
	#endregion PluginInfo
	public class ReflectRefractManagerReflectRefractServerNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Clear", IsBang = true, IsSingle = true)]
        ISpread<bool> FClear;
		[Output("Output")]
        ISpread<ReflectRefractServer> FOutput;
		[Output("Custom")]
		ISpread<string> FCustom;
		[Output("Direction")]
        ISpread<Vector3> FDirection;
        [Output("Light Color")]
        ISpread<Color4> FLightCol;
        [Output("Light Strength")]
        ISpread<float> FLightStrength;
		
		private ReflectRefractServer Everything;
		#endregion fields & pins
 
		[ImportingConstructor]
		public ReflectRefractManagerReflectRefractServerNode()
		{
			this.Everything = new ReflectRefractServer();
		}
		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{ 
			FOutput.SliceCount = 1;

			FOutput[0] = Everything;
			int MaxID = Everything.Custom.Count;

			FCustom.SliceCount = Math.Max(MaxID,1);
	        FDirection.SliceCount = Math.Max(MaxID,1);
	        FLightCol.SliceCount = Math.Max(MaxID,1);
	        FLightStrength.SliceCount = Math.Max(MaxID,1);
			
			if(FClear[0])
			{
				Everything.Custom.Clear();
				Everything.ReflectRefractObjects.Clear();
			}
	        
			for(int i=0; i<Everything.ReflectRefractObjects.Count; i++)
			{
				FCustom[i] = Everything.Custom[i];
		        FDirection[i] = Everything.ReflectRefractObjects[i].Direction;
		        FLightCol[i] = (Color4)Everything.ReflectRefractObjects[i].LightCol;
		        FLightStrength[i] = Everything.ReflectRefractObjects[i].LightStrength;
			//FLogger.Log(LogType.Debug, "hi tty!");
				
			}
		}
	}
	
	#region PluginInfo
	[PluginInfo(Name = "ReflectRefract",
	            Category = "ReflectRefractManager",
	            Tags = "",
				AutoEvaluate = true)]
	#endregion PluginInfo
	public class ReflectRefractManagerReflectRefractNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("ReflectRefract Server")]
		IDiffSpread<ReflectRefractServer> FServer;
		[Input("Custom")]
		ISpread<string> FCustom;
		[Input("Direction")]
        ISpread<Vector3> FDirection;
        [Input("Light Color")]
        ISpread<Color4> FLightCol;
        [Input("Light Strength")]
        ISpread<float> FLightStrength;
		
		#endregion fields & pins
		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			for(int i = 0; i<SpreadMax; i++)
			{
				
				bool exists = false;
				int FoundID = 0;
				for(int j = 0; j<FServer[0].ReflectRefractObjects.Count; j++)
				{
					if(FServer[0].Custom[j] == FCustom[i])
					{
						exists = true;
						FoundID = j;
					}
				}
				if(exists)
				{
					FServer[0].Custom[FoundID] = FCustom[i];
			        FServer[0].ReflectRefractObjects[FoundID].Direction = FDirection[i];
			        FServer[0].ReflectRefractObjects[FoundID].LightCol = (Vector4)FLightCol[i];
			        FServer[0].ReflectRefractObjects[FoundID].LightStrength = FLightStrength[i];
					
				}
				else
				{
					if(FCustom[i]!="")
					{
						ReflectRefractObject tmp = new ReflectRefractObject();
				        tmp.Direction = FDirection[i];
				        tmp.LightCol = (Vector4)FLightCol[i];
				        tmp.LightStrength = FLightStrength[i];
						FServer[0].ReflectRefractObjects.Add(tmp);
						FServer[0].Custom.Add(FCustom[i]);
					}
				}
			}
		}
	}*/
	#endregion reflectrefract
	#endregion management
	
	#region buffers
	#region scene
    [PluginInfo(Name = "DynamicBuffer", Category = "DX11.Buffer", Version = "DeferredBase", Author = "microdee")]
    public class DeferredBaseDynamicBuffer : DynamicArrayBuffer<DeferredBase>
    {
        [Input("World Transform", AutoValidate = false)]
        protected ISpread<Matrix> FtW;
        [Input("Previous World Transform", AutoValidate = false)]
        protected ISpread<Matrix> FptW;
        [Input("Texture Transform", AutoValidate = false)]
        protected ISpread<Matrix> FtTex;
        [Input("Diffuse Amount", AutoValidate = false)]
        protected ISpread<float> FDiffAmount;
        [Input("Diffuse Color", AutoValidate = false)]
        protected ISpread<Color4> FDiffCol;
        [Input("Velocity Gain", AutoValidate = false)]
        protected ISpread<float> FVelocityGain;
        [Input("Bump Amount", AutoValidate = false)]
        protected ISpread<float> FBumpAmount;
        [Input("Displace Amount", AutoValidate = false)]
        protected ISpread<float> FDispAmount;
        [Input("Previous Displace Amount", AutoValidate = false)]
        protected ISpread<float> FPDispAmount;
        [Input("Material ID", AutoValidate = false)]
        protected ISpread<uint> FMatID;
        [Input("Object ID", AutoValidate = false)]
        protected ISpread<Vector3> FObjID;

        protected override void BuildBuffer(int count, DeferredBase[] buffer)
        {
            this.FBumpAmount.Sync();
            this.FDiffAmount.Sync();
            this.FDiffCol.Sync();
            this.FDispAmount.Sync();
            this.FPDispAmount.Sync();
            this.FtW.Sync();
            this.FptW.Sync();
            this.FtTex.Sync();
            this.FVelocityGain.Sync();
        	this.FMatID.Sync();
        	this.FObjID.Sync();

            for (int i = 0; i < count; i++)
            {
            	Matrix tempout;
            	Matrix tempin = this.FtW[i];
            	Matrix.Transpose(ref tempin, out tempout);
                buffer[i].tW = tempout;
            	tempin = this.FptW[i];
            	Matrix.Transpose(ref tempin, out tempout);
                buffer[i].ptW = tempout;
            	tempin = this.FtTex[i];
            	Matrix.Transpose(ref tempin, out tempout);
                buffer[i].tTex = tempout;
                buffer[i].DiffAmount = this.FDiffAmount[i];
                buffer[i].DiffCol = (Vector4)this.FDiffCol[i];
                buffer[i].VelocityGain = this.FVelocityGain[i];
                buffer[i].BumpAmount = this.FBumpAmount[i];
                buffer[i].DispAmount = this.FDispAmount[i];
                buffer[i].pDispAmount = this.FPDispAmount[i];
                buffer[i].MatID = this.FMatID[i];
                buffer[i].ObjID0 = (int)this.FObjID[i].X;
                buffer[i].ObjID1 = (int)this.FObjID[i].Y;
                buffer[i].ObjID2 = (int)this.FObjID[i].Z;
            }
        }
    }
    [PluginInfo(Name = "DynamicBuffer", Category = "DX11.Buffer", Version = "DeferredBaseProperties", Author = "microdee")]
    public class DeferredBasePropertiesDynamicBuffer : DynamicArrayBuffer<DeferredBaseProperties>
    {
        [Input("Diffuse Amount", AutoValidate = false)]
        protected ISpread<float> FDiffAmount;
        [Input("Diffuse Color", AutoValidate = false)]
        protected ISpread<Vector4> FDiffCol;
        [Input("Velocity Gain", AutoValidate = false)]
        protected ISpread<float> FVelocityGain;
        [Input("Bump Amount", AutoValidate = false)]
        protected ISpread<float> FBumpAmount;
        [Input("Displace Amount", AutoValidate = false)]
        protected ISpread<float> FDispAmount;
        [Input("Previous Displace Amount", AutoValidate = false)]
        protected ISpread<float> FPDispAmount;
        [Input("Material ID", AutoValidate = false)]
        protected ISpread<uint> FMatID;
        

        protected override void BuildBuffer(int count, DeferredBaseProperties[] buffer)
        {
            this.FBumpAmount.Sync();
            this.FDiffAmount.Sync();
            this.FDiffCol.Sync();
            this.FDispAmount.Sync();
            this.FPDispAmount.Sync();
            this.FVelocityGain.Sync();
        	this.FMatID.Sync();

            for (int i = 0; i < count; i++)
            {
                buffer[i].DiffAmount = this.FDiffAmount[i];
                buffer[i].DiffCol = this.FDiffCol[i];
                buffer[i].VelocityGain = this.FVelocityGain[i];
                buffer[i].BumpAmount = this.FBumpAmount[i];
                buffer[i].DispAmount = this.FDispAmount[i];
                buffer[i].pDispAmount = this.FPDispAmount[i];
                buffer[i].MatID = this.FMatID[i];
            }
        }
    }
	#endregion scene
	#region materials
    [PluginInfo(Name = "DynamicBuffer", Category = "DX11.Buffer", Version = "MaterialProp", Author = "microdee")]
    public class MaterialPropDynamicBuffer : DynamicArrayBuffer<MaterialProp>
    {

        [Input("Attenuation", AutoValidate = false)]
        protected ISpread<Vector3> FAtten;
        [Input("Specular Power", AutoValidate = false)]
        protected ISpread<float> FPow;
        [Input("Ambient Color", AutoValidate = false)]
        protected ISpread<Color4> FAmbCol;
        [Input("Specular Color", AutoValidate = false)]
        protected ISpread<Color4> FSpecCol;
        [Input("Specular Amount", AutoValidate = false)]
        protected ISpread<float> FSpecAmount;
        [Input("Emission Color", AutoValidate = false)]
        protected ISpread<Color4> FEmCol;
        [Input("Emission Amount", AutoValidate = false)]
        protected ISpread<float> FEmAmount;
        [Input("SSS Amount", AutoValidate = false)]
        protected ISpread<float> FSSSAmount;
        [Input("SSS Power", AutoValidate = false)]
        protected ISpread<float> FSSSPower;
        [Input("SSS Material Thickness", AutoValidate = false)]
        protected ISpread<float> FMatThick;
        [Input("Rim Light Amount", AutoValidate = false)]
        protected ISpread<float> FRimLAmount;
        [Input("Rim Light Power", AutoValidate = false)]
        protected ISpread<float> FRimLPower;
        [Input("Extinction Coefficient", AutoValidate = false)]
        protected ISpread<Color4> FSSSExtCoeff;
        [Input("Reflection", AutoValidate = false)]
        protected ISpread<float> FReflection;
        [Input("Refraction", AutoValidate = false)]
        protected ISpread<float> FRefraction;
        [Input("ReflectRefractTexID", AutoValidate = false)]
        protected ISpread<int> FReflectRefractTexID;
        

        protected override void BuildBuffer(int count, MaterialProp[] buffer)
        {
            this.FAtten.Sync();
            this.FPow.Sync();
            this.FAmbCol.Sync();
            this.FSpecCol.Sync();
            this.FSpecAmount.Sync();
            this.FEmCol.Sync();
            this.FEmAmount.Sync();
            this.FSSSAmount.Sync();
            this.FSSSPower.Sync();
            this.FMatThick.Sync();
            this.FRimLAmount.Sync();
            this.FRimLPower.Sync();
            this.FSSSExtCoeff.Sync();
            this.FReflection.Sync();
            this.FRefraction.Sync();
            this.FReflectRefractTexID.Sync();

            for (int i = 0; i < count; i++)
            {
                buffer[i].Atten = this.FAtten[i];
                buffer[i].Power = this.FPow[i];
                buffer[i].AmbCol = (Vector4)this.FAmbCol[i];
                buffer[i].SpecCol = (Vector4)this.FSpecCol[i];
                buffer[i].SpecAmount = this.FSpecAmount[i];
                buffer[i].EmCol = (Vector4)this.FEmCol[i];
                buffer[i].EmAmount = this.FEmAmount[i];
                buffer[i].SSSAmount = this.FSSSAmount[i];
                buffer[i].SSSPower = this.FSSSPower[i];
                buffer[i].MatThick = this.FMatThick[i];
                buffer[i].RimLAmount = this.FRimLAmount[i];
                buffer[i].RimLPower = this.FRimLPower[i];
                buffer[i].SSSExtCoeff = (Vector4)this.FSSSExtCoeff[i];
                buffer[i].Reflection = this.FReflection[i];
                buffer[i].Refraction = this.FRefraction[i];
                buffer[i].ReflectRefractTexID = (uint)this.FReflectRefractTexID[i];
            }
        }
    }
	#endregion materials
	#region pointlight
    [PluginInfo(Name = "DynamicBuffer", Category = "DX11.Buffer", Version = "PointLightProp", Author = "microdee")]
    public class PointLightPropDynamicBuffer : DynamicArrayBuffer<PointLightProp>
    {

        [Input("Position", AutoValidate = false)]
        protected ISpread<Vector3> FPosition;
        [Input("Range", AutoValidate = false)]
        protected ISpread<float> FRange;
        [Input("Range Power", AutoValidate = false)]
        protected ISpread<float> FRangePow;
        [Input("Color", AutoValidate = false)]
        protected ISpread<Color4> FLightCol;
        [Input("Strength", AutoValidate = false)]
        protected ISpread<float> FLightStrength;
        

        protected override void BuildBuffer(int count, PointLightProp[] buffer)
        {
            this.FPosition.Sync();
            this.FRange.Sync();
            this.FRangePow.Sync();
            this.FLightCol.Sync();
            this.FLightStrength.Sync();

            for (int i = 0; i < count; i++)
            {
                buffer[i].Position = FPosition[i];
                buffer[i].Range = FRange[i];
                buffer[i].RangePow = FRangePow[i];
                buffer[i].LightCol = (Vector4)FLightCol[i];
                buffer[i].LightStrength = FLightStrength[i];
            }
        }
    }
	#endregion pointlight
	#region spotlight
    [PluginInfo(Name = "DynamicBuffer", Category = "DX11.Buffer", Version = "SpotLightProp", Author = "microdee")]
    public class SpotLightPropDynamicBuffer : DynamicArrayBuffer<SpotLightProp>
    {

        [Input("Position", AutoValidate = false)]
        protected ISpread<Vector3> FPosition;
        [Input("Range", AutoValidate = false)]
        protected ISpread<float> FRange;
        [Input("Range Power", AutoValidate = false)]
        protected ISpread<float> FRangePow;
        [Input("Color", AutoValidate = false)]
        protected ISpread<Color4> FLightCol;
        [Input("Strength", AutoValidate = false)]
        protected ISpread<float> FLightStrength;
        [Input("View", AutoValidate = false)]
        protected ISpread<Matrix> FView;
        [Input("Projection", AutoValidate = false)]
        protected ISpread<Matrix> FProjection;
        [Input("TexID", AutoValidate = false)]
        protected ISpread<int> FTexID;
        

        protected override void BuildBuffer(int count, SpotLightProp[] buffer)
        {
            this.FPosition.Sync();
            this.FRange.Sync();
            this.FRangePow.Sync();
            this.FLightCol.Sync();
            this.FLightStrength.Sync();
            this.FProjection.Sync();
            this.FView.Sync();
            this.FTexID.Sync();

            for (int i = 0; i < count; i++)
            {
                buffer[i].Position = FPosition[i];
                buffer[i].Range = FRange[i];
                buffer[i].RangePow = FRangePow[i];
                buffer[i].LightCol = (Vector4)FLightCol[i];
                buffer[i].LightStrength = FLightStrength[i];
                buffer[i].lProjection = FProjection[i];
                buffer[i].lView = FView[i];
                buffer[i].TexID = (uint)FTexID[i];
            }
        }
    }
	#endregion spotlight
	#region sunlight
    [PluginInfo(Name = "DynamicBuffer", Category = "DX11.Buffer", Version = "SunLightProp", Author = "microdee")]
    public class SunLightPropDynamicBuffer : DynamicArrayBuffer<SunLightProp>
    {

        [Input("Position", AutoValidate = false)]
        protected ISpread<Vector3> FDirection;
        [Input("Color", AutoValidate = false)]
        protected ISpread<Color4> FLightCol;
        [Input("Strength", AutoValidate = false)]
        protected ISpread<float> FLightStrength;
        

        protected override void BuildBuffer(int count, SunLightProp[] buffer)
        {
            this.FDirection.Sync();
            this.FLightCol.Sync();
            this.FLightStrength.Sync();

            for (int i = 0; i < count; i++)
            {
                buffer[i].Direction = FDirection[i];
                buffer[i].LightCol = (Vector4)FLightCol[i];
                buffer[i].LightStrength = FLightStrength[i];
            }
        }
    }
	#endregion sunlight
	#endregion buffers
}