declare name 		"CompBus";
declare version 	"1.0";
declare author 		"Bart Brouns";
declare license 	"GNU 3.0";
declare copyright 	"(c) Bart Brouns 2014";


import("effect.lib");

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// What is this?
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This is a group of sidechain-compressors all mixed together. The sidechain is connected to the output.
// see process=CompBusMono; for a visual explanation.

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  User prefferences
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// up to 85 stereo compressors works, but 86 gives "Invalid Faust Code"
NrCompressors = 8; //1 for a single compressor doesn't work, use process=FBcomp; instead. doesn't have in and out metering though...
//2 to 16, can be extended by writing more f(n) functions in SCcomp
ChanPerComp= 2; //1 for mono doesn't work, use process=CompBusMono; instead, Doesn't have in and out metering though...

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  user interface
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

meter_group(x)  = (vgroup("[1]", x));
knob_group(x)  = (vgroup("[2]", x));


ratio = knob_group(vslider("[1]ratio[unit::1]", 20, 1, 20 , 0.1));
thresh =  knob_group(vslider("[2]thres[unit: dB]", 0, -70, 0 , 0.1));
att =  knob_group(vslider("[3]att[unit: s]", 0, 0, 0.1 , 0.001));
rel =  knob_group(vslider("[4]rel[unit: s]", 0.1, 0.01, 1 , 0.001));

envelop	= abs : max ~ -(1.0/SR) : max(db2linear(-70)) : linear2db;

meter = (_<:(_, (envelop :(vbargraph("[3][unit:dB][tooltip: input level in dB]", -70, +6)))):attach);
multimeter =  meter_group(hgroup("[1]",par(i,ChanPerComp,_<:(_, (envelop :(vbargraph("[unit:dB][tooltip: input level in dB]", -70, +6)))):attach)));

InMeter=bus(ChanPerComp*NrCompressors)<:(bus(ChanPerComp*NrCompressors)<:bus(ChanPerComp*NrCompressors*2):(InMetRoutInput,InMet):interleave(ChanPerComp,2):par(i,ChanPerComp,attach)),InMetRoutOutput:>bus(ChanPerComp*NrCompressors)
with {
	InMet= bus(ChanPerComp*(NrCompressors)):> meter_group(vgroup("In:",par(i,ChanPerComp,envelop :(hbargraph("[unit:dB][tooltip: input level in dB]", -70, +6)) )));
	InMetRoutInput=bus(ChanPerComp),par(i,ChanPerComp*(NrCompressors-1),!) ;
	//met=(InMetRoutInput,InMet):interleave(ChanPerComp,2):par(i,ChanPerComp,attach);
	InMetRoutOutput= par(i,ChanPerComp,!),bus(ChanPerComp*(NrCompressors-1)) ;
	//me= (bus(ChanPerComp*NrCompressors)<:bus(ChanPerComp*NrCompressors*2):(InMetRoutInput,InMet):interleave(ChanPerComp,2):par(i,ChanPerComp,attach));
};

OutMeter =  meter_group(vgroup("Out:",par(i,ChanPerComp,_<:(_, (envelop :(hbargraph("[2][unit:dB][tooltip: output level in dB]", -70, +6)))):attach)));

//GR 		=  (linear2db : meter_group(vbargraph("[2] GR [unit:dB] [tooltip: Gain reduction in dB]",  -30,0)));
displayGR 	= _<:_,(linear2db : meter_group(vbargraph("[4] GR [unit:dB] [tooltip: Gain reduction in dB]",  -30,0))) : attach;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  compute the gain
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

gaincomp(x) = compression_gain_mono(ratio,thresh,att,rel,x);
//gaincomp_stereo = min(gaincomp,gaincomp) ;
gaincomp_multi(Nr) = f(Nr) with {

f(1)=gaincomp(_);
f(2)=min( gaincomp(_),gaincomp(_));
f(3)=f(1),f(2):min;
//f(n)=f(n-2),f(n-1):min;
f(4) =par(i,(2),min( gaincomp(_),gaincomp(_))):min;
f(5) =f(1),f(4):min;
f(6) =f(2),f(4):min;
f(7) =f(3),f(4):min;
f(8) =par(i,4,min( gaincomp(_),gaincomp(_)) ):par(i,(2),min):min;
f(9) =f(1),f(8):min;
f(10) =f(2),f(8):min;
f(11) =f(3),f(8):min;
f(12) =f(4),f(8):min;
f(13) =f(5),f(8):min;
f(14) =f(6),f(8):min;
f(15) =f(7),f(8):min;
f(16) =par(i,8,min( gaincomp(_),gaincomp(_)) ):par(i,4,min ):par(i,(2),min):min;
};


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//   compressor building blocks
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// a feedback compressor
//FBcomp =_*_~gaincomp(_);

