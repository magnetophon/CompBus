declare name 		"CompBus";
declare version 	"1.1";
declare author 		"Bart Brouns";
declare license 	"GNU 3.0";
declare copyright 	"(c) Bart Brouns 2014";


import("CompBus.lib");

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// What is this?
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This is a group of sidechain-compressors all mixed together. The sidechain is connected to the output.
// see process=CompBusMono; for a visual explanation.

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  User preferences
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// up to 85 stereo compressors works, but 86 gives "Invalid Faust Code"
NrCompressors = 4; //1 for a single compressor doesn't work, use process=FBcomp; instead. doesn't have in and out metering though...

process =  CompBusMono ;

