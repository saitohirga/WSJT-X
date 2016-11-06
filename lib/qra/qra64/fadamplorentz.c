/*
fadamplorentz.c
Lorentz fading tables for QRA64 modes

(c) 2016 - Nico Palermo, IV3NWV

This file is part of the qracodes project, a Forward Error Control
encoding/decoding package based on Q-ary RA (Repeat and Accumulate) LDPC codes.
-------------------------------------------------------------------------------

   qracodes is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   qracodes is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with qracodes source distribution.  
   If not, see <http://www.gnu.org/licenses/>.

-----------------------------------------------------------------------------
*/

static const int hlen_tab_lorentz[64] = {
  2,   2,   2,   2,   2,   2,   2,   2, 
  2,   2,   2,   2,   2,   2,   3,   3, 
  3,   3,   3,   3,   3,   4,   4,   4, 
  4,   4,   5,   5,   5,   5,   6,   6, 
  7,   7,   7,   8,   8,   9,  10,  10, 
 11,  12,  13,  14,  15,  16,  17,  19, 
 20,  22,  23,  25,  27,  30,  32,  35, 
 38,  41,  45,  49,  53,  57,  62,  65
};
static const float hlorentz1[2] = {
0.1464f, 0.9543f
};
static const float hlorentz2[2] = {
0.1563f, 0.9503f
};
static const float hlorentz3[2] = {
0.1672f, 0.9461f
};
static const float hlorentz4[2] = {
0.1773f, 0.9415f
};
static const float hlorentz5[2] = {
0.1868f, 0.9367f
};
static const float hlorentz6[2] = {
0.1970f, 0.9314f
};
static const float hlorentz7[2] = {
0.2063f, 0.9258f
};
static const float hlorentz8[2] = {
0.2151f, 0.9197f
};
static const float hlorentz9[2] = {
0.2236f, 0.9132f
};
static const float hlorentz10[2] = {
0.2320f, 0.9061f
};
static const float hlorentz11[2] = {
0.2406f, 0.8986f
};
static const float hlorentz12[2] = {
0.2494f, 0.8905f
};
static const float hlorentz13[2] = {
0.2584f, 0.8819f
};
static const float hlorentz14[2] = {
0.2674f, 0.8727f
};
static const float hlorentz15[3] = {
0.1400f, 0.2765f, 0.8629f
};
static const float hlorentz16[3] = {
0.1451f, 0.2857f, 0.8525f
};
static const float hlorentz17[3] = {
0.1504f, 0.2949f, 0.8414f
};
static const float hlorentz18[3] = {
0.1557f, 0.3041f, 0.8298f
};
static const float hlorentz19[3] = {
0.1611f, 0.3133f, 0.8174f
};
static const float hlorentz20[3] = {
0.1666f, 0.3223f, 0.8045f
};
static const float hlorentz21[3] = {
0.1721f, 0.3312f, 0.7909f
};
static const float hlorentz22[4] = {
0.1195f, 0.1778f, 0.3399f, 0.7766f
};
static const float hlorentz23[4] = {
0.1235f, 0.1835f, 0.3483f, 0.7618f
};
static const float hlorentz24[4] = {
0.1277f, 0.1893f, 0.3564f, 0.7463f
};
static const float hlorentz25[4] = {
0.1319f, 0.1952f, 0.3641f, 0.7303f
};
static const float hlorentz26[4] = {
0.1362f, 0.2011f, 0.3712f, 0.7138f
};
static const float hlorentz27[5] = {
0.1062f, 0.1407f, 0.2071f, 0.3779f, 0.6967f
};
static const float hlorentz28[5] = {
0.1097f, 0.1452f, 0.2132f, 0.3839f, 0.6793f
};
static const float hlorentz29[5] = {
0.1134f, 0.1499f, 0.2193f, 0.3891f, 0.6615f
};
static const float hlorentz30[5] = {
0.1172f, 0.1546f, 0.2254f, 0.3936f, 0.6434f
};
static const float hlorentz31[6] = {
0.0974f, 0.1211f, 0.1595f, 0.2314f, 0.3973f, 0.6251f
};
static const float hlorentz32[6] = {
0.1007f, 0.1251f, 0.1645f, 0.2374f, 0.4000f, 0.6066f
};
static const float hlorentz33[7] = {
0.0872f, 0.1042f, 0.1292f, 0.1695f, 0.2434f, 0.4017f, 0.5880f
};
static const float hlorentz34[7] = {
0.0902f, 0.1077f, 0.1335f, 0.1747f, 0.2491f, 0.4025f, 0.5694f
};
static const float hlorentz35[7] = {
0.0934f, 0.1114f, 0.1379f, 0.1799f, 0.2547f, 0.4022f, 0.5509f
};
static const float hlorentz36[8] = {
0.0832f, 0.0967f, 0.1152f, 0.1423f, 0.1851f, 0.2600f, 0.4008f, 0.5325f
};
static const float hlorentz37[8] = {
0.0862f, 0.1001f, 0.1192f, 0.1469f, 0.1903f, 0.2649f, 0.3985f, 0.5143f
};
static const float hlorentz38[9] = {
0.0784f, 0.0893f, 0.1036f, 0.1232f, 0.1515f, 0.1955f, 0.2694f, 0.3950f, 
0.4964f
};
static const float hlorentz39[10] = {
0.0724f, 0.0813f, 0.0925f, 0.1072f, 0.1273f, 0.1562f, 0.2005f, 0.2733f, 
0.3906f, 0.4787f
};
static const float hlorentz40[10] = {
0.0751f, 0.0842f, 0.0958f, 0.1109f, 0.1315f, 0.1609f, 0.2054f, 0.2767f, 
0.3853f, 0.4614f
};
static const float hlorentz41[11] = {
0.0703f, 0.0779f, 0.0873f, 0.0992f, 0.1148f, 0.1358f, 0.1656f, 0.2101f, 
0.2794f, 0.3790f, 0.4444f
};
static const float hlorentz42[12] = {
0.0665f, 0.0730f, 0.0808f, 0.0905f, 0.1027f, 0.1187f, 0.1401f, 0.1702f, 
0.2145f, 0.2813f, 0.3720f, 0.4278f
};
static const float hlorentz43[13] = {
0.0634f, 0.0690f, 0.0757f, 0.0838f, 0.0938f, 0.1063f, 0.1226f, 0.1444f, 
0.1747f, 0.2185f, 0.2824f, 0.3643f, 0.4117f
};
static const float hlorentz44[14] = {
0.0609f, 0.0658f, 0.0716f, 0.0785f, 0.0869f, 0.0971f, 0.1100f, 0.1266f, 
0.1487f, 0.1791f, 0.2220f, 0.2826f, 0.3559f, 0.3960f
};
static const float hlorentz45[15] = {
0.0588f, 0.0632f, 0.0683f, 0.0743f, 0.0814f, 0.0900f, 0.1005f, 0.1137f, 
0.1306f, 0.1529f, 0.1831f, 0.2250f, 0.2820f, 0.3470f, 0.3808f
};
static const float hlorentz46[16] = {
0.0571f, 0.0611f, 0.0657f, 0.0709f, 0.0771f, 0.0844f, 0.0932f, 0.1040f, 
0.1175f, 0.1346f, 0.1570f, 0.1869f, 0.2274f, 0.2804f, 0.3377f, 0.3660f
};
static const float hlorentz47[17] = {
0.0557f, 0.0594f, 0.0635f, 0.0682f, 0.0736f, 0.0800f, 0.0875f, 0.0965f, 
0.1076f, 0.1212f, 0.1385f, 0.1609f, 0.1903f, 0.2292f, 0.2781f, 0.3281f, 
0.3517f
};
static const float hlorentz48[19] = {
0.0516f, 0.0546f, 0.0579f, 0.0617f, 0.0659f, 0.0708f, 0.0764f, 0.0829f, 
0.0906f, 0.0999f, 0.1111f, 0.1249f, 0.1423f, 0.1645f, 0.1933f, 0.2302f, 
0.2748f, 0.3182f, 0.3379f
};
static const float hlorentz49[20] = {
0.0509f, 0.0537f, 0.0567f, 0.0602f, 0.0640f, 0.0684f, 0.0734f, 0.0792f, 
0.0859f, 0.0938f, 0.1032f, 0.1146f, 0.1286f, 0.1460f, 0.1679f, 0.1957f, 
0.2305f, 0.2709f, 0.3082f, 0.3245f
};
static const float hlorentz50[22] = {
0.0480f, 0.0504f, 0.0529f, 0.0558f, 0.0589f, 0.0625f, 0.0665f, 0.0710f, 
0.0761f, 0.0821f, 0.0889f, 0.0970f, 0.1066f, 0.1181f, 0.1321f, 0.1494f, 
0.1709f, 0.1976f, 0.2300f, 0.2662f, 0.2981f, 0.3115f
};
static const float hlorentz51[23] = {
0.0477f, 0.0499f, 0.0523f, 0.0550f, 0.0580f, 0.0612f, 0.0649f, 0.0690f, 
0.0736f, 0.0789f, 0.0850f, 0.0920f, 0.1002f, 0.1099f, 0.1215f, 0.1355f, 
0.1526f, 0.1735f, 0.1989f, 0.2288f, 0.2609f, 0.2880f, 0.2991f
};
static const float hlorentz52[25] = {
0.0456f, 0.0475f, 0.0496f, 0.0519f, 0.0544f, 0.0572f, 0.0602f, 0.0636f, 
0.0673f, 0.0715f, 0.0763f, 0.0817f, 0.0879f, 0.0951f, 0.1034f, 0.1132f, 
0.1248f, 0.1387f, 0.1554f, 0.1755f, 0.1995f, 0.2268f, 0.2550f, 0.2779f, 
0.2870f
};
static const float hlorentz53[27] = {
0.0438f, 0.0456f, 0.0474f, 0.0494f, 0.0516f, 0.0539f, 0.0565f, 0.0594f, 
0.0625f, 0.0660f, 0.0698f, 0.0742f, 0.0790f, 0.0846f, 0.0909f, 0.0981f, 
0.1065f, 0.1164f, 0.1279f, 0.1416f, 0.1579f, 0.1771f, 0.1994f, 0.2242f, 
0.2487f, 0.2680f, 0.2754f
};
static const float hlorentz54[30] = {
0.0410f, 0.0424f, 0.0440f, 0.0456f, 0.0474f, 0.0493f, 0.0513f, 0.0536f, 
0.0560f, 0.0587f, 0.0616f, 0.0648f, 0.0684f, 0.0724f, 0.0768f, 0.0818f, 
0.0874f, 0.0938f, 0.1011f, 0.1096f, 0.1194f, 0.1308f, 0.1442f, 0.1599f, 
0.1781f, 0.1987f, 0.2208f, 0.2421f, 0.2582f, 0.2643f
};
static const float hlorentz55[32] = {
0.0400f, 0.0413f, 0.0427f, 0.0441f, 0.0457f, 0.0474f, 0.0492f, 0.0512f, 
0.0533f, 0.0557f, 0.0582f, 0.0609f, 0.0639f, 0.0672f, 0.0709f, 0.0749f, 
0.0795f, 0.0845f, 0.0902f, 0.0967f, 0.1041f, 0.1125f, 0.1222f, 0.1334f, 
0.1464f, 0.1614f, 0.1785f, 0.1973f, 0.2169f, 0.2351f, 0.2485f, 0.2535f
};
static const float hlorentz56[35] = {
0.0380f, 0.0391f, 0.0403f, 0.0416f, 0.0429f, 0.0444f, 0.0459f, 0.0475f, 
0.0493f, 0.0512f, 0.0532f, 0.0554f, 0.0578f, 0.0604f, 0.0632f, 0.0663f, 
0.0697f, 0.0734f, 0.0775f, 0.0821f, 0.0873f, 0.0930f, 0.0995f, 0.1069f, 
0.1153f, 0.1248f, 0.1358f, 0.1483f, 0.1624f, 0.1782f, 0.1952f, 0.2125f, 
0.2280f, 0.2391f, 0.2432f
};
static const float hlorentz57[38] = {
0.0364f, 0.0374f, 0.0384f, 0.0395f, 0.0407f, 0.0419f, 0.0432f, 0.0446f, 
0.0461f, 0.0477f, 0.0494f, 0.0512f, 0.0531f, 0.0552f, 0.0575f, 0.0599f, 
0.0626f, 0.0655f, 0.0686f, 0.0721f, 0.0759f, 0.0801f, 0.0848f, 0.0899f, 
0.0957f, 0.1022f, 0.1095f, 0.1178f, 0.1271f, 0.1377f, 0.1496f, 0.1629f, 
0.1774f, 0.1926f, 0.2076f, 0.2207f, 0.2299f, 0.2332f
};
static const float hlorentz58[41] = {
0.0351f, 0.0360f, 0.0369f, 0.0379f, 0.0389f, 0.0400f, 0.0411f, 0.0423f, 
0.0436f, 0.0450f, 0.0464f, 0.0479f, 0.0496f, 0.0513f, 0.0532f, 0.0552f, 
0.0573f, 0.0596f, 0.0621f, 0.0648f, 0.0678f, 0.0710f, 0.0745f, 0.0784f, 
0.0826f, 0.0873f, 0.0925f, 0.0983f, 0.1048f, 0.1120f, 0.1201f, 0.1291f, 
0.1392f, 0.1505f, 0.1628f, 0.1759f, 0.1894f, 0.2023f, 0.2134f, 0.2209f, 
0.2237f
};
static const float hlorentz59[45] = {
0.0333f, 0.0341f, 0.0349f, 0.0357f, 0.0366f, 0.0375f, 0.0384f, 0.0394f, 
0.0405f, 0.0416f, 0.0428f, 0.0440f, 0.0453f, 0.0467f, 0.0482f, 0.0498f, 
0.0515f, 0.0532f, 0.0552f, 0.0572f, 0.0594f, 0.0618f, 0.0643f, 0.0671f, 
0.0701f, 0.0734f, 0.0770f, 0.0809f, 0.0851f, 0.0898f, 0.0950f, 0.1008f, 
0.1071f, 0.1142f, 0.1221f, 0.1307f, 0.1403f, 0.1508f, 0.1621f, 0.1739f, 
0.1857f, 0.1968f, 0.2060f, 0.2123f, 0.2145f
};
static const float hlorentz60[49] = {
0.0319f, 0.0325f, 0.0332f, 0.0339f, 0.0347f, 0.0355f, 0.0363f, 0.0371f, 
0.0380f, 0.0390f, 0.0400f, 0.0410f, 0.0421f, 0.0432f, 0.0444f, 0.0457f, 
0.0471f, 0.0485f, 0.0500f, 0.0517f, 0.0534f, 0.0552f, 0.0572f, 0.0593f, 
0.0615f, 0.0640f, 0.0666f, 0.0694f, 0.0724f, 0.0757f, 0.0793f, 0.0833f, 
0.0875f, 0.0922f, 0.0974f, 0.1030f, 0.1093f, 0.1161f, 0.1237f, 0.1319f, 
0.1409f, 0.1506f, 0.1608f, 0.1713f, 0.1816f, 0.1910f, 0.1987f, 0.2038f, 
0.2056f
};
static const float hlorentz61[53] = {
0.0307f, 0.0313f, 0.0319f, 0.0325f, 0.0332f, 0.0338f, 0.0346f, 0.0353f, 
0.0361f, 0.0369f, 0.0377f, 0.0386f, 0.0395f, 0.0405f, 0.0415f, 0.0426f, 
0.0437f, 0.0449f, 0.0462f, 0.0475f, 0.0489f, 0.0504f, 0.0519f, 0.0536f, 
0.0553f, 0.0572f, 0.0592f, 0.0614f, 0.0637f, 0.0661f, 0.0688f, 0.0716f, 
0.0747f, 0.0780f, 0.0816f, 0.0856f, 0.0898f, 0.0945f, 0.0996f, 0.1051f, 
0.1111f, 0.1177f, 0.1249f, 0.1327f, 0.1410f, 0.1499f, 0.1590f, 0.1683f, 
0.1771f, 0.1851f, 0.1915f, 0.1957f, 0.1971f
};
static const float hlorentz62[57] = {
0.0297f, 0.0302f, 0.0308f, 0.0313f, 0.0319f, 0.0325f, 0.0332f, 0.0338f, 
0.0345f, 0.0352f, 0.0359f, 0.0367f, 0.0375f, 0.0384f, 0.0392f, 0.0401f, 
0.0411f, 0.0421f, 0.0432f, 0.0443f, 0.0454f, 0.0466f, 0.0479f, 0.0493f, 
0.0507f, 0.0522f, 0.0538f, 0.0555f, 0.0573f, 0.0592f, 0.0613f, 0.0635f, 
0.0658f, 0.0683f, 0.0710f, 0.0738f, 0.0769f, 0.0803f, 0.0839f, 0.0878f, 
0.0920f, 0.0965f, 0.1015f, 0.1069f, 0.1127f, 0.1190f, 0.1258f, 0.1330f, 
0.1406f, 0.1486f, 0.1568f, 0.1648f, 0.1724f, 0.1791f, 0.1844f, 0.1878f, 
0.1890f
};
static const float hlorentz63[62] = {
0.0284f, 0.0289f, 0.0294f, 0.0299f, 0.0304f, 0.0309f, 0.0315f, 0.0320f, 
0.0326f, 0.0332f, 0.0338f, 0.0345f, 0.0352f, 0.0359f, 0.0366f, 0.0374f, 
0.0382f, 0.0390f, 0.0399f, 0.0408f, 0.0417f, 0.0427f, 0.0437f, 0.0448f, 
0.0459f, 0.0471f, 0.0484f, 0.0497f, 0.0511f, 0.0525f, 0.0541f, 0.0557f, 
0.0575f, 0.0593f, 0.0612f, 0.0633f, 0.0655f, 0.0679f, 0.0704f, 0.0731f, 
0.0760f, 0.0791f, 0.0824f, 0.0859f, 0.0898f, 0.0939f, 0.0984f, 0.1032f, 
0.1083f, 0.1139f, 0.1198f, 0.1261f, 0.1328f, 0.1398f, 0.1469f, 0.1541f, 
0.1610f, 0.1675f, 0.1731f, 0.1774f, 0.1802f, 0.1811f
};
static const float hlorentz64[65] = {
0.0283f, 0.0287f, 0.0291f, 0.0296f, 0.0301f, 0.0306f, 0.0311f, 0.0316f, 
0.0322f, 0.0327f, 0.0333f, 0.0339f, 0.0345f, 0.0352f, 0.0359f, 0.0366f, 
0.0373f, 0.0381f, 0.0388f, 0.0397f, 0.0405f, 0.0414f, 0.0423f, 0.0433f, 
0.0443f, 0.0454f, 0.0465f, 0.0476f, 0.0489f, 0.0501f, 0.0515f, 0.0529f, 
0.0544f, 0.0560f, 0.0576f, 0.0594f, 0.0613f, 0.0632f, 0.0653f, 0.0676f, 
0.0699f, 0.0724f, 0.0751f, 0.0780f, 0.0811f, 0.0843f, 0.0879f, 0.0916f, 
0.0956f, 0.0999f, 0.1046f, 0.1095f, 0.1147f, 0.1202f, 0.1261f, 0.1321f, 
0.1384f, 0.1447f, 0.1510f, 0.1569f, 0.1624f, 0.1670f, 0.1706f, 0.1728f, 
0.1736f
};
static const float *hptr_tab_lorentz[64] = {
hlorentz1, hlorentz2, hlorentz3, hlorentz4, 
hlorentz5, hlorentz6, hlorentz7, hlorentz8, 
hlorentz9, hlorentz10, hlorentz11, hlorentz12, 
hlorentz13, hlorentz14, hlorentz15, hlorentz16, 
hlorentz17, hlorentz18, hlorentz19, hlorentz20, 
hlorentz21, hlorentz22, hlorentz23, hlorentz24, 
hlorentz25, hlorentz26, hlorentz27, hlorentz28, 
hlorentz29, hlorentz30, hlorentz31, hlorentz32, 
hlorentz33, hlorentz34, hlorentz35, hlorentz36, 
hlorentz37, hlorentz38, hlorentz39, hlorentz40, 
hlorentz41, hlorentz42, hlorentz43, hlorentz44, 
hlorentz45, hlorentz46, hlorentz47, hlorentz48, 
hlorentz49, hlorentz50, hlorentz51, hlorentz52, 
hlorentz53, hlorentz54, hlorentz55, hlorentz56, 
hlorentz57, hlorentz58, hlorentz59, hlorentz60, 
hlorentz61, hlorentz62, hlorentz63, hlorentz64
};
