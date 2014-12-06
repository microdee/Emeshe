#region usings
using System;
using System.ComponentModel.Composition;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
#endregion usings

namespace VVVV.Nodes
{
	#region PluginInfo
	[PluginInfo(Name = "RouteMaterialData", Category = "MRE", Version = "Materials", Help = "Basic template with one value in/out", Tags = "")]
	#endregion PluginInfo
	public class MaterialsMRERouteMaterialDataNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Material ID's", DefaultValue = 1.0)]
		public ISpread<int> FMatID;
		[Input("Flags")]
		public ISpread<uint> FFlags;
		[Input("Address")]
		public ISpread<uint> FAdress;
		[Input("Size")]
		public ISpread<uint> FSize;
		
		[Input("Feature ID")]
		public ISpread<ISpread<int>> FFeatureID;
		[Input("Feature Offset")]
		public ISpread<ISpread<uint>> FFeatureOffs;
		
		[Input("Flags Size")]
		public ISpread<int> FFlagSize;

		[Output("Flags Output")]
		public ISpread<uint> FFlagsOut;
		[Output("Address Output")]
		public ISpread<uint> FAdressOut;
		[Output("Size Output")]
		public ISpread<uint> FSizeOut;

		[Output("Feature Offset Out")]
		public ISpread<ISpread<uint>> FFeatureOffsOut;
		
		[Import()]
		public ILogger FLogger;
		#endregion fields & pins

		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			SpreadMax = 0;
			for(int i=0; i<FMatID.SliceCount; i++)
				SpreadMax = Math.Max(SpreadMax, FMatID[i])+1;
			
			FFlagsOut.SliceCount = SpreadMax;
			FAdressOut.SliceCount = SpreadMax;
			FSizeOut.SliceCount = SpreadMax;
			FFeatureOffsOut.SliceCount = SpreadMax;
			
			for(int i=0; i<SpreadMax; i++)
				FFeatureOffsOut[i].SliceCount = FFlagSize[0];
			
			for(int i=0; i<FMatID.SliceCount; i++)
			{
				int mi = FMatID[i];
				
				FFlagsOut[mi] = FFlags[i];
				FAdressOut[mi] = FAdress[i];
				FSizeOut[mi] = FSize[i];
				
				for(int j=0; j<FFeatureID[i].SliceCount; j++)
				{
					int fi = FFeatureID[i][j];
					FFeatureOffsOut[mi][fi] = FFeatureOffs[i][j];
				}
			}
		}
	}
}
