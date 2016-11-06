/* 
fadampgauss.c
Gaussian fading tables for QRA64 modes

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
static const int hlen_tab_gauss[64] = {
  2,   2,   2,   2,   2,   2,   2,   2, 
  2,   2,   2,   2,   2,   2,   2,   2, 
  3,   3,   3,   3,   3,   3,   3,   3, 
  4,   4,   4,   4,   5,   5,   5,   6, 
  6,   6,   7,   7,   8,   8,   9,  10, 
 10,  11,  12,  13,  14,  15,  17,  18, 
 19,  21,  23,  25,  27,  29,  32,  34, 
 37,  41,  44,  48,  52,  57,  62,  65
};
static const float hgauss1[2] = {
0.1722f, 0.9540f
};
static const float hgauss2[2] = {
0.1870f, 0.9463f
};
static const float hgauss3[2] = {
0.2028f, 0.9374f
};
static const float hgauss4[2] = {
0.2198f, 0.9273f
};
static const float hgauss5[2] = {
0.2378f, 0.9158f
};
static const float hgauss6[2] = {
0.2569f, 0.9030f
};
static const float hgauss7[2] = {
0.2769f, 0.8887f
};
static const float hgauss8[2] = {
0.2977f, 0.8730f
};
static const float hgauss9[2] = {
0.3190f, 0.8559f
};
static const float hgauss10[2] = {
0.3405f, 0.8374f
};
static const float hgauss11[2] = {
0.3619f, 0.8177f
};
static const float hgauss12[2] = {
0.3828f, 0.7970f
};
static const float hgauss13[2] = {
0.4026f, 0.7755f
};
static const float hgauss14[2] = {
0.4208f, 0.7533f
};
static const float hgauss15[2] = {
0.4371f, 0.7307f
};
static const float hgauss16[2] = {
0.4510f, 0.7078f
};
static const float hgauss17[3] = {
0.1729f, 0.4621f, 0.6849f
};
static const float hgauss18[3] = {
0.1920f, 0.4704f, 0.6620f
};
static const float hgauss19[3] = {
0.2131f, 0.4757f, 0.6393f
};
static const float hgauss20[3] = {
0.2350f, 0.4782f, 0.6170f
};
static const float hgauss21[3] = {
0.2565f, 0.4779f, 0.5949f
};
static const float hgauss22[3] = {
0.2767f, 0.4752f, 0.5733f
};
static const float hgauss23[3] = {
0.2948f, 0.4703f, 0.5522f
};
static const float hgauss24[3] = {
0.3102f, 0.4635f, 0.5316f
};
static const float hgauss25[4] = {
0.1874f, 0.3226f, 0.4551f, 0.5115f
};
static const float hgauss26[4] = {
0.2071f, 0.3319f, 0.4454f, 0.4919f
};
static const float hgauss27[4] = {
0.2253f, 0.3383f, 0.4347f, 0.4730f
};
static const float hgauss28[4] = {
0.2413f, 0.3419f, 0.4232f, 0.4546f
};
static const float hgauss29[5] = {
0.1701f, 0.2546f, 0.3429f, 0.4110f, 0.4368f
};
static const float hgauss30[5] = {
0.1874f, 0.2652f, 0.3417f, 0.3985f, 0.4196f
};
static const float hgauss31[5] = {
0.2028f, 0.2729f, 0.3386f, 0.3857f, 0.4029f
};
static const float hgauss32[6] = {
0.1569f, 0.2158f, 0.2780f, 0.3338f, 0.3728f, 0.3868f
};
static const float hgauss33[6] = {
0.1723f, 0.2263f, 0.2807f, 0.3278f, 0.3599f, 0.3713f
};
static const float hgauss34[6] = {
0.1857f, 0.2343f, 0.2812f, 0.3207f, 0.3471f, 0.3564f
};
static const float hgauss35[7] = {
0.1550f, 0.1968f, 0.2398f, 0.2799f, 0.3128f, 0.3344f, 0.3420f
};
static const float hgauss36[7] = {
0.1677f, 0.2055f, 0.2430f, 0.2770f, 0.3043f, 0.3220f, 0.3281f
};
static const float hgauss37[8] = {
0.1456f, 0.1783f, 0.2118f, 0.2442f, 0.2728f, 0.2953f, 0.3098f, 0.3147f
};
static const float hgauss38[8] = {
0.1572f, 0.1866f, 0.2160f, 0.2436f, 0.2675f, 0.2861f, 0.2979f, 0.3019f
};
static const float hgauss39[9] = {
0.1410f, 0.1667f, 0.1928f, 0.2182f, 0.2416f, 0.2615f, 0.2767f, 0.2863f, 
0.2895f
};
static const float hgauss40[10] = {
0.1288f, 0.1511f, 0.1741f, 0.1970f, 0.2187f, 0.2383f, 0.2547f, 0.2672f, 
0.2750f, 0.2776f
};
static const float hgauss41[10] = {
0.1391f, 0.1592f, 0.1795f, 0.1992f, 0.2176f, 0.2340f, 0.2476f, 0.2578f, 
0.2641f, 0.2662f
};
static const float hgauss42[11] = {
0.1298f, 0.1475f, 0.1654f, 0.1830f, 0.1999f, 0.2153f, 0.2289f, 0.2401f, 
0.2484f, 0.2535f, 0.2552f
};
static const float hgauss43[12] = {
0.1227f, 0.1382f, 0.1540f, 0.1696f, 0.1848f, 0.1991f, 0.2120f, 0.2232f, 
0.2324f, 0.2391f, 0.2433f, 0.2447f
};
static const float hgauss44[13] = {
0.1173f, 0.1309f, 0.1448f, 0.1587f, 0.1722f, 0.1851f, 0.1971f, 0.2078f, 
0.2171f, 0.2246f, 0.2301f, 0.2334f, 0.2346f
};
static const float hgauss45[14] = {
0.1132f, 0.1253f, 0.1375f, 0.1497f, 0.1617f, 0.1732f, 0.1841f, 0.1941f, 
0.2030f, 0.2106f, 0.2167f, 0.2212f, 0.2239f, 0.2248f
};
static const float hgauss46[15] = {
0.1102f, 0.1208f, 0.1315f, 0.1423f, 0.1529f, 0.1632f, 0.1730f, 0.1821f, 
0.1904f, 0.1978f, 0.2040f, 0.2089f, 0.2126f, 0.2148f, 0.2155f
};
static const float hgauss47[17] = {
0.0987f, 0.1079f, 0.1173f, 0.1267f, 0.1362f, 0.1455f, 0.1546f, 0.1634f, 
0.1716f, 0.1792f, 0.1861f, 0.1921f, 0.1972f, 0.2012f, 0.2042f, 0.2059f, 
0.2065f
};
static const float hgauss48[18] = {
0.0980f, 0.1062f, 0.1145f, 0.1228f, 0.1311f, 0.1393f, 0.1474f, 0.1551f, 
0.1624f, 0.1693f, 0.1756f, 0.1813f, 0.1862f, 0.1904f, 0.1936f, 0.1960f, 
0.1975f, 0.1979f
};
static const float hgauss49[19] = {
0.0976f, 0.1049f, 0.1122f, 0.1195f, 0.1268f, 0.1341f, 0.1411f, 0.1479f, 
0.1544f, 0.1606f, 0.1663f, 0.1715f, 0.1762f, 0.1802f, 0.1836f, 0.1862f, 
0.1881f, 0.1893f, 0.1897f
};
static const float hgauss50[21] = {
0.0911f, 0.0974f, 0.1038f, 0.1103f, 0.1167f, 0.1232f, 0.1295f, 0.1357f, 
0.1417f, 0.1474f, 0.1529f, 0.1580f, 0.1627f, 0.1670f, 0.1708f, 0.1741f, 
0.1768f, 0.1790f, 0.1805f, 0.1815f, 0.1818f
};
static const float hgauss51[23] = {
0.0861f, 0.0916f, 0.0973f, 0.1029f, 0.1086f, 0.1143f, 0.1199f, 0.1255f, 
0.1309f, 0.1361f, 0.1412f, 0.1460f, 0.1505f, 0.1548f, 0.1587f, 0.1622f, 
0.1653f, 0.1679f, 0.1702f, 0.1719f, 0.1732f, 0.1739f, 0.1742f
};
static const float hgauss52[25] = {
0.0823f, 0.0872f, 0.0922f, 0.0971f, 0.1021f, 0.1071f, 0.1121f, 0.1170f, 
0.1219f, 0.1266f, 0.1312f, 0.1356f, 0.1398f, 0.1438f, 0.1476f, 0.1511f, 
0.1543f, 0.1572f, 0.1597f, 0.1619f, 0.1637f, 0.1651f, 0.1661f, 0.1667f, 
0.1669f
};
static const float hgauss53[27] = {
0.0795f, 0.0838f, 0.0882f, 0.0925f, 0.0969f, 0.1013f, 0.1057f, 0.1101f, 
0.1144f, 0.1186f, 0.1227f, 0.1267f, 0.1306f, 0.1343f, 0.1378f, 0.1411f, 
0.1442f, 0.1471f, 0.1497f, 0.1520f, 0.1541f, 0.1558f, 0.1573f, 0.1585f, 
0.1593f, 0.1598f, 0.1599f
};
static const float hgauss54[29] = {
0.0774f, 0.0812f, 0.0850f, 0.0889f, 0.0928f, 0.0966f, 0.1005f, 0.1043f, 
0.1081f, 0.1119f, 0.1155f, 0.1191f, 0.1226f, 0.1259f, 0.1292f, 0.1322f, 
0.1351f, 0.1379f, 0.1404f, 0.1428f, 0.1449f, 0.1468f, 0.1485f, 0.1499f, 
0.1511f, 0.1520f, 0.1527f, 0.1531f, 0.1532f
};
static const float hgauss55[32] = {
0.0726f, 0.0759f, 0.0792f, 0.0826f, 0.0860f, 0.0894f, 0.0928f, 0.0962f, 
0.0996f, 0.1029f, 0.1062f, 0.1094f, 0.1126f, 0.1157f, 0.1187f, 0.1217f, 
0.1245f, 0.1271f, 0.1297f, 0.1321f, 0.1343f, 0.1364f, 0.1383f, 0.1401f, 
0.1416f, 0.1430f, 0.1442f, 0.1451f, 0.1459f, 0.1464f, 0.1467f, 0.1468f
};
static const float hgauss56[34] = {
0.0718f, 0.0747f, 0.0777f, 0.0807f, 0.0836f, 0.0866f, 0.0896f, 0.0926f, 
0.0956f, 0.0985f, 0.1014f, 0.1043f, 0.1071f, 0.1098f, 0.1125f, 0.1151f, 
0.1176f, 0.1201f, 0.1224f, 0.1246f, 0.1267f, 0.1287f, 0.1305f, 0.1322f, 
0.1338f, 0.1352f, 0.1365f, 0.1376f, 0.1385f, 0.1393f, 0.1399f, 0.1403f, 
0.1406f, 0.1407f
};
static const float hgauss57[37] = {
0.0687f, 0.0712f, 0.0738f, 0.0765f, 0.0791f, 0.0817f, 0.0843f, 0.0870f, 
0.0896f, 0.0922f, 0.0948f, 0.0973f, 0.0998f, 0.1023f, 0.1047f, 0.1071f, 
0.1094f, 0.1117f, 0.1138f, 0.1159f, 0.1179f, 0.1199f, 0.1217f, 0.1234f, 
0.1250f, 0.1265f, 0.1279f, 0.1292f, 0.1304f, 0.1314f, 0.1323f, 0.1330f, 
0.1337f, 0.1341f, 0.1345f, 0.1347f, 0.1348f
};
static const float hgauss58[41] = {
0.0640f, 0.0663f, 0.0686f, 0.0709f, 0.0732f, 0.0755f, 0.0778f, 0.0801f, 
0.0824f, 0.0847f, 0.0870f, 0.0893f, 0.0915f, 0.0938f, 0.0960f, 0.0982f, 
0.1003f, 0.1024f, 0.1044f, 0.1064f, 0.1083f, 0.1102f, 0.1120f, 0.1137f, 
0.1154f, 0.1170f, 0.1185f, 0.1199f, 0.1212f, 0.1224f, 0.1236f, 0.1246f, 
0.1255f, 0.1264f, 0.1271f, 0.1277f, 0.1282f, 0.1286f, 0.1289f, 0.1291f, 
0.1291f
};
static const float hgauss59[44] = {
0.0625f, 0.0645f, 0.0665f, 0.0685f, 0.0705f, 0.0726f, 0.0746f, 0.0767f, 
0.0787f, 0.0807f, 0.0827f, 0.0847f, 0.0867f, 0.0887f, 0.0907f, 0.0926f, 
0.0945f, 0.0964f, 0.0982f, 0.1000f, 0.1017f, 0.1034f, 0.1051f, 0.1067f, 
0.1083f, 0.1097f, 0.1112f, 0.1125f, 0.1138f, 0.1151f, 0.1162f, 0.1173f, 
0.1183f, 0.1192f, 0.1201f, 0.1208f, 0.1215f, 0.1221f, 0.1226f, 0.1230f, 
0.1233f, 0.1235f, 0.1237f, 0.1237f
};
static const float hgauss60[48] = {
0.0596f, 0.0614f, 0.0631f, 0.0649f, 0.0667f, 0.0685f, 0.0703f, 0.0721f, 
0.0738f, 0.0756f, 0.0774f, 0.0792f, 0.0810f, 0.0827f, 0.0845f, 0.0862f, 
0.0879f, 0.0896f, 0.0912f, 0.0929f, 0.0945f, 0.0960f, 0.0976f, 0.0991f, 
0.1005f, 0.1019f, 0.1033f, 0.1046f, 0.1059f, 0.1071f, 0.1083f, 0.1094f, 
0.1105f, 0.1115f, 0.1124f, 0.1133f, 0.1141f, 0.1149f, 0.1156f, 0.1162f, 
0.1167f, 0.1172f, 0.1176f, 0.1179f, 0.1182f, 0.1184f, 0.1185f, 0.1185f
};
static const float hgauss61[52] = {
0.0575f, 0.0590f, 0.0606f, 0.0621f, 0.0637f, 0.0652f, 0.0668f, 0.0684f, 
0.0700f, 0.0715f, 0.0731f, 0.0747f, 0.0762f, 0.0778f, 0.0793f, 0.0809f, 
0.0824f, 0.0839f, 0.0854f, 0.0868f, 0.0883f, 0.0897f, 0.0911f, 0.0925f, 
0.0938f, 0.0951f, 0.0964f, 0.0976f, 0.0988f, 0.1000f, 0.1011f, 0.1022f, 
0.1033f, 0.1043f, 0.1053f, 0.1062f, 0.1070f, 0.1079f, 0.1086f, 0.1093f, 
0.1100f, 0.1106f, 0.1112f, 0.1116f, 0.1121f, 0.1125f, 0.1128f, 0.1131f, 
0.1133f, 0.1134f, 0.1135f, 0.1135f
};
static const float hgauss62[57] = {
0.0545f, 0.0558f, 0.0572f, 0.0586f, 0.0599f, 0.0613f, 0.0627f, 0.0641f, 
0.0654f, 0.0668f, 0.0682f, 0.0696f, 0.0710f, 0.0723f, 0.0737f, 0.0751f, 
0.0764f, 0.0778f, 0.0791f, 0.0804f, 0.0817f, 0.0830f, 0.0843f, 0.0855f, 
0.0868f, 0.0880f, 0.0892f, 0.0903f, 0.0915f, 0.0926f, 0.0937f, 0.0948f, 
0.0958f, 0.0968f, 0.0977f, 0.0987f, 0.0996f, 0.1004f, 0.1013f, 0.1020f, 
0.1028f, 0.1035f, 0.1042f, 0.1048f, 0.1054f, 0.1059f, 0.1064f, 0.1068f, 
0.1072f, 0.1076f, 0.1079f, 0.1082f, 0.1084f, 0.1085f, 0.1087f, 0.1087f, 
0.1088f
};
static const float hgauss63[62] = {
0.0522f, 0.0534f, 0.0546f, 0.0558f, 0.0570f, 0.0582f, 0.0594f, 0.0606f, 
0.0619f, 0.0631f, 0.0643f, 0.0655f, 0.0667f, 0.0679f, 0.0691f, 0.0703f, 
0.0715f, 0.0727f, 0.0739f, 0.0751f, 0.0763f, 0.0774f, 0.0786f, 0.0797f, 
0.0808f, 0.0819f, 0.0830f, 0.0841f, 0.0851f, 0.0861f, 0.0872f, 0.0882f, 
0.0891f, 0.0901f, 0.0910f, 0.0919f, 0.0928f, 0.0936f, 0.0944f, 0.0952f, 
0.0960f, 0.0967f, 0.0974f, 0.0981f, 0.0987f, 0.0994f, 0.0999f, 0.1005f, 
0.1010f, 0.1014f, 0.1019f, 0.1023f, 0.1026f, 0.1030f, 0.1033f, 0.1035f, 
0.1037f, 0.1039f, 0.1040f, 0.1041f, 0.1042f, 0.1042f
};
static const float hgauss64[65] = {
0.0526f, 0.0537f, 0.0547f, 0.0558f, 0.0569f, 0.0579f, 0.0590f, 0.0601f, 
0.0611f, 0.0622f, 0.0633f, 0.0643f, 0.0654f, 0.0665f, 0.0675f, 0.0686f, 
0.0696f, 0.0707f, 0.0717f, 0.0727f, 0.0737f, 0.0748f, 0.0758f, 0.0767f, 
0.0777f, 0.0787f, 0.0796f, 0.0806f, 0.0815f, 0.0824f, 0.0833f, 0.0842f, 
0.0850f, 0.0859f, 0.0867f, 0.0875f, 0.0883f, 0.0891f, 0.0898f, 0.0905f, 
0.0912f, 0.0919f, 0.0925f, 0.0932f, 0.0938f, 0.0943f, 0.0949f, 0.0954f, 
0.0959f, 0.0964f, 0.0968f, 0.0972f, 0.0976f, 0.0979f, 0.0983f, 0.0986f, 
0.0988f, 0.0991f, 0.0993f, 0.0994f, 0.0996f, 0.0997f, 0.0998f, 0.0998f, 
0.0998f
};
static const float *hptr_tab_gauss[64] = {
hgauss1, hgauss2, hgauss3, hgauss4, 
hgauss5, hgauss6, hgauss7, hgauss8, 
hgauss9, hgauss10, hgauss11, hgauss12, 
hgauss13, hgauss14, hgauss15, hgauss16, 
hgauss17, hgauss18, hgauss19, hgauss20, 
hgauss21, hgauss22, hgauss23, hgauss24, 
hgauss25, hgauss26, hgauss27, hgauss28, 
hgauss29, hgauss30, hgauss31, hgauss32, 
hgauss33, hgauss34, hgauss35, hgauss36, 
hgauss37, hgauss38, hgauss39, hgauss40, 
hgauss41, hgauss42, hgauss43, hgauss44, 
hgauss45, hgauss46, hgauss47, hgauss48, 
hgauss49, hgauss50, hgauss51, hgauss52, 
hgauss53, hgauss54, hgauss55, hgauss56, 
hgauss57, hgauss58, hgauss59, hgauss60, 
hgauss61, hgauss62, hgauss63, hgauss64
};