//a mono sidechain compressor
SidechainCompressor(v) 	= hgroup("Ch %v", hgroup("",(gaincomp(_):displayGR)*meter));
//StereoComp(v) 	= vgroup("Ch %v",_,_<:gaincomp_stereo*_,gaincomp_stereo*_);
//SC(Nr)=par(i,Nr*2,_): (gaincomp_multi(Nr):displayGR<:par(i,Nr,_)),multimeter : interleave(Nr,2): par(i,Nr,*);
SCcomp(Nr) 	= hgroup("",par(i,Nr*2,_): (gaincomp_multi(Nr):displayGR<:par(i,Nr,_)),multimeter : interleave(Nr,2): par(i,Nr,*));
SidechainComp(Nr) 	= hgroup("[1]MasterFB",par(i,Nr*2,_): (gaincomp_multi(Nr):displayGR<:par(i,Nr,_)),multimeter : interleave(Nr,2): par(i,Nr,*)); //identical to SCcomp except for the caption

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  StereoRouting
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// the number of in and outputs
inputNr= (NrCompressors*ChanPerComp); // total nr of inputs
totalNr= (ChanPerComp+inputNr); // total nr of inputs, including the feedback
outputNr= inputNr*2; //nr of outputs of the router, including a SC for each compressor

Zero(Nr)=  par(i,Nr,0); //nake (Nr) outputs  that output nothing

//make it pair up the feedback input with the audio inputs of multirouting, mono version
routing=  (bus(1+NrCompressors))  <: par(j,NrCompressors,(_,selector(j,NrCompressors)));

// select first ChanPerComp inputs from ((NrCompressors*ChanPerComp)+ChanPerComp)
SideChain(ChNr) = bus(totalNr)<:Zero(ChNr*2*ChanPerComp),par(i,ChanPerComp,selector(i,totalNr)),Zero(outputNr-(ChNr*2*ChanPerComp)-ChanPerComp);
//exception, needed cause par(i,0,something) doesn't work
FirstSideChain =bus(totalNr)<:par(i,ChanPerComp,selector(i,totalNr)),Zero(outputNr-ChanPerComp);
//Connect all SideChains
AllSC = bus(totalNr)<:FirstSideChain,par(i,NrCompressors-1,SideChain(i+1)):>bus(outputNr);
// select audio bus(totalNr):
audio(ChNr)=  par(i,ChanPerComp,!) , (bus(inputNr)<:par(i,ChanPerComp,selector(i+ChanPerComp*ChNr,inputNr)));
//connect all the audio
AllAudio = bus(totalNr)<:par(i,NrCompressors,Zero(ChanPerComp),audio(i));


//and the complete routing
MultiRouting= bus(totalNr)<: AllSC, AllAudio:>bus(outputNr);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  the complete CompBus
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
CompBusMono = ((routing:(hgroup("CompBus", par(i, NrCompressors, SidechainCompressor(i+1)):>_ )))~_) ;

FBcomp= (  hgroup("[2]FBcomp",SCcomp(ChanPerComp))   ) ~ bus(ChanPerComp) ;
FFcomp= hgroup("[2]FFcomp",bus(ChanPerComp)<:(  par(i,ChanPerComp*2,_): (gaincomp_multi(ChanPerComp):displayGR<:par(i,ChanPerComp,_)),multimeter : interleave(ChanPerComp,2): par(i,ChanPerComp,*)   ) );

SCFB(Nr)=hgroup("[1]MasterSC",(( (interleave(Nr,2):par(i,Nr,*):gaincomp_multi(Nr):displayGR<:par(i,Nr,_)),multimeter)~(bus(Nr)) : interleave(Nr,2): par(i,Nr,*)));
SCFBplusFF(Ch)= hgroup("Ch %Ch [Ch]",hgroup("",SCFB(ChanPerComp):FFcomp));
SCplusFF(Ch)= hgroup("Ch %Ch [Ch]",hgroup("",SidechainComp(ChanPerComp):FFcomp));

CompBus=InMeter: (  hgroup("", MultiRouting:(par(i,NrCompressors, SCplusFF(i+1)):>bus(ChanPerComp) )) )  ~  OutMeter ;

process =  CompBus;

