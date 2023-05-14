declare name 		"CompBus2x4";
declare version 	"1.1.4";
declare author 		"Bart Brouns";
declare license 	"AGPL-3.0-only";
declare copyright 	"(c) Bart Brouns 2023";

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
NrCompressors = 2; //1 for a single compressor doesn't work, use process=FBcomp; instead. doesn't have in and out metering though...
// has to be a power of 2
ChanPerComp= 4; //1 for mono doesn't work, use process=CompBusMono; instead, Doesn't have in and out metering though...

process =  CompBus;
