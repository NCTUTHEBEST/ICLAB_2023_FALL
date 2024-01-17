//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Fall Course
//   Lab09      : BEV
//   Author     : Tzu-Yun Huang
//	 Editor		: Jui-Huang Tsai
//                
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : pseudo_DRAM.sv
//   Module Name : pseudo_DRAM
//   Release version : v2.0 (Release Date: Nov-2023)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`include "Usertype_BEV.sv"

module pseudo_DRAM(input clk, INF.DRAM inf);

`protected
/f0.GT7PVG/QgROX9:?P7)g)37b+P]?I&7LX30++/DZWV?WM2dI0-)EA[LVWA5VV
SS?,fQRGI>Z.HV0FCA2;aOI9I=RU88_1?$
`endprotected

//================================================================
// parameters & integer
//================================================================

parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";

parameter DRAM_R_latency = 50;
parameter DRAM_W_latency = 99;
parameter DRAM_B_latency = 1;

`protected
I_U0DD1?=8FIKH0L:LK,K6:+VYE]NJ::Zb_g;Q,TX>cE.YY\9FP+4)YJ/)=+/-J=
TKX[.7IaZI78.]7R20_8WNe2:<C_b+_O5aU-9>HU_:),5]@(+VQ+K&4I;b(2ZaNc
/^_55e3,7M:AS=O0_Y0Dg?(NdFca,ZADRT+G3_&E(M;7L,UWO8F+FLPV4/HYW300
76<>S26^Ef&.>>df9.1NdPY#:>E-P5MdEP6Oa\.S7MY_&PJO51Ce\\N8bFa+2VA3
?:#N#SDfW7S:?a.B^+.7MXQ6;[)905:/9.J,_f8:Bd4.]Yb0I-^UMQBf>.?TAgQ8
@[WJ[TfF9FF)?BN@3=T.VDV_#DFD0E>Nc_ef/\[Xd_+0UWGCg+#1,BbP&gHLK^HF
?.5,)G#Y#Ib53]9.//,Qf>=+#YcDZUD?X22Of4Wa_,fRXfE-\\E:[?&J)LX@ODE7
@YL)&/R56SH?2b_H+X7.^.=f?/DNIb8@)(2LXA@&Z]69-ZO[4?C)BJLE0\.\M@]F
_4]VMPb.edT5=ZU6)N&Qf4\//.cF>GK#E31+Og-B=S,_99M@<41bU&MS]^.ee+Yg
a.Q54WUR4?QP;UUQ6H7R.:YKM92RbGcC[/N0\GS3]V3FHfV[W#/Y:@^1c/g1^S,-
<\;MJ6-bIONQP_\B-S1RE]@EL-QG@F)3bB(AKCBUV9C,8aLRZHEJ-I7YE>;I\:JF
KCTY+SBGPdQS.AdbfO/Q-F@C;fDK]OZ61K))MRJ895=9N;<[f48_=+-]=bMa[?[2
&O>\dJHCQ[&:EDCd^]\e7BGdeT\FD99SFG,g1-[?;@>JVHM)Y=780UeQ[eC/T)BT
aEDY3\GR45MfS9Yc45f/LO-aOW+H,71O>=W7/.2N_\ZU/P\AF25^7TR4ZB,K7RZZ
P8.>a\S4A5P9ITJ(2Cf/)N#8T/=CN<PT?8VfEA1CLYD.Q&-Z3<BMZY@+-9YEdR,<
<PLbBd(]T-KOO;NeU.NB@gOWR8F#9FLE(4N@e]0(<5Y_=JTP#W>BK^d+Y]/LCdRS
eV4ME()8NASCQZKa.PfXeBf&--ILCef#)SFQIBY^[KYC;:T8DKNO???G3b&MSR^0
8OKY5gaO)fe8)U8@a#D#XLd6KR2M;8W;J0a2AQ8(,H0#K,#;0D#&G^8,<aH0E@Sg
R:\dK5)&1J.#Y6_XQ?1[;A,19??;c1fIXLef._DDC9L]P1fFZX8;ERBSbG]+.:0f
ZF)7MXFD=1-eR\LGA<;cLKYU5:D/52:YG?/K3/da@Y_bO?:-R/e/>8_6,91_^\S=
eTFG>5]UQ5Y4@=Ce[^[G]N&()0U[K<J\;VaQZD-KfUEWIc6M^f[O/SP]+UPOZ-I6
+)_a::aE\IJM#]0HGc#<IRZ+7+[g7?acVZ-4Q167W-X-7\Ac&+e:MWa]e@1J&S[R
+6@._@F;+FYG<GgD\R:PRUS86>H<K3RG.8WN1.BcKa<?_5F.4TEW@G;@(NRTMZW/
I#M#G>]2H4^D?e4?W,K:Q8-/OcEN-@>S-5IP[D-aKZ_<B5>dE:O48ME40S+-+NEH
V?3;GfNM?a+<&aMcW.=O7C:)VWNG)(;3Id_?SE#<RSJ?Q=^Ke)6NYQ\^G1P-e:F\
4MbGB/153KWYDON@\JP/>F4P@&@\Z)=4]2(UM;SUQJS4@6.8#7UPc>12TWK.L<WV
Z.O4G0<LVA[KXE>>=)EB7IDC3XO@ZTg(;?FR?c:]G?3[C8P/+@9MRI4JYLeO>#-?
)95a20f3P(0GJ459UDDgT5:=0&UAG&6.F=YC:PaH39T-JabTbg/=9DPW,?eQ&BHP
,3=R?c9ffDH:#^<E,+HUa)Ma1GD4Y0-2^.-V6?<^/NN<QT.+A5,gN6C@DE];W3L-
g4Kg]^3;C2T5)LgcD>0)CcEC@TO4XHc9VM>-N&0<&Ma&[\=:=KfG+4,,0W??U2TT
)KRW?D==]>J85@0<K5d-34RZR4O<N[d(5X2FA&@g>:>OFG]Nag_-8G^bE;e=-T/G
/H^PGFg#(:[U))EHd8_\-;90#FcSAJ<Z+;?^3E#BBE1&<=YE#O2D;XSc6S1V])\I
00.a>:K7Db&D8,?]>dSW6c<a_2WU,W-NIc_bY1#TW8dYZY?-b3[[>)b\Ug(5a81S
X6NZ3C0;]TMTQ_\H@C@\B2cePO&?KKPc]g@NO(.<(D/FF..1P-L)f.HI2WGF8HcN
M?4E)29_-6?2:Wa_W]+RQ^69I/=::PMdLR,]2P;TYO?#6@^R9&]He5#HJGM?..JD
-QNRJ6?WY^DcVT8XO_da]c?5@Ra<H1Z<=R1=NO8E(QJe&L;^=P^>GIXM4\>UC.aD
2eUT2cWe2D-gGL-_P(#>YeK-TPa?+ZZ(GJ/OWd=T+>K0-DD0L&=W)g@RKbX09UX:
<PJ]CPRYR[QK-f+L9?=#Xb7eb7ERI68gJ]>UNEQG?8<,>#EO01PH@g@Q>V#5]Vd<
9SG(+[)\g_b8>;@D(T-bg]WLN\f+_aFQA2==F82+cbd+XYO@:,W;3I1;Pb?3M3aO
)59JAS.7B23d:DX;gd-gD@_A/A(90?[<eO(=HeT(^^,aQMT8&W??VMGSHDC.fS[Y
O;&gf/)VgNO]GCb?LK1BH\-]8W4=Y<aMabW[H>BYAUD3)Dg7QbJSBR]DE(^-;3\3
TJfZ[W)5.=V0DQ<KJC3<[Y1?cRIa)\:TM:g#=8_ESQ4@S-6Cb10S\^JZDU&&Kgb?
g4@5.PW^cc8.gI_\@TWYBfG#_e,09fT;__[MGX<V/cb/ece/7,<KST2(-9-b^U?D
dbVJ)\SJ[Z.dXA66B<6\A5&fZ4f.NEQWeN?B1P4gLZLYXRQMFcOL-_<</.<Y_QRC
HW7))I^PBL47GT3<(YKg?c/PH0eI8;0G9[.](=HXFT_gX);X)dbX?M:840dZ;SI=
J2bYC@TYGVFW]VW1STE-N@^-e;5f^]2&&NJ/,/D&V6\&WI.;)Q0_((^_eKd[+7Z/
VPT>5+B:2>9G/=F.CWS8eOdgGA)YKdUS727A<XH7)]<E^.X=QWZ-T371-CMaL2I0
P7ZM<,EML).PDEM#?,,HQG4;cE9S92X4gbXC9BK<EOKXcQ2F<CZ)E.#CLDcL3/U<
[FZI/eR-d3UQ]ZMSa;:A_,><X=+F8?1USTC?XfSd/c8?]C@M9=fLYP6+d-ZgU/#<
CHZB)@c_)9DE/=SI8.b])(=M0[0WJ4]3,:W>ZOIc35,#+U[6)3I[AI^09Cf/VXJ1
?BI,)\+G901d/^6O?LS40]B8fGED)HR4Z5aPSHb&3YMD>JE_,19f9L\3fbRKUX_2
Z21:Lg^Q8b/JGc.Jg7NAZeRdS/K89>cHfA#3Y@J=:6[3-8<7WE>?9W7\3)OFRH7f
XDBCZORUd\U<M+3/_OJ#6dbc=UTG8)<d,7.&D__UbbH99/e+WbKG67gH.L6C&40D
FOXVf#b+D]?T0G-;93b0XecHLSSa5gZ.?TgLZ#8,(T01dG4X-(YFGVZA)_;6-4N)
#/a0IJH,=.H68TNYYX+:4?GV:;0-2V-Hb_e3\g-[8@SaMW#^43=W8G5P3IMN]B4E
7:);^/__;PC-3V/QV0+QOdA[gLf)U:.BU.JC?aV9X^fSeC=60HX<(J=afH_]+VY2
W:aHI/eOf]W[#1ZR>KKPM\><IdVO7a?P&1;MPMH_HgDaTGAeb6c/,,(X._PacX<W
>V_-b)=(ANR1^1)^YD>J5YY+S-4T_DZ49G66b2LfGHB=1)XSNRX4@Z2BO+?U/IY>
II728#GZ=N++)/b9B>O5;AL>-J81YN<ZT4&K5c^=6E0:[Xe7Be7Ga_8]f5.C@A?I
36[(]AXGU98=K>5RM7@d.&a;feKOIGU\Z;FMUaE(ILK_HH0:Z?N@?59TDePALeRW
X09/VAQ\G#MGC@<E>ULU#()&A+Z1c&M?&GGHF,+]Od_-S,)D8Le8X/Q8.:cSe/0S
EJZ.\Z-+H<8YJ]N^\M?-\J8<9KbA]a1([Ab4<OY:P15CFH.Y0H\7IL1<<,Jg#f#8
6ddLY;D#3^K1Y5Q>>\;1AaTT<X5:T9IPe(?UT(:2N32O-f:E#D_/U(\KCF]]eK?1
B(2M\Ua6,e^T4<EdNRa1g_=O>&@/8,eJNL8@#JJRQe..F==0-Z=9)ed+W8P</:LU
.X-OX35K_W4-0dc2-XZ\e5N87^0;d1c^2</?)(4TJGcG-N]WLZ<&X4SbQbe5\11e
1/4a+AHgNT861RNfcN\#L)70OV@]).(W40<XV_OL<c5TH:ZKgfEWH.^)I@LZbPAX
9,(IK#WP(RZ\3,YAb7TeH^^\Kd&aC:<D;CLa9D?D(5+R1^9B7&P1#BR#cC6FXPLJ
,PN&Y<3<C<UB2WL4>.?f97+fUC.^Y:H?R[8ZQ8^):.dGX23;U+B@/H#OC@WX>N.I
<CaI?7I4KWT/?LN3:A\^DY5X3/J0F.]+.@bP0/_:g;(?LIg8CGIG<N9@GW/@.Ldf
&7:F]6MeCGF1M^5V.JX^1JAZ4=\5_M\7::AJ68a&=FTN<?&JWDgJQHF9=L.(_#-)
\Y>\X&(/Y<FgIcHE@4.-C[+#RQEK1V+2C+@;#95KB9R=-+65^>,Tag>YSeYg-3[5
G?7IY598+H^<>EMHO-+&J:T@Y(FX_;XI?Q_ZIM>dTZHeJ82@=7Ua=eVJ>62<DP6d
dH)/+TWGAVH7G-6I4aY0W7T=ZBNGf:FRf-CcLG?;eg26beaE+[@6=<#<MXBWUBYH
aK6_/cGSQBR#R74RdQWJO-=6S014.V,2L6V>K[G8)8_U\9)3GPU?CGFXIZOKfd2=
X<QUQcYcAA]:cU8OQNG[KaHO,^J3J=:cRR\?P4E&P_^SYAV-&=YMV?=NcD2N=_K3
#T_NCE:O=C4M.&e;=9E8X/NI<B5B//81]RIS@f@C1Tb(]P+9B@(UN1Eg#=HbA]MZ
edJ2NRb0Y/f,,04gD-^[?6TU@#=HE3AX;[F?R)K_<;8+I4g)67f7Le>N,TM7&14-
a<fXUD(>ZQa<W/.9UMOaG6:>G<e:d0^9;-3-#2aB=B9;#=>7>\DXLc2Tc[U0(UU3
CL9IK;DWf;YTDc+-N_25g/:>3$
`endprotected
endmodule
