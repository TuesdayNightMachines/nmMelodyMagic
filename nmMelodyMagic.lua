-- nmMelodyMagic
-- 0.7.3.1 @NightMachines
-- llllllll.co/t/nmmelodymagic/
--
-- Port of Ken Stone's CV
-- generators and processors,
-- originally for the 4U
-- CGS Serge modular synth:
-- - Infinite Melody
-- - Diatonic Converter
-- - Modulo Magic
-- 
-- Configure 'MIDI Output Settings'
-- in the EDIT menu first!
--
-- E1: Switch Page
-- E2: Choose Parameter
-- E3: Change Parameter
--
-- K1: Hold for Info
-- K2: Manual Clock Pulse
-- K3: Manual Advance Pulse
-- K1 + K2: MIDI Panic
-- K1 + K3: Save Patch
-- 

--[[
_norns.screen_export_png("/home/we/dust/nmMelodyMagic.png")
norns.script.load("code/nmMelodyMagic/nmMelodyMagic.lua")
]]--
--
--


engine.name = "PolyPerc"
local audioOut = 1

local selPage = 1
local pageLabels = {"Infinite Melody >","< Diatonic Converter >", "< Output Processing >", "< Modulo Magic >", "< Output Processing >", "< Modulation >", "< Note On/Off >", "< Visualizer"}
local onOff = {"on", "off"}
local plusMin = {"+", "-"}
local intExt = {"int", "ext"}
local k1held = 0

local devices = {}
local midi_output = nil
local midiOuts = {}
local midiChs = {}
local midiSources = {"imDAC1Midi","imDAC1pMidi","imDAC2Midi","imDAC2pMidi","imDAC3Midi", "imDAC3pMidi", "imMixMidi", "imMixpMidi", "dcOutMidi", "dcOutpMidi", "mmOutMidi", "mmOutpMidi"}
local midiSourcChs = {"imDAC1Ch","imDAC1pCh","imDAC2Ch","imDAC2pCh","imDAC3Ch","imDAC3pCh", "imMixCh", "imMixpCh", "dcOutCh", "dcOutpCh","mmOutCh","mmOutpCh"}
local activeNotes = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1}
local midiPanic = 0
local midiNoteStarts = {"imDAC1Start","imDAC1pStart","imDAC2Start","imDAC2pStart","imDAC3Start","imDAC3pStart","imMixStart","imMixpStart","dcOutStart","dcOutpStart","mmOutStart","mmOutpStart"}
local midiNoteEnds = {"imDAC1End","imDAC1pEnd","imDAC2End","imDAC2pEnd","imDAC3End","imDAC3pEnd","imMixEnd","imMixpEnd","dcOutEnd","dcOutpEnd","mmOutEnd","mmOutpEnd"}
local midiChIds = {"imDAC1Ch","imDAC1pCh","imDAC2Ch","imDAC2pCh","imDAC3Ch","imDAC3pCh","imMixCh","imMixpCh","dcOutCh","dcOutpCh","mmOutCh","mmOutpCh"}

local allBits = {}
local allBitNames = {"DSR In 1", "DSR In 2", "DSR In 3", "DSR In 4", "DSR In 5", "DSR In 6", "DAC1 1", "DAC1 2", "DAC1 3", "DAC1 4", "DAC1 5", "DAC1 6", "DAC2 1", "DAC2 2", "DAC2 3", "DAC2 4", "DAC2 5", "DAC2 6", "DAC3 1", "DAC3 2", "DAC3 3", "DAC3 4", "DAC3 5", "DAC3 6", "Mix 1", "Mix 2", "Mix 3", "Mix 4", "Mix 5", "Mix 6"}

local savedState = 0

local rotateCounter = 0
local xCounter = 0
local xAdd = 0


--INFINITE MELODY VARIABLES

local imSelUI = 1 -- ui elements to select

local imDsrIn = {0,0,0,0,0,0}
local imDsrInString = "000000"
local imDsrBits = {
  {0,0,0,0}, -- LSB
  {0,0,0,0},
  {0,0,0,0},
  {0,0,0,0},
  {0,0,0,0},
  {0,0,0,0} -- MSB
}
local imRndOptions = {"rnd", "1/f"}
local imFModeCounter = {0,0,0,0,0}
local imNoiseVal = 0
local imMixOut = 0
local imDsrOuts = {0,0,0}
local imDsrOutsProc = {0,0,0}
local imDsrStrings = {"0000","0000","0000","0000"}

local imClockTick = 0
local imAdvTick = 0
local imAdvTicks = {0,0,0,0,0,0}


-- DIATONIC CONVERTER VARIABLES

local dcSelUI = 2
local dcOctave = 1
local dcIns = {"DSR In", "DSR1", "DSR2", "DSR3", "Manual"}
local dcUiElements = {"dcIns","dcManVal","dcRoot","dcMajMin","dcScaling","dcBit5", "dcBit6"}
local dcSelOffset = 0
local dcStringNote = ""
local dcStringOctave = ""
local dcNote = 1
local dcNotesMaj = {"C","D","E","F","G","A","B","C"}
local dcNotesMin = {"C","D","Eb","F","G","Ab","Bb","C"}
local dcOut = 0
local dcOutProc = 0
local dcMajMin = {"maj", "min"}
local dcMidiNotes = {"C","Db","D","Eb","E","F","Gb","G","Ab","A","Bb","B"}
local dcMidiOctaves = {"-1","0","1","2","3","4","5","6","7","8","9"}


-- OUTPUT PROC 1 VARIABLES
local out1SelUI = 1


-- MODULO MAGIC VARIABLES
local mmSelUI = 2
local mmSelOffset = 0
local mmUiElements = {"mmIns", "mmManVal", "mmInit","mmOff","mmStepSize","mmAdd","mmSub","mmSteps"}
local mmIns = {"DAC1", "DAC1-p", "DAC2", "DAC2-p", "DAC3", "DAC3-p","Mix","Mix-p","Dia", "Dia-p", "Manual"}
local mmTracker = 0
local mmOut = 0
local mmOutProc = 0
local mmStepCount = 0

-- OUTPUT PROC 2 VARIABLES
local out2SelUI = 1


-- MODULATION PAGE
local modSelUI = 1
local modSources = {"DAC1", "DAC1-p", "DAC2", "DAC2-p", "DAC3", "DAC3-p","Mix","Mix-p","Dia", "Dia-p", "Modulo", "Modulo-p","Manual 1", "Manual 2", "Manual 3", "Crow In 1", "Crow In 2"}
local modTargets = {"Clock", "Advance", "Mode", "Sense", "Root", "Scale", "Scaling", "Initiation", "Offset", "Step Size", "Steps"}
local modTgtIds = {"imClockRate","imAdvanceRate", "imRndMode", "imSense", "dcRoot", "dcMajMin", "dcScaling", "mmInit", "mmOff", "mmStepSize", "mmSteps"}
local modPrevVals = {
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
}

-- MIDI NOTE SETTINGS PAGE
local noteSelUI = 1
local noteOutSel = 1


-- MODERN ART PAGE
local artSelUI = 1
local artOn = 0
local page8 = 0


-- CROW STUFF
local crowOuts = {"off","DAC1", "DAC1-p", "DAC2", "DAC2-p", "DAC3", "DAC3-p","Mix","Mix-p","Dia", "Dia-p", "Modulo", "Modulo-p"}
local crowInRanges = {"0-5V", "0-10V"}
local cvGate ={"CV","Gate"} 
local cvClock ={"CV","Clock"} 
local crowGates = {0,0,0,0}



-- GRID STUFF
local grid = util.file_exists(_path.code.."midigrid") and include "midigrid/lib/mg_128" or grid
local gridDSR = {
  {nil,nil,nil,nil,nil,nil}, -- DSRIn
  {nil,nil,nil,nil,nil,nil}, -- DSR1
  {nil,nil,nil,nil,nil,nil}, -- DSR2
  {nil,nil,nil,nil,nil,nil}, -- DSR3
  {nil,nil,nil,nil,nil,nil}, -- DSRmix
}


function init()
  screen.aa(0)
  screenClear()
  crow.reset()
  grid.connect()
  grid.key = gridKey
  
  
  for id,device in pairs(midi.vports) do
    devices[id] = device.name
  end

  for i=1,128 do
    if i==1 then
      midiOuts[i]= "Note"
    else
      midiOuts[i]= "CC# "..i-1
    end
  end

  for i=1,17 do
    if i==1 then
      midiChs[i]= "off"
    else
      midiChs[i]= i-1
    end
  end
  

  for i=1,30 do
    allBits[i]=0
  end
  
  for i=1,4 do
    crow.output[i].volts = 0
    crow.output[i].slew = 0
  end
  


  
  params:add_separator("nmMelodyMagic")
  params:add{type = "trigger", id = "loadDefault", name = "Load Default Settings", action=function(x) params:read(norns.state.data.."default.pset") params:bang() end}
  params:add{type = "trigger", id = "loadLaststate", name = "Load Last State Settings", action=function(x) params:read(norns.state.data.."laststate.pset") params:bang() end}
  params:add_separator("")
  params:add{type = "option", id = "audioOut", name = "Audio Output", options = onOff, default = 1, action=function(x) audioOut=x end}
  params:add{type = "option", id = "midi_input", name = "Midi Input", options = devices, default = 2, action=set_midi_input}
  params:add{type = "option", id = "midi_output", name = "Midi Output", options = devices, default = 1, action=set_midi_output}

  
  midi_output = midi.connect(params:get("midi_output")) 

  
  params:add_group("MIDI Output Settings",31)
  params:add{type = "option", id = "midiClockOut", name = "MIDI Clock Out", options = onOff, default = 2, action=function(x) if x == 2 then midi_output:stop() else midi_output:start() end end}
  params:add_separator("") 
  params:add{type = "option", id = "imDAC1Midi", name = "DAC 1 Out", options = midiOuts, default = 1, wrap = false, action = function(x) end}
  params:add{type = "option", id = "imDAC1Ch", name = "DAC 1 Channel", options = midiChs, default = 1, wrap = false, action = function(x)  end}
  params:add{type = "option", id = "imDAC1pMidi", name = "DAC 1 Proc. Out", options = midiOuts, default = 1, wrap = false, action = function(x) end}
  params:add{type = "option", id = "imDAC1pCh", name = "DAC 1 Proc. Channel", options = midiChs, default = 2, wrap = false, action = function(x)  end}
  params:add_separator("")
  
  params:add{type = "option", id = "imDAC2Midi", name = "DAC 2 Out", options = midiOuts, default = 2, wrap = false, action = function(x)  end}
  params:add{type = "option", id = "imDAC2Ch", name = "DAC 2 Channel", options = midiChs, default = 1, wrap = false, action = function(x)  end}
  params:add{type = "option", id = "imDAC2pMidi", name = "DAC 2 Proc. Out", options = midiOuts, default = 2, wrap = false, action = function(x)  end}
  params:add{type = "option", id = "imDAC2pCh", name = "DAC 2 Proc. Channel", options = midiChs, default = 1, wrap = false, action = function(x)  end}
  params:add_separator("") 

  params:add{type = "option", id = "imDAC3Midi", name = "DAC 3 Out", options = midiOuts, default = 1, wrap = false, action = function(x)  end}
  params:add{type = "option", id = "imDAC3Ch", name = "DAC 3 Channel", options = midiChs, default = 1, wrap = false, action = function(x)  end}
  params:add{type = "option", id = "imDAC3pMidi", name = "DAC 3 Proc. Out", options = midiOuts, default = 1, wrap = false, action = function(x)  end}
  params:add{type = "option", id = "imDAC3pCh", name = "DAC 3 Proc. Channel", options = midiChs, default = 1, wrap = false, action = function(x)  end}
  params:add_separator("")

  params:add{type = "option", id = "imMixMidi", name = "Mix Out", options = midiOuts, default = 2, wrap = false, action = function(x)  end}
  params:add{type = "option", id = "imMixCh", name = "Mix Channel", options = midiChs, default = 1, wrap = false, action = function(x)  end}
  params:add{type = "option", id = "imMixpMidi", name = "Mix Proc. Out", options = midiOuts, default = 2, wrap = false, action = function(x)  end}
  params:add{type = "option", id = "imMixpCh", name = "Mix Proc. Channel", options = midiChs, default = 1, wrap = false, action = function(x)  end}
  params:add_separator("")

  params:add{type = "option", id = "dcOutMidi", name = "Diatonic Out", options = midiOuts, default = 1, wrap = false, action = function(x)  end}
  params:add{type = "option", id = "dcOutCh", name = "Diatonic Channel", options = midiChs, default = 1, wrap = false, action = function(x)  end}
  params:add{type = "option", id = "dcOutpMidi", name = "Diatonic Proc. Out", options = midiOuts, default = 1, wrap = false, action = function(x)  end}
  params:add{type = "option", id = "dcOutpCh", name = "Diatonic Proc. Channel", options = midiChs, default = 1, wrap = false, action = function(x)  end}
  params:add_separator("")
  
  params:add{type = "option", id = "mmOutMidi", name = "Modulo Out", options = midiOuts, default = 2, wrap = false, action = function(x)  end}
  params:add{type = "option", id = "mmOutCh", name = "Modulo Channel", options = midiChs, default = 1, wrap = false, action = function(x)  end}
  params:add{type = "option", id = "mmOutpMidi", name = "Modulo Proc. Out", options = midiOuts, default = 2, wrap = false, action = function(x)  end}
  params:add{type = "option", id = "mmOutpCh", name = "Modulo Proc. Channel", options = midiChs, default = 1, wrap = false, action = function(x)  end}
  
  
  
  
  params:add_group("Grid Settings",1)
  params:add{type = "option", id = "gridUpdateOutsImm", name = "Update Outs Immediately", options = onOff, default = 2, action = function(x) grid:led(6,8,((-1*(x-1))+1)*14+1) grid:refresh() end }
  
  
  
  
  
  
  
  params:add_group("Crow I/O Settings",30)
  params:add_separator("Outputs (0-10V)") 
  params:add{type = "option", id = "crowOut1", name = "Crow Out 1", options = crowOuts, default = 3}
  params:add{type = "option", id = "crowOut1Type", name = "Crow Out 1 Type", options = cvGate, default = 1}
  params:add_control("crowOut1Slew", "Crow Out 1 Slew", controlspec.new(0.0,5.0,"lin",0.05,0.0,"",1/100,false))
  params:set_action("crowOut1Slew", function(x) crow.output[1].slew = x end)
  params:add_control("crowOut1Off", "Crow Out 1 Offset", controlspec.new(-64,63,"lin",1,0,"",1/127,false))
  params:add_control("crowOut1Scaling", "Crow Out 1 Scaling", controlspec.new(0.0,1.0,"lin",0.05,1.0,"",1/20,false))
  params:add_separator("")
  params:add{type = "option", id = "crowOut2", name = "Crow Out 2", options = crowOuts, default = 3}
  params:add{type = "option", id = "crowOut2Type", name = "Crow Out 2 Type", options = cvGate, default = 2}
  params:add_control("crowOut2Slew", "Crow Out 2 Slew", controlspec.new(0.0,5.0,"lin",0.05,0.0,"",1/100,false))
  params:set_action("crowOut2Slew", function(x) crow.output[2].slew = x end)
  params:add_control("crowOut2Off", "Crow Out 2 Offset", controlspec.new(-64,63,"lin",1,0,"",1/127,false))
  params:add_control("crowOut2Scaling", "Crow Out 2 Scaling", controlspec.new(0.0,1.0,"lin",0.05,1.0,"",1/20,false))
  params:add_separator("")
  params:add{type = "option", id = "crowOut3", name = "Crow Out 3", options = crowOuts, default = 7}
  params:add{type = "option", id = "crowOut3Type", name = "Crow Out 3 Type", options = cvGate, default = 1}
  params:add_control("crowOut3Slew", "Crow Out 3 Slew", controlspec.new(0.0,5.0,"lin",0.05,0.0,"",1/100,false))
  params:set_action("crowOut3Slew", function(x) crow.output[3].slew = x end)
  params:add_control("crowOut3Off", "Crow Out 3 Offset", controlspec.new(-64,63,"lin",1,0,"",1/127,false))
  params:add_control("crowOut3Scaling", "Crow Out 3 Scaling", controlspec.new(0.0,1.0,"lin",0.05,1.0,"",1/20,false))
  params:add_separator("")
  params:add{type = "option", id = "crowOut4", name = "Crow Out 4", options = crowOuts, default = 7}
  params:add{type = "option", id = "crowOut4Type", name = "Crow Out 4 Type", options = cvGate, default = 2}
  params:add_control("crowOut4Slew", "Crow Out 4 Slew", controlspec.new(0.0,5.0,"lin",0.05,0.0,"",1/100,false))
  params:set_action("crowOut4Slew", function(x) crow.output[4].slew = x end)
  params:add_control("crowOut4Off", "Crow Out 4 Offset", controlspec.new(-64,63,"lin",1,0,"",1/127,false))
  params:add_control("crowOut4Scaling", "Crow Out 4 Scaling", controlspec.new(0.0,1.0,"lin",0.05,1.0,"",1/20,false))
  params:add_separator("")
  
  params:add_separator("Inputs")
  params:add{type = "option", id = "crowIn1Type", name = "Crow In 1 Type", options = cvClock, default = 2, action = function(x) if x== 1 then crow.input[1].mode("change",2,0.1,"rising") else crow.input[1].mode("none") end end}
  params:add{type = "option", id = "crowIn1Range", name = "Crow In 1 CV Range", options = crowInRanges, default = 2}
  params:add{type = "option", id = "crowIn2Type", name = "Crow In 2 Type", options = cvClock, default = 1, action = function(x) if x== 1 then crow.input[2].mode("change",2,0.1,"rising") else crow.input[2].mode("none") end end}
  params:add{type = "option", id = "crowIn2Range", name = "Crow In 2 CV Range", options = crowInRanges, default = 2}
  
  
  
  
  
  
  params:add_separator("Module Settings") 
  params:add_group("Infinite Melody",23)
  
  params:add_control("imClockRate", "Clock Rate", controlspec.new(-64,63,"lin",1,0,"",1/128,false))
  params:add_control("imAdvanceRate", "Advance Rate", controlspec.new(-64,63,"lin",1,0,"",1/128,false))
  params:add{type = "option", id = "imRndMode", name = "Mode", options = imRndOptions, default = 1}
  params:add{type = "option", id = "imNoiseGen", name = "Noise Generator", options = intExt, default = 1}
  params:add_control("imIntNoiseRate", "Int. Noise Gen. Rate", controlspec.new(-64,63,"lin",1,8,"",1/128,false))
  params:add{type = "number", id = "imExtNoiseVal", name = "Ext. Noise Gen Value", min = 0, max = 127, default = 65, wrap = false, action = function(x) if params:get("imNoiseGen")==2 then imUpdateNoise() end end}
  params:add{type = "number", id = "imSense", name = "Sense", min = 0, max = 127, default = 64, wrap = false}


  params:add_separator("Mixer Pots") 
  for i=1,6 do
    params:add{type = "number", id = "imMix"..i, name = "Mixer "..i, min = 0, max = 127, default = 0, wrap = false}
  end
  
  params:add_separator("Output Processing")
  params:add_control("imDsrOutsProcAtt1", "DAC 1 Attenuverter", controlspec.new(-1.0,1.0,"lin",0.05,1.0,"",1/40,false))
  params:add{type = "number", id = "imDsrOutsProcOff1", name = "DAC 1 Offset", min = 0, max = 127, default = 25, wrap = false}
  params:add_control("imDsrOutsProcAtt2", "DAC 2 Attenuverter", controlspec.new(-1.0,1.0,"lin",0.05,1.0,"",1/40,false))
  params:add{type = "number", id = "imDsrOutsProcOff2", name = "DAC 2 Offset", min = 0, max = 127, default = 0, wrap = false}
  params:add_control("imDsrOutsProcAtt3", "DAC 3 Attenuverter", controlspec.new(-1.0,1.0,"lin",0.05,1.0,"",1/40,false))
  params:add{type = "number", id = "imDsrOutsProcOff3", name = "DAC 3 Offset", min = 0, max = 127, default = 0, wrap = false}
  params:add_control("imMixOutProcAtt", "Mix Out Attenuverter", controlspec.new(-1.0,1.0,"lin",0.05,1.0,"",1/40,false))
  params:add{type = "number", id = "imMixOutProcOff", name = "Mix Out Offset", min = 0, max = 127, default = 0, wrap = false}
  
  
  
  
  params:add_group("Diatonic Converter",10)
  params:add{type = "option", id = "dcIns", name = "Input", options = dcIns, default = 5, action = function(x) if x == 5 then dcSelOffset = 1 else dcSelOffset = 0 end end}
  params:add{type = "number", id = "dcManVal", name = "Manual Value", min = 0, max = 63, default = 0, wrap = false, action = function(x) if dcSelOffset == 1 then updateDcOut() end end}
  params:add{type = "number", id = "dcRoot", name = "Root", min = 0, max = 127, default = 0, wrap = false, action = function(x) if dcSelOffset == 1 then updateDcOut() end end}
  params:add{type = "option", id = "dcMajMin", name = "Scale", options = dcMajMin, default = 1, action = function(x) if dcSelOffset == 1 then updateDcOut() end end}
  params:add{type = "number", id = "dcScaling", name = "Scaling", min = 0, max = 127, default = 127, wrap = false, action = function(x) if dcSelOffset == 1 then updateDcOut() end end}
  params:add{type = "option", id = "dcBit5", name = "Bit 5", options = onOff, default = 1, action = function(x) if dcSelOffset == 1 then updateDcOut() end end}
  params:add{type = "option", id = "dcBit6", name = "Bit 6", options = onOff, default = 1, action = function(x) if dcSelOffset == 1 then updateDcOut() end end}
  
  params:add_separator("Output Processing")
  params:add_control("dcOutProcAtt", "Diatonic Out Attenuverter", controlspec.new(-1.0,1.0,"lin",0.05,1.0,"",1/40,false))
  params:add{type = "number", id = "dcOutProcOff", name = "Diatonic Out Offset", min = 0, max = 127, default = 0, wrap = false}


  
  
  
  params:add_group("Modulo Magic",11)
  params:add{type = "option", id = "mmIns", name = "Input", options = mmIns, default = 11, action = function(x) if x == 11 then mmSelOffset = 1 else mmSelOffset = 0 end end}
  params:add{type = "number", id = "mmManVal", name = "Manual Value", min = 0, max = 127, default = 30, wrap = false, action = function(x) if mmSelOffset == 1 then updateMmOut() end end}
  params:add{type = "number", id = "mmInit", name = "Initiation", min = 0, max = 127, default = 20, wrap = false, action = function(x) if mmSelOffset == 1 then updateMmOut() end end}
  params:add{type = "number", id = "mmOff", name = "Offset", min = 0, max = 127, default = 20, wrap = false, action = function(x) if mmSelOffset == 1 then updateMmOut() end end}

  params:add_control("mmStepSize", "Step Size", controlspec.new(-64,63,"lin",1,-15,"",1/128,false))
  params:set_action("mmStepSize", function(x) if mmSelOffset == 1 then updateMmOut() end end)
  params:add{type = "number", id = "mmAdd", name = "Add", min = 0, max = 127, default = 0, wrap = false, action = function(x) if mmSelOffset == 1 then updateMmOut() end end}
  params:add{type = "number", id = "mmSub", name = "Subtract", min = 0, max = 127, default = 0, wrap = false, action = function(x) if mmSelOffset == 1 then updateMmOut() end end}
  params:add{type = "number", id = "mmSteps", name = "Steps", min = 0, max = 8, default = 3, wrap = false, action = function(x) if mmSelOffset == 1 then updateMmOut() end end}
  
  params:add_separator("Output Processing")
  params:add_control("mmOutProcAtt", "Modulo Out Attenuverter", controlspec.new(-1.0,1.0,"lin",0.05,1.0,"",1/40,false))
  params:add{type = "number", id = "mmOutProcOff", name = "Modulo Out Offset", min = 0, max = 127, default = 0, wrap = false}
 
  
  params:add_group("Modulation",19)
  params:add{type = "option", id = "mod1Src", name = "Modulation 1 Source", options = modSources, default = 1}
  params:add_control("mod1Amt", "Modulation 1 Amount", controlspec.new(-1.0,1.0,"lin",0.05, 0.0,"",1/40,false))
  params:add{type = "option", id = "mod1Tgt", name = "Modulation 1 Target", options = modTargets, default = 1}
  params:add_separator("")
  params:add{type = "option", id = "mod2Src", name = "Modulation 2 Source", options = modSources, default = 1}
  params:add_control("mod2Amt", "Modulation 2 Amount", controlspec.new(-1.0,1.0,"lin",0.05, 0.0,"",1/40,false))
  params:add{type = "option", id = "mod2Tgt", name = "Modulation 2 Target", options = modTargets, default = 1}
  params:add_separator("")
  params:add{type = "option", id = "mod3Src", name = "Modulation 3 Source", options = modSources, default = 1}
  params:add_control("mod3Amt", "Modulation 3 Amount", controlspec.new(-1.0,1.0,"lin",0.05, 0.0,"",1/40,false))
  params:add{type = "option", id = "mod3Tgt", name = "Modulation 3 Target", options = modTargets, default = 1}
  params:add_separator("")
  params:add{type = "option", id = "mod4Src", name = "Modulation 4 Source", options = modSources, default = 1}
  params:add_control("mod4Amt", "Modulation 4 Amount", controlspec.new(-1.0,1.0,"lin",0.05, 0.0,"",1/40,false))
  params:add{type = "option", id = "mod4Tgt", name = "Modulation 4 Target", options = modTargets, default = 1}
  params:add_separator("")
  params:add{type = "number", id = "modManVal1", name = "Manual Value 1", min = 0, max = 127, default = 0, wrap = false}
  params:add{type = "number", id = "modManVal2", name = "Manual Value 2", min = 0, max = 127, default = 0, wrap = false}
  params:add{type = "number", id = "modManVal3", name = "Manual Value 3", min = 0, max = 127, default = 0, wrap = false}
  
  
  params:add_group("Note On/Off Settings",29)
  params:add{type = "option", id = "imDAC1Start", name = "DAC 1 On", options = allBitNames, default = 7, wrap = false}
  params:add{type = "option", id = "imDAC1End", name = "DAC 1 Off", options = allBitNames, default = 9, wrap = false}
  params:add{type = "option", id = "imDAC1pStart", name = "DAC 1 Proc. On", options = allBitNames, default = 11, wrap = false}
  params:add{type = "option", id = "imDAC1pEnd", name = "DAC 1 Proc. Off", options = allBitNames, default = 12, wrap = false}
  params:add_separator("")
  params:add{type = "option", id = "imDAC2Start", name = "DAC 2 On", options = allBitNames, default = 13, wrap = false}
  params:add{type = "option", id = "imDAC2End", name = "DAC 2 Off", options = allBitNames, default = 14, wrap = false}
  params:add{type = "option", id = "imDAC2pStart", name = "DAC 2 Proc. On", options = allBitNames, default = 15, wrap = false}
  params:add{type = "option", id = "imDAC2pEnd", name = "DAC 2 Proc. Off", options = allBitNames, default = 17, wrap = false}
  params:add_separator("")
  params:add{type = "option", id = "imDAC3Start", name = "DAC 3 On", options = allBitNames, default = 19, wrap = false}
  params:add{type = "option", id = "imDAC3End", name = "DAC 3 Off", options = allBitNames, default = 20, wrap = false}
  params:add{type = "option", id = "imDAC3pStart", name = "DAC 3 Proc. On", options = allBitNames, default = 21, wrap = false}
  params:add{type = "option", id = "imDAC3pEnd", name = "DAC 3 Proc. Off", options = allBitNames, default = 24, wrap = false}
  params:add_separator("")
  params:add{type = "option", id = "imMixStart", name = "Mix Out On", options = allBitNames, default = 25, wrap = false}
  params:add{type = "option", id = "imMixEnd", name = "Mix Out Off", options = allBitNames, default = 26, wrap = false}
  params:add{type = "option", id = "imMixpStart", name = "Mix Proc. Out On", options = allBitNames, default = 29, wrap = false}
  params:add{type = "option", id = "imMixpEnd", name = "Mix Proc. Out Off", options = allBitNames, default = 30, wrap = false}
  params:add_separator("")
  params:add{type = "option", id = "dcOutStart", name = "Diatonic Out On", options = allBitNames, default = 10, wrap = false}
  params:add{type = "option", id = "dcOutEnd", name = "Diatonic Out Off", options = allBitNames, default = 15, wrap = false}
  params:add{type = "option", id = "dcOutpStart", name = "Diatonic P. Out On", options = allBitNames, default = 12, wrap = false}
  params:add{type = "option", id = "dcOutpEnd", name = "Diatonic P. Out Off", options = allBitNames, default = 17, wrap = false}
  params:add_separator("")
  params:add{type = "option", id = "mmOutStart", name = "Modulo Out On", options = allBitNames, default = 22, wrap = false}
  params:add{type = "option", id = "mmOutEnd", name = "Modulo Out Off", options = allBitNames, default = 28, wrap = false}
  params:add{type = "option", id = "mmOutpStart", name = "Modulo P. Out On", options = allBitNames, default = 24, wrap = false}
  params:add{type = "option", id = "mmOutpEnd", name = "Modulo P. Out Off", options = allBitNames, default = 30, wrap = false}
  
  print(norns.state.data)
  params:add{type = "trigger", id = "burnArt", name = "Burn Modern Art", action=function(x)  os.execute "rm /home/we/dust/data/nmMelodyMagic/modernart.png" end}
  
  
  
  params:add_separator("Encoder Settings")
  params:add{type = "number", id = "encSens", name = "Encoder Sensitivity", min = 0, max = 16, default = 0, wrap = false, action=function(x) norns.enc.sens(0,x) end} 
  params:add{type = "option", id = "encAccel", name = "Encoder Acceleration", options = onOff, default = 1, wrap = false, action=function(x) if x==0 then norns.enc.accel(0,false) else norns.enc.accel(0,true) end end} 
  
  params:write(norns.state.data.."default.pset")
  params:read(norns.state.data.."laststate.pset")
  params:bang()
  
  if params:get("mmIns") == 11 then
    mmSelOffset = 1
  else
    mmSelOffset = 0
  end

  if params:get("dcIns") == 5 then
    dcSelOffset = 1
  else
    dcSelOffset = 0
  end
  
  
  clockClk = clock.run(imClockIn)
  advanceClk = clock.run(imAdvanceIn)
  noiseClk = clock.run(imNoiseGen)
  

  updateImOut()
  updateDcOut()
  updateMmOut()
  
--  gridUpdateDsrLEDs()
  
  grid:led(1,8,1)
  grid:led(2,8,1)
  grid:led(6,8,1)
  grid:refresh()
  
  
  redraw()

end





function imClockIn()
  while true do
    if params:get("imClockRate")==0 then
      clock.sync(1/1)
    elseif params:get("imClockRate") < 0 then
      clock.sync(math.abs(params:get("imClockRate")/2))
      imClockTick = 1
      grid:led(1,8,10)
      grid:refresh()
      imClockPulse()
      clock.sync(math.abs(params:get("imClockRate")/2))
      imClockTick = 0
      grid:led(1,8,1)
      grid:refresh()
    else
      clock.sync((1/params:get("imClockRate"))/2)
      imClockTick = 1
      grid:led(1,8,10)
      grid:refresh()
      imClockPulse()
      clock.sync((1/params:get("imClockRate"))/2)
      imClockTick = 0
      grid:led(1,8,1)
      grid:refresh()
    end
  end
end

function imClockPulse()
  local tempArray = imDsrIn
  for i=6,2,-1 do
    imDsrIn[i] = tempArray[i-1]
  end
  imDsrIn[1]=imNoiseVal

  imDsrInString = imDsrIn[6]..imDsrIn[5]..imDsrIn[4]..imDsrIn[3]..imDsrIn[2]..imDsrIn[1]
  for x=1,6 do
    allBits[x]=tonumber(string.sub(string.reverse(imDsrInString),x,x))
  end
  gridUpdateDsrLEDs()
end




function imAdvanceIn()
  while true do
    if params:get("imAdvanceRate")==0 then
      clock.sync(1/1)
    elseif params:get("imAdvanceRate")<0 then 
      clock.sync(math.abs(params:get("imAdvanceRate")/2))
      imAdvTick = 1
      grid:led(2,8,10)
      grid:refresh()
      imAdvancePulse()
      clock.sync(math.abs(params:get("imAdvanceRate")/2))
      imAdvTick = 0
      for i=1,6 do
        imAdvTicks[i]=0
      end
      grid:led(2,8,1)
      grid:refresh()
    else
      clock.sync((1/params:get("imAdvanceRate"))/2)
      imAdvTick = 1
      grid:led(2,8,10)
      grid:refresh()
      imAdvancePulse()
      clock.sync((1/params:get("imAdvanceRate"))/2)
      imAdvTick = 0
      for i=1,6 do
        imAdvTicks[i]=0
      end
      grid:led(2,8,1)
      grid:refresh()
    end
  end
end

function imAdvancePulse()
  if params:get("imRndMode")==1 then -- if random mode
    for i=1,6 do
      imAdvTicks[i]=1
      imShiftBits(i)
    end
    
  elseif params:get("imRndMode")==2 then -- if 1/f mode

    for i=1,5 do -- count up for all counters
      imFModeCounter[i] = imFModeCounter[i]+1 
    end
    

    imAdvTicks[1]=1
    imShiftBits(1) -- shift bit 1 LSB on each advance clock pulse
    
    if imFModeCounter[1]/2>=1 then
      imAdvTicks[2]=1
      imFModeCounter[1] = 0
      imShiftBits(2) -- shift bit 2 every two pulses 
    end
    if imFModeCounter[2]/4>=1 then
      imAdvTicks[3]=1
      imFModeCounter[2] = 0
      imShiftBits(3) -- shift bit 3 every 4 pulses 
    end
    if imFModeCounter[3]/8>=1 then
      imAdvTicks[4]=1
      imFModeCounter[3] = 0
      imShiftBits(4)
    end
    if imFModeCounter[4]/16>=1 then
      imAdvTicks[5]=1
      imFModeCounter[4] = 0
      imShiftBits(5)
    end
    if imFModeCounter[5]/32>=1 then
      imAdvTicks[6]=1
      imFModeCounter[5] = 0
      imShiftBits(6)
    end
    
  end
  updateImOut()
end

function imShiftBits(dsr)
  local tempArray = imDsrBits
  for j=6,2,-1 do
    imDsrBits[dsr][j] = tempArray[dsr][j-1]
  end
  imDsrBits[dsr][1] = imDsrIn[dsr]
end






function imNoiseGen()
  while true do   
    if params:get("imIntNoiseRate")==0 then
      clock.sync(1/1)
    elseif params:get("imIntNoiseRate")<0 then
      clock.sync(math.abs(params:get("imIntNoiseRate")))
      if params:get("imNoiseGen")==1 then
        imUpdateNoise()
      end
    else
      clock.sync(1/params:get("imIntNoiseRate"))
      if params:get("imNoiseGen")==1 then
        imUpdateNoise()
      end
    end     
  end
end


function imUpdateNoise()
  if params:get("imNoiseGen")==1 then -- if internal noise gen
    local rnd = math.random(0,127)
    if rnd>params:get("imSense") then
      imNoiseVal = 1
    else
      imNoiseVal = 0
    end
    
  else -- if external nosie gen
    if params:get("imExtNoiseVal")>params:get("imSense") then
      imNoiseVal = 1
    else
      imNoiseVal = 0
    end

  end
end

function imSelColor(x)
  if x== imSelUI then
    return 15
  else
    return 1
  end
end

function dcSelColor(x)
  if x== dcSelUI then
    return 15
  else
    return 1
  end
end

function out1SelColor(x)
  if x== out1SelUI then
    return 15
  else
    return 1
  end
end

function mmSelColor(x)
  if x== mmSelUI then
    return 15
  else
    return 1
  end
end

function out2SelColor(x)
  if x== out2SelUI then
    return 15
  else
    return 1
  end
end

function modSelColor(x)
  if x== modSelUI then
    return 15
  else
    return 1
  end
end

function noteSelColor(x)
  if x== noteSelUI then
    return 15
  else
    return 1
  end
end


function updateImOut()
  modulate()
  
   -- IM DSR DAC outs
  for d=1,3 do
    local dsr = ""
    for i=1,6 do
      dsr=imDsrBits[i][d]..dsr -- reverse array order
    end
    imDsrStrings[d] = dsr
    
    for x=1,6 do
      allBits[x+(6*d)]=tonumber(string.sub(string.reverse(dsr),x,x))
    end

    imDsrOuts[d] = tonumber(dsr,2)
    imDsrOutsProc[d] = util.clamp(round(imDsrOuts[d]*params:get("imDsrOutsProcAtt"..d)+params:get("imDsrOutsProcOff"..d)),0,127)
  end

  -- IM MIXER
  local mix = 0
  imDsrStrings[4]= ""
  for i=1,6 do
    imDsrStrings[4] = imDsrBits[i][4]..imDsrStrings[4]
    mix = mix + (imDsrBits[i][4]*(params:get("imMix"..i)))
  end
  
  for x=1,6 do
      allBits[x+24]=tonumber(string.sub(string.reverse(imDsrStrings[4]),x,x))
  end
  
  imMixOut = util.clamp(mix,0,127) -- clamp to 0-127
  imMixOutProc = util.clamp(round(imMixOut*params:get("imMixOutProcAtt")+params:get("imMixOutProcOff")),0,127)
  
  updateImMidiOutput()
  gridUpdateDsrLEDs()
  updateCrowOut()
  
  if params:get("mmIns") < 11 then
    updateMmOut()
  end
  
  if params:get("dcIns") < 5 then
    updateDcOut()
  end
  
end


function updateDcOut()
  -- DC OUT
  modulate()
  
  dcStringNote = ""
  dcStringOctave = ""
  if params:get("dcIns") == 1 then
    for i=1,3 do
      dcStringNote = imDsrIn[i]..dcStringNote
    end
    for i=4,6 do
      dcStringOctave = imDsrIn[i]..dcStringOctave
    end
  elseif params:get("dcIns") == 2 then
    for i=1,3 do
      dcStringNote = imDsrBits[i][1]..dcStringNote
    end
    for i=4,6 do
      dcStringOctave = imDsrBits[i][1]..dcStringOctave
    end
  elseif params:get("dcIns") == 3 then
    for i=1,3 do
      dcStringNote = imDsrBits[i][2]..dcStringNote
    end
    for i=4,6 do
      dcStringOctave = imDsrBits[i][2]..dcStringOctave
    end
  elseif params:get("dcIns") == 4 then
    for i=1,3 do
      dcStringNote = imDsrBits[i][3]..dcStringNote
    end
    for i=4,6 do
      dcStringOctave = imDsrBits[i][3]..dcStringOctave
    end    
  elseif params:get("dcIns") == 5 then
    
    dcStringNote = string.sub(intoBinary(params:get("dcManVal")),4,6)
    dcStringOctave = string.sub(intoBinary(params:get("dcManVal")),1,3)
    
  end
  

  dcNote = tonumber(dcStringNote,2)+1

  if params:get("dcBit5")==2 then
    dcStringOctave = string.sub(dcStringOctave,1,1).."0"..string.sub(dcStringOctave,3,3) 
  end
  if params:get("dcBit6")==2 then
    dcStringOctave = "0"..string.sub(dcStringOctave,2,2)..string.sub(dcStringOctave,3,3) 
  end
  dcOctave = tonumber(dcStringOctave,2)+1
  
  
  
  
  local tempNote = 0
  if params:get("dcMajMin")==1 then -- if MAJ
    if dcNote==1 then
      tempNote = 0 -- C
    elseif dcNote==2 then
      tempNote = 2 -- D
    elseif dcNote==3 then
      tempNote = 4 -- E
    elseif dcNote==4 then
      tempNote = 5 -- F
    elseif dcNote==5 then
      tempNote = 7 -- G
    elseif dcNote==6 then
      tempNote = 9 -- A
    elseif dcNote==7 then
      tempNote = 11 -- B
    elseif dcNote==8 then
      tempNote = 12 -- C
    end
  else -- if MIN
    if dcNote==1 then
      tempNote = 0 -- C
    elseif dcNote==2 then
      tempNote = 2 -- D
    elseif dcNote==3 then
      tempNote = 3 -- Eb
    elseif dcNote==4 then
      tempNote = 5 -- F
    elseif dcNote==5 then
      tempNote = 7 -- G
    elseif dcNote==6 then
      tempNote = 8 -- Ab
    elseif dcNote==7 then
      tempNote = 10 -- Bb
    elseif dcNote==8 then
      tempNote = 12 -- C
    end
  end
  
  dcOut = util.clamp(round((((dcOctave-1)*12) + tempNote) * (params:get("dcScaling")/127)) + params:get("dcRoot"),0,127)
  dcOutProc = util.clamp(round((dcOut*params:get("dcOutProcAtt")+params:get("dcOutProcOff"))),0,127)
  
  updateDcMidiOutput()
  updateCrowOut()
  
end









function updateMmOut()   -- MODULO MAGIC OUT
  modulate()

  if params:get("mmIns") == 1 then
    mmTracker = imDsrOuts[1]
  elseif params:get("mmIns") == 2 then
    mmTracker = imDsrOutsProc[1]
  elseif params:get("mmIns") == 3 then
    mmTracker = imDsrOuts[2]
  elseif params:get("mmIns") == 4 then
    mmTracker = imDsrOutsProc[2]
  elseif params:get("mmIns") == 5 then
    mmTracker = imDsrOuts[3]
  elseif params:get("mmIns") == 6 then
    mmTracker = imDsrOutsProc[3]
  elseif params:get("mmIns") == 7 then
    mmTracker = imMixOut
  elseif params:get("mmIns") == 8 then
    mmTracker = imMixOutProc
  elseif params:get("mmIns") == 9 then
    mmTracker = dcOut
  elseif params:get("mmIns") == 10 then
    mmTracker = dcOutProc
  elseif params:get("mmIns") == 11 then
    mmTracker = params:get("mmManVal")
  end


  if mmTracker >= params:get("mmOff") + ((1+mmStepCount)*params:get("mmInit")) then
    mmStepCount = util.clamp(mmStepCount+1,0,params:get("mmSteps"))
  elseif mmTracker < params:get("mmOff") + ((mmStepCount)*params:get("mmInit")) then
    mmStepCount = util.clamp(mmStepCount-1,0,params:get("mmSteps"))  
  end
  
  mmOut = util.clamp(mmTracker + (mmStepCount * (params:get("mmStepSize")+params:get("mmAdd")-params:get("mmSub"))),0,127)
  mmOutProc = util.clamp(round(mmOut*params:get("mmOutProcAtt")+params:get("mmOutProcOff")),0,127)
  
  updateMmMidiOutput()
  updateCrowOut()
  
end



function gridUpdateDsrLEDs()
  -- DSRs
  for i=1,5 do -- y
    for j=1,6 do -- x
      jRev = 7-j
      if i==1 then -- DSRin
        if imDsrIn[j] ~= gridDSR[i][j] then -- check for changes in DSRin and if so, change according LED
          gridDSR[i][j] = imDsrIn[j]
          grid:led(jRev,i,imDsrIn[j]*14+1) -- on == 15, off = 1
          grid:refresh()
        end
      elseif i>=2 then --- DSR 1-3 & mix
        if imDsrBits[j][i-1] ~= gridDSR[i][j] then -- check for changes in DSRs 1-3 & mix and if so, change according LED
          gridDSR[i][j] = imDsrBits[j][i-1]
          grid:led(jRev,i,imDsrBits[j][i-1]*14+1) -- on == 15, off = 1
          grid:refresh()
        end
      end
    end
  end
end


function gridKey(x,y,z)
  
  if x <= 6 and y <= 5 and z == 1 then -- if touch in area of DSRs
    local xRev = 7-x
    if y==1 then
      imDsrIn[xRev] = (-1*imDsrIn[xRev])+1 -- toggle bit 1 or 0
    elseif y>=2 then
      imDsrBits[xRev][y-1] = (-1*imDsrBits[xRev][y-1])+1 -- toggle bit 1 or 0
    end
    gridUpdateDsrLEDs()
    if params:get("gridUpdateOutsImm") == 1 then -- if outputs should be updated immediately, do it, otherwise wait for next clock or advance signal
      updateImOut()
    end
  end
  
  if x == 6 and y == 8 and z == 1 then -- if update imemdiately key
    params:set("gridUpdateOutsImm", (-1*(params:get("gridUpdateOutsImm")-1))+2) -- toggle option on/off
    grid:led(x,y, ((-1* (params:get("gridUpdateOutsImm")-1) ) +1) *14+1) -- toggle grid key on or off (brightness 1 or 15)
    grid:refresh()
  end
  
  
  if x == 1 and y == 8 then -- manual clock tick
    if z==1 then
      imClockTick=1
      imClockPulse()
      grid:led(x,y,15)
      grid:refresh()
    else
      imClockTick=0
      grid:led(x,y,1)
      grid:refresh()
    end
  end
  
  if x == 2 and y == 8 then -- manual advance tick
    if z==1 then
      imAdvTick=1
      imAdvancePulse()
      grid:led(x,y,15)
      grid:refresh()
    else
      imAdvTick=0
      for i=1,6 do
        imAdvTicks[i]=0
      end
      grid:led(x,y,1)
      grid:refresh()
    end
  end
  
end



function updateCrowOut()
  for i=1,4 do
    if params:get("crowOut"..i) == 2 then -- DAC1
      if params:get("crowOut"..i.."Type") == 1 then --CV out
        crow.output[i].volts = ((imDsrOuts[1] + util.clamp(params:get("crowOut"..i.."Off"),0,127))/12) * params:get("crowOut"..i.."Scaling")
      else -- gate out
        if allBits[params:get(midiNoteEnds[1])] == 1 and crowGates[i]==1 then
          crowGateOut(i,0)
        elseif allBits[params:get(midiNoteStarts[1])] == 1 and crowGates[i]==0 then
          crowGateOut(i,1)
        end
      end  
        
    elseif params:get("crowOut"..i) == 3 then
      if params:get("crowOut"..i.."Type") == 1 then --CV out
      crow.output[i].volts = ((imDsrOutsProc[1] + util.clamp(params:get("crowOut"..i.."Off"),0,127))/12) * params:get("crowOut"..i.."Scaling")
      else -- gate out
        if allBits[params:get(midiNoteEnds[2])] == 1 and crowGates[i]==1 then
          crowGateOut(i,0)
        elseif allBits[params:get(midiNoteStarts[2])] == 1 and crowGates[i]==0 then
          crowGateOut(i,1)
        end
      end
    elseif params:get("crowOut"..i) == 4 then
      if params:get("crowOut"..i.."Type") == 1 then --CV out
      crow.output[i].volts = ((imDsrOuts[2] + util.clamp(params:get("crowOut"..i.."Off"),0,127))/12) * params:get("crowOut"..i.."Scaling")
      else -- gate out
        if allBits[params:get(midiNoteEnds[3])] == 1 and crowGates[i]==1 then
          crowGateOut(i,0)
        elseif allBits[params:get(midiNoteStarts[3])] == 1 and crowGates[i]==0 then
          crowGateOut(i,1)
        end
      end
    elseif params:get("crowOut"..i) == 5 then
      if params:get("crowOut"..i.."Type") == 1 then --CV out
      crow.output[i].volts = ((imDsrOutsProc[2] + util.clamp(params:get("crowOut"..i.."Off"),0,127))/12) * params:get("crowOut"..i.."Scaling")
      else -- gate out
        if allBits[params:get(midiNoteEnds[4])] == 1 and crowGates[i]==1 then
          crowGateOut(i,0)
        elseif allBits[params:get(midiNoteStarts[4])] == 1 and crowGates[i]==0 then
          crowGateOut(i,1)
        end
      end
  
    elseif params:get("crowOut"..i) == 6 then
      if params:get("crowOut"..i.."Type") == 1 then --CV out
      crow.output[i].volts = ((imDsrOuts[3] + util.clamp(params:get("crowOut"..i.."Off"),0,127))/12) * params:get("crowOut"..i.."Scaling")
      else -- gate out
        if allBits[params:get(midiNoteEnds[5])] == 1 and crowGates[i]==1 then
          crowGateOut(i,0)
        elseif allBits[params:get(midiNoteStarts[5])] == 1 and crowGates[i]==0 then
          crowGateOut(i,1)
        end
      end
    elseif params:get("crowOut"..i) == 7 then
      if params:get("crowOut"..i.."Type") == 1 then --CV out
      crow.output[i].volts = ((imDsrOutsProc[3] + util.clamp(params:get("crowOut"..i.."Off"),0,127))/12) * params:get("crowOut"..i.."Scaling")
      else -- gate out
        if allBits[params:get(midiNoteEnds[6])] == 1 and crowGates[i]==1 then
          crowGateOut(i,0)
        elseif allBits[params:get(midiNoteStarts[6])] == 1 and crowGates[i]==0 then
          crowGateOut(i,1)
        end
      end
    elseif params:get("crowOut"..i) == 8 then
      if params:get("crowOut"..i.."Type") == 1 then --CV out
      crow.output[i].volts = ((imMixOut + util.clamp(params:get("crowOut"..i.."Off"),0,127))/12) * params:get("crowOut"..i.."Scaling")
      else -- gate out
        if allBits[params:get(midiNoteEnds[7])] == 1 and crowGates[i]==1 then
          crowGateOut(i,0)
        elseif allBits[params:get(midiNoteStarts[7])] == 1 and crowGates[i]==0 then
          crowGateOut(i,1)
        end
      end
    elseif params:get("crowOut"..i) == 9 then
      if params:get("crowOut"..i.."Type") == 1 then --CV out
      crow.output[i].volts = ((imMixOutProc + util.clamp(params:get("crowOut"..i.."Off"),0,127))/12) * params:get("crowOut"..i.."Scaling")
      else -- gate out
        if allBits[params:get(midiNoteEnds[8])] == 1 and crowGates[i]==1 then
          crowGateOut(i,0)
        elseif allBits[params:get(midiNoteStarts[8])] == 1 and crowGates[i]==0 then
          crowGateOut(i,1)
        end
      end
    elseif params:get("crowOut"..i) == 10 then
      if params:get("crowOut"..i.."Type") == 1 then --CV out
      crow.output[i].volts = ((dcOut + util.clamp(params:get("crowOut"..i.."Off"),0,127))/12) * params:get("crowOut"..i.."Scaling")
      else -- gate out
        if allBits[params:get(midiNoteEnds[9])] == 1 and crowGates[i]==1 then
          crowGateOut(i,0)
        elseif allBits[params:get(midiNoteStarts[9])] == 1 and crowGates[i]==0 then
          crowGateOut(i,1)
        end
      end
    elseif params:get("crowOut"..i) == 11 then
      if params:get("crowOut"..i.."Type") == 1 then --CV out
      crow.output[i].volts = ((dcOutProc + util.clamp(params:get("crowOut"..i.."Off"),0,127))/12) * params:get("crowOut"..i.."Scaling")
      else -- gate out
        if allBits[params:get(midiNoteEnds[10])] == 1 and crowGates[i]==1 then
          crowGateOut(i,0)
        elseif allBits[params:get(midiNoteStarts[10])] == 1 and crowGates[i]==0 then
          crowGateOut(i,1)
        end
      end
    elseif params:get("crowOut"..i) == 12 then
      if params:get("crowOut"..i.."Type") == 1 then --CV out
      crow.output[i].volts = ((mmOut + util.clamp(params:get("crowOut"..i.."Off"),0,127))/12) * params:get("crowOut"..i.."Scaling")
      else -- gate out
        if allBits[params:get(midiNoteEnds[11])] == 1 and crowGates[i]==1 then
          crowGateOut(i,0)
        elseif allBits[params:get(midiNoteStarts[11])] == 1 and crowGates[i]==0 then
          crowGateOut(i,1)
        end
      end
    elseif params:get("crowOut"..i) == 13 then
      if params:get("crowOut"..i.."Type") == 1 then --CV out
      crow.output[i].volts = ((mmOutProc + util.clamp(params:get("crowOut"..i.."Off"),0,127))/12) * params:get("crowOut"..i.."Scaling")
      else -- gate out
        if allBits[params:get(midiNoteEnds[12])] == 1 and crowGates[i]==1 then
          crowGateOut(i,0)
        elseif allBits[params:get(midiNoteStarts[12])] == 1 and crowGates[i]==0 then
          crowGateOut(i,1)
        end
      end
    end
  end
  
end



function crowGateOut(out, gate)
  crow.output[out].volts = (gate * 10.0) * params:get("crowOut"..out.."Scaling")
  crowGates[out] = gate
  if crow.connected() == true and gate == 1 then
    drawViz(4)
  end
end

function crowGetIn(x)
  local val = crow.input[x].query()
  
  if val == nil then
    val = 0
  end
  
  return util.clamp(val,0,5*params:get("crowIn"..x.."Range"))
end




function modulate()
  local val = 0
  local outVal = 0
  
  for i=1,4 do
    if params:get("mod"..i.."Src") == 1 then
      val = round(imDsrOuts[1] * params:get("mod"..i.."Amt"))
      outVal = val - modPrevVals[i][1]
      modPrevVals[i][1] = val
    elseif params:get("mod"..i.."Src") == 2 then
      val = round(imDsrOutsProc[1] * params:get("mod"..i.."Amt"))
      outVal = val - modPrevVals[i][2]
      modPrevVals[i][2] = val
    elseif params:get("mod"..i.."Src") == 3 then
      val = round(imDsrOuts[2] * params:get("mod"..i.."Amt"))
      outVal = val - modPrevVals[i][3]
      modPrevVals[i][3] = val
    elseif params:get("mod"..i.."Src") == 4 then
      val = round(imDsrOutsProc[2] * params:get("mod"..i.."Amt"))
      outVal = val - modPrevVals[i][4]
      modPrevVals[i][4] = val
    elseif params:get("mod"..i.."Src") == 5 then
      val = round(imDsrOuts[3] * params:get("mod"..i.."Amt"))
      outVal = val - modPrevVals[i][5]
      modPrevVals[i][5] = val
    elseif params:get("mod"..i.."Src") == 6 then
      val = round(imDsrOutsProc[3] * params:get("mod"..i.."Amt"))
      outVal = val - modPrevVals[i][6]
      modPrevVals[i][6] = val
    elseif params:get("mod"..i.."Src") == 7 then
      val = round(imMixOut * params:get("mod"..i.."Amt"))
      outVal = val - modPrevVals[i][7]
      modPrevVals[i][7] = val
    elseif params:get("mod"..i.."Src") == 8 then
      val = round(imMixOutProc * params:get("mod"..i.."Amt"))
      outVal = val - modPrevVals[i][8]
      modPrevVals[i][8] = val
    elseif params:get("mod"..i.."Src") == 9 then
      val = round(dcOut * params:get("mod"..i.."Amt"))
      outVal = val - modPrevVals[i][9]
      modPrevVals[i][9] = val
    elseif params:get("mod"..i.."Src") == 10 then
      val = round(dcOutProc * params:get("mod"..i.."Amt"))
      outVal = val - modPrevVals[i][10]
      modPrevVals[i][10] = val
    elseif params:get("mod"..i.."Src") == 11 then
      val = round(mmOut * params:get("mod"..i.."Amt"))
      outVal = val - modPrevVals[i][11]
      modPrevVals[i][11] = val
    elseif params:get("mod"..i.."Src") == 12 then
      val = round(mmOutProc * params:get("mod"..i.."Amt"))
      outVal = val - modPrevVals[i][12]
      modPrevVals[i][12] = val
    elseif params:get("mod"..i.."Src") == 13 then
      val = round(params:get("modManVal1") * params:get("mod"..i.."Amt"))
      outVal = val - modPrevVals[i][13]
      modPrevVals[i][13] = val
    elseif params:get("mod"..i.."Src") == 14 then
      val = round(params:get("modManVal2") * params:get("mod"..i.."Amt"))
      outVal = val - modPrevVals[i][14]
      modPrevVals[i][14] = val
    elseif params:get("mod"..i.."Src") == 15 then
      val = round(params:get("modManVal3") * params:get("mod"..i.."Amt"))
      outVal = val - modPrevVals[i][15]
      modPrevVals[i][15] = val
    elseif params:get("mod"..i.."Src") == 16 then -- crow in 1
      val = round(((crowGetIn(1)/(5*params:get("crowIn1Range")))*127) * params:get("mod"..i.."Amt"))
      outVal = val - modPrevVals[i][16]
      modPrevVals[i][16] = val
    elseif params:get("mod"..i.."Src") == 17 then -- crow in 2
      val = round(((crowGetIn(2)/(5*params:get("crowIn2Range")))*127) * params:get("mod"..i.."Amt"))
      outVal = val - modPrevVals[i][17]
      modPrevVals[i][17] = val    
    end

    params:delta(modTgtIds[params:get("mod"..i.."Tgt")], outVal)
  end
  
end



-- BUTTONS
function key(id,st)
  if id==1 then
    if st==1 then
      k1held = 1
    else
      k1held = 0
      artOn = 0
    end
  elseif id==2 then
    if k1held == 0 then
      if st==1 then
        imClockTick=1
        imClockPulse()
      else
        imClockTick=0
      end
    else
      if st==1 then
        allNotesOff()
        midiPanic = 1
      else
        midiPanic = 0
      end
    end
  elseif id==3 then
    if k1held==0 then
      if st==1 then
        imAdvTick=1
        imAdvancePulse()
      else
        imAdvTick=0
        for i=1,6 do
          imAdvTicks[i]=0
        end
      end
    else
      if st==1 then
        params:write(norns.state.data.."laststate.pset")
        savedState = 1
      else
        savedState = 0
      end
    end
  end
end


-- ENCODERS
function enc(id,delta)
  if id==1 then
    if selPage < 8 then
      screenClear()
      page8 = 0
      
    elseif selPage == 8 and delta <0 then
      _norns.screen_export_png(norns.state.data.."modernart.png")
      page8 = 0
      --screen.rotate(-rotateCounter*math.pi/180)
      --rotateCounter = 0
    end
    selPage = util.clamp(selPage + delta, 1,8)

    if selPage == 8 and page8 == 0 then
      screen.display_png(norns.state.data.."modernart.png", 0, 0)
      page8 = 1
    elseif selPage == 8 and page8 == 1 then
    end
  
    
  elseif id==2 then
    if selPage == 1 then
      imSelUI = util.clamp(imSelUI + delta,1,12) -- select ui element
    elseif selPage == 2 then
      dcSelUI = util.clamp(dcSelUI + delta,1,6+dcSelOffset)
    elseif selPage == 3 then
      out1SelUI = util.clamp(out1SelUI + delta,1,10)
    elseif selPage == 4 then
      mmSelUI = util.clamp(mmSelUI + delta,1,7+mmSelOffset)
    elseif selPage == 5 then
      out2SelUI = util.clamp(out2SelUI + delta,1,2)
    elseif selPage == 6 then
      modSelUI = util.clamp(modSelUI + delta,1,15)
    elseif selPage == 7 then
      noteSelUI = util.clamp(noteSelUI + delta,1,3)
    elseif selPage == 8 then

    end
    
    
    
  elseif id==3 then -- change ui element value
    if selPage == 1 then
      if imSelUI == 1 then
        params:delta("imClockRate",delta)
      elseif imSelUI == 2 then
        params:delta("imAdvanceRate",delta)
      elseif imSelUI == 3 then
        params:delta("imRndMode",delta)
      elseif imSelUI == 4 then
        params:delta("imNoiseGen",delta)
      elseif imSelUI == 5 and params:get("imNoiseGen") == 1 then
        params:delta("imIntNoiseRate",delta)
      elseif imSelUI == 5 and params:get("imNoiseGen") == 2 then
        params:delta("imExtNoiseVal",delta)
      elseif imSelUI == 6 then
        params:delta("imSense",delta)
      elseif imSelUI == 7 then
        params:delta("imMix1",delta)
      elseif imSelUI == 8 then
        params:delta("imMix2",delta)
      elseif imSelUI == 9 then
        params:delta("imMix3",delta)
      elseif imSelUI == 10 then
        params:delta("imMix4",delta)
      elseif imSelUI == 11 then
        params:delta("imMix5",delta)
      elseif imSelUI == 12 then
        params:delta("imMix6",delta)
      end
      
      
      
    elseif selPage == 2 then
      
      if dcSelUI == 1 then
        params:delta(dcUiElements[dcSelUI],delta)
      elseif dcSelUI > 1 and dcSelOffset == 0 then
        params:delta(dcUiElements[dcSelUI+1],delta)
      elseif dcSelUI > 1 and dcSelOffset == 1 then
        params:delta(dcUiElements[dcSelUI],delta)
      end
      
      
    elseif selPage == 3 then -- PROCS
      if out1SelUI == 1 then
        params:delta("imDsrOutsProcAtt1",delta)
      elseif out1SelUI == 2 then
        params:delta("imDsrOutsProcOff1",delta)
      elseif out1SelUI == 3 then
        params:delta("imDsrOutsProcAtt2",delta)
      elseif out1SelUI == 4 then
        params:delta("imDsrOutsProcOff2",delta)
      elseif out1SelUI == 5 then
        params:delta("imDsrOutsProcAtt3",delta)
      elseif out1SelUI == 6 then
        params:delta("imDsrOutsProcOff3",delta)
      elseif out1SelUI == 7 then
        params:delta("imMixOutProcAtt",delta)
      elseif out1SelUI == 8 then
        params:delta("imMixOutProcOff",delta)
      elseif out1SelUI == 9 then
        params:delta("dcOutProcAtt",delta)
      elseif out1SelUI == 10 then
        params:delta("dcOutProcOff",delta)
      end
      
      
    
    elseif selPage == 4 then -- MM
      
      if mmSelUI == 1 then
        params:delta(mmUiElements[mmSelUI],delta)
      elseif mmSelUI > 1 and mmSelOffset == 0 then
        params:delta(mmUiElements[mmSelUI+1],delta)
      elseif mmSelUI > 1 and mmSelOffset == 1 then
        params:delta(mmUiElements[mmSelUI],delta)
      end
    
    
    elseif selPage == 5 then -- PROCS
      if out2SelUI == 1 then
        params:delta("mmOutProcAtt",delta)
      elseif out2SelUI == 2 then
        params:delta("mmOutProcOff",delta)
      end
    
    elseif selPage == 6 then -- Modulation
      
      if modSelUI == 1 then
        params:delta("mod1Src",delta)
      elseif modSelUI == 2 then
        params:delta("mod1Amt",delta)
      elseif modSelUI == 3 then
        params:delta("mod1Tgt",delta)
      elseif modSelUI == 4 then
        params:delta("mod2Src",delta)
      elseif modSelUI == 5 then
        params:delta("mod2Amt",delta)
      elseif modSelUI == 6 then
        params:delta("mod2Tgt",delta)
      elseif modSelUI == 7 then
        params:delta("mod3Src",delta)
      elseif modSelUI == 8 then
        params:delta("mod3Amt",delta)
      elseif modSelUI == 9 then
        params:delta("mod3Tgt",delta)
      elseif modSelUI == 10 then
        params:delta("mod4Src",delta)
      elseif modSelUI == 11 then
        params:delta("mod4Amt",delta)
      elseif modSelUI == 12 then
        params:delta("mod4Tgt",delta)
      elseif modSelUI == 13 then
        params:delta("modManVal1",delta)
      elseif modSelUI == 14 then
        params:delta("modManVal2",delta)
      elseif modSelUI == 15 then
        params:delta("modManVal3",delta)
      end
      
    elseif selPage == 7 then -- MIDI Note Settings
      if noteSelUI == 1 then
        noteOutSel = util.clamp(noteOutSel + delta,1, 12)
      elseif noteSelUI == 2 then
        params:delta(midiNoteStarts[noteOutSel],delta)
      elseif noteSelUI == 3 then
        params:delta(midiNoteEnds[noteOutSel],delta)
      end
    
    end
  end
end



function redraw()
  screen.line_width(1)

  
  if selPage == 1 then -- infinite melody UI
    screenClear()
    --- TOP
    screen.level(1)
    screen.rect(0,0,128,7)
    screen.fill()
    screen.level(4)
    screen.move(64,5)
    screen.text_center(pageLabels[selPage])

    --- MIDDLE
    
    -- draw dsr grid
    imDrawDsrs(0,9)
    
    screen.level(imSelColor(1))
    screen.move(32,14)
    screen.text("Clock: "..params:get("imClockRate"))
    screen.level(imSelColor(2))
    screen.move(32,20)
    screen.text("Adv.: "..params:get("imAdvanceRate"))
    screen.level(imSelColor(3))
    screen.move(32,26)
    screen.text("Mode: "..imRndOptions[params:get("imRndMode")])

    screen.level(imSelColor(4))
    screen.move(32,36)
    screen.text("Noise: "..intExt[params:get("imNoiseGen")])
    if params:get("imNoiseGen")==1 then
      screen.level(imSelColor(5))
      screen.move(32,42)
      screen.text("N.Rate: "..params:get("imIntNoiseRate"))
    else
      screen.level(imSelColor(5))
      screen.move(32,42)
      screen.text("N.Val: "..params:get("imExtNoiseVal"))      
    end
    screen.level(imSelColor(6))
    screen.move(32,48)
    screen.text("Sense: "..params:get("imSense"))
    if imNoiseVal == 1 then
      screen.rect(29,46,2,2)
      screen.fill()
    end
    
    
    
    -- mix values
    screen.level(1)
    for i=1,6 do
      screen.level(imSelColor(6+i))
      if imDsrBits[i][4] == 1 then
        screen.rect(93,12+(i-1)*6,2,2)
        screen.fill()
      end
      screen.move(96,14+(i-1)*6)
      screen.text("m"..i..":")
      screen.move(115,14+(i-1)*6)
      screen.text(params:get("imMix"..i))
    end

    --- BOTTOM
    screen.level(1)
    screen.rect(0,57,128,7)
    screen.fill()
    screen.level(4)
    screen.move(0,63)
    if params:get("imDAC1Midi") == 1 then
      screen.text("D1:"..num2Note(imDsrOuts[1]))
    else
      screen.text("D1:"..imDsrOuts[1])
    end
    screen.move(32,63)
    if params:get("imDAC2Midi") == 1 then
      screen.text("D2:"..num2Note(imDsrOuts[2]))
    else
      screen.text("D2:"..imDsrOuts[2])
    end
    screen.move(64,63)
    if params:get("imDAC3Midi") == 1 then
      screen.text("D3:"..num2Note(imDsrOuts[3]))
    else
      screen.text("D3:"..imDsrOuts[3])
    end
    screen.move(96,63)
    if params:get("imMixMidi") == 1 then
      screen.text("Mix:"..num2Note(imMixOut))
    else
      screen.text("Mix:"..imMixOut)
    end

   
   
   
   
   
   
    
  elseif selPage == 2 then -- diatonic converter UI
    screenClear()
    
    --- TOP
    screen.level(1)
    screen.rect(0,0,128,7)
    screen.fill()
    screen.level(4)
    screen.move(64,5)
    screen.text_center(pageLabels[selPage])

    --- MIDDLE
    
    dcDrawVis(0,9)

    screen.level(dcSelColor(1))
    screen.move(32,14)
    screen.text("Input: "..dcIns[params:get("dcIns")])
    if dcSelOffset == 1 then
      screen.level(dcSelColor(2))
      screen.move(92,14)
      screen.text("-> "..params:get("dcManVal"))
    end
    
    screen.level(dcSelColor(2+dcSelOffset))
    screen.move(32,20)
    screen.text("Root: "..params:get("dcRoot").." / "..dcMidiNotes[params:get("dcRoot")%12+1]..math.floor(params:get("dcRoot")/12)-1)
    screen.level(dcSelColor(3+dcSelOffset))
    screen.move(32,26)
    screen.text("Scale: "..dcMajMin[params:get("dcMajMin")])
    screen.level(dcSelColor(4+dcSelOffset))
    screen.move(32,32)
    screen.text("Scaling: "..round((params:get("dcScaling")/127)*100)/100)
    screen.level(dcSelColor(5+dcSelOffset))
    screen.move(32,38)
    screen.text("Bit 5: "..onOff[params:get("dcBit5")])
    screen.level(dcSelColor(6+dcSelOffset))
    screen.move(32,44)
    screen.text("Bit 6: "..onOff[params:get("dcBit6")])

    
    --- BOTTOM
    screen.level(1)
    screen.rect(0,57,128,7)
    screen.fill()
    screen.level(4)
    screen.move(0,63)
    if params:get("dcOutMidi") == 1 then
      screen.text("Out: "..num2Note(dcOut))
    else
      screen.text("Out: "..dcOut)
    end
    --screen.text("Out: "..dcOut.." / "..num2Note(dcOut))
  
    
  elseif selPage == 3 then -- output processors 1
    screenClear()
    --- TOP
    screen.level(1)
    screen.rect(0,0,128,7)
    screen.fill()
    screen.level(4)
    screen.move(64,5)
    screen.text_center(pageLabels[selPage])

    --- MIDDLE
    screen.level(out1SelColor(1))
    screen.move(0,14)
    screen.text("D1 Att: "..params:get("imDsrOutsProcAtt1"))
    screen.level(out1SelColor(2))
    screen.move(64,14)
    screen.text("D1 Off: "..params:get("imDsrOutsProcOff1"))
    screen.level(out1SelColor(3))
    screen.move(0,20)
    screen.text("D2 Att: "..params:get("imDsrOutsProcAtt2"))
    screen.level(out1SelColor(4))
    screen.move(64,20)
    screen.text("D2 Off: "..params:get("imDsrOutsProcOff2"))
    screen.level(out1SelColor(5))
    screen.move(0,26)
    screen.text("D3 Att: "..params:get("imDsrOutsProcAtt3"))
    screen.level(out1SelColor(6))
    screen.move(64,26)
    screen.text("D3 Off: "..params:get("imDsrOutsProcOff3"))
    screen.level(out1SelColor(7))
    screen.move(0,36)
    screen.text("Mix Att: "..params:get("imMixOutProcAtt"))
    screen.level(out1SelColor(8))
    screen.move(64,36)
    screen.text("Mix Off: "..params:get("imMixOutProcOff"))
    screen.level(out1SelColor(9))
    screen.move(0,46)
    screen.text("Dia Att: "..params:get("dcOutProcAtt"))
    screen.level(out1SelColor(10))
    screen.move(64,46)
    screen.text("Dia Off: "..params:get("dcOutProcOff"))
    
    --- BOTTOM
    screen.level(1)
    screen.rect(0,50,128,14)
    screen.fill()
    screen.level(4)
    screen.move(0,56)
    if params:get("imDAC1pMidi") == 1 then
      screen.text("D1-p: "..num2Note(imDsrOutsProc[1]))
    else
      screen.text("D1-p: "..imDsrOutsProc[1])
    end
    screen.move(42,56)
    if params:get("imDAC2pMidi") == 1 then
      screen.text("D2-p: "..num2Note(imDsrOutsProc[2]))
    else
      screen.text("D2-p: "..imDsrOutsProc[2])
    end
    screen.move(85,56)
    if params:get("imDAC3pMidi") == 1 then
      screen.text("D3-p: "..num2Note(imDsrOutsProc[3]))
    else
      screen.text("D3-p: "..imDsrOutsProc[3])
    end
    screen.move(0,63)
    if params:get("imMixpMidi") == 1 then
      screen.text("Mix-p: "..num2Note(imMixOutProc))
    else
      screen.text("Mix-p: "..imMixOutProc)
    end

    screen.move(85,63)
    if params:get("dcOutpMidi") == 1 then
      screen.text("Dia-p: "..num2Note(dcOutProc))
    else
      screen.text("Dia-p: "..dcOutProc)
    end

    
    
  elseif selPage == 4 then -- modulo magic
    screenClear()
    --- TOP
    screen.level(1)
    screen.rect(0,0,128,7)
    screen.fill()
    screen.level(4)
    screen.move(64,5)
    screen.text_center(pageLabels[selPage])

    
    --- MIDDLE
    
    mmDrawVis(0,9)
    
    screen.level(mmSelColor(1))
    screen.move(32,14)
    screen.text("Input: "..mmIns[params:get("mmIns")])
    if mmSelOffset == 1 then
      screen.level(mmSelColor(2))
      screen.move(92,14)
      screen.text("-> "..params:get("mmManVal"))
    else
      screen.move(92,14)
      screen.text("-> "..mmTracker)
    end
    screen.level(mmSelColor(2+mmSelOffset))
    screen.move(32,21)
    screen.text("Initiation: "..params:get("mmInit"))
    screen.level(mmSelColor(3+mmSelOffset))
    screen.move(32,28)
    screen.text("Offset: "..params:get("mmOff"))
    screen.level(mmSelColor(4+mmSelOffset))
    screen.move(32,35)
    screen.text("Step Size: "..params:get("mmStepSize"))
    screen.level(mmSelColor(5+mmSelOffset))
    screen.move(32,42)
    screen.text("Add: "..params:get("mmAdd"))
    screen.level(mmSelColor(6+mmSelOffset))
    screen.move(32,49)
    screen.text("Subtract: "..params:get("mmSub"))
    screen.level(mmSelColor(7+mmSelOffset))
    screen.move(32,56)
    screen.text("Steps: "..params:get("mmSteps"))
    
    
    --- BOTTOM
    screen.level(1)
    screen.rect(0,57,128,7)
    screen.fill()
    screen.level(4)
    screen.move(0,63)
    if params:get("mmOutMidi") == 1 then
      screen.text("Out: "..num2Note(mmOut))
    else
      screen.text("Out: "..mmOut)
    end
    --screen.text("Out: "..mmOut.." / "..num2Note(mmOut))
    screen.move(96,63)
    screen.text("Step: "..mmStepCount)
    
    
  elseif selPage == 5 then -- output processors 2
    screenClear()
    --- TOP
    screen.level(1)
    screen.rect(0,0,128,7)
    screen.fill()
    screen.level(4)
    screen.move(64,5)
    screen.text_center(pageLabels[selPage])

    --- MIDDLE
    screen.level(out2SelColor(1))
    screen.move(0,14)
    screen.text("Mod Att: "..params:get("mmOutProcAtt"))
    screen.level(out2SelColor(2))
    screen.move(64,14)
    screen.text("Mod Off: "..params:get("mmOutProcOff"))
    
    
    --- BOTTOM
    screen.level(1)
    screen.rect(0,57,128,14)
    screen.fill()
    screen.level(4)
    screen.move(0,63)
    if params:get("mmOutpMidi") == 1 then
      screen.text("Mod-p: "..num2Note(mmOutProc))
    else
      screen.text("Mod-p: "..mmOutProc)
    end
    --screen.text("Mod-p: "..mmOutProc)
    
    
  elseif selPage == 6 then -- modulation
    screenClear()
    --- TOP
    screen.level(1)
    screen.rect(0,0,128,7)
    screen.fill()
    screen.level(4)
    screen.move(64,5)
    screen.text_center(pageLabels[selPage])

    --- MIDDLE
    screen.level(1)
    screen.move(5,14)
    screen.text("Source")
    screen.move(48,14)
    screen.text("Amount")
    screen.move(85,14)
    screen.text("Target")
    screen.move(0,17)
    screen.line_rel(128,0)
    screen.stroke()
    
    screen.level(modSelColor(1))
    screen.move(5,25)
    screen.text(modSources[params:get("mod1Src")])
    screen.level(modSelColor(2))
    screen.move(48,25)
    screen.text(params:get("mod1Amt"))
    screen.level(modSelColor(3))
    screen.move(85,25)
    screen.text(modTargets[params:get("mod1Tgt")])
    
    screen.level(modSelColor(4))
    screen.move(5,32)
    screen.text(modSources[params:get("mod2Src")])
    screen.level(modSelColor(5))
    screen.move(48,32)
    screen.text(params:get("mod2Amt"))
    screen.level(modSelColor(6))
    screen.move(85,32)
    screen.text(modTargets[params:get("mod2Tgt")])
    
    screen.level(modSelColor(7))
    screen.move(5,39)
    screen.text(modSources[params:get("mod3Src")])
    screen.level(modSelColor(8))
    screen.move(48,39)
    screen.text(params:get("mod3Amt"))
    screen.level(modSelColor(9))
    screen.move(85,39)
    screen.text(modTargets[params:get("mod3Tgt")])
    
    screen.level(modSelColor(10))
    screen.move(5,46)
    screen.text(modSources[params:get("mod4Src")])
    screen.level(modSelColor(11))
    screen.move(48,46)
    screen.text(params:get("mod4Amt"))
    screen.level(modSelColor(12))
    screen.move(85,46)
    screen.text(modTargets[params:get("mod4Tgt")])
    
    screen.level(modSelColor(13))
    screen.move(5,55)
    screen.text("M1: "..params:get("modManVal1"))
    screen.level(modSelColor(14))
    screen.move(48,55)
    screen.text("M2: "..params:get("modManVal2"))
    screen.level(modSelColor(15))
    screen.move(85,55)
    screen.text("M3: "..params:get("modManVal3"))
    
    --- BOTTOM
    screen.level(1)
    screen.rect(0,57,128,14)
    screen.fill()
    screen.level(4)
    
    
    for i=1,3 do -- show Crow input values if selected as mod sources
      if params:get("mod"..i.."Src") == 16 then
        screen.move(0,63)
        screen.text("Crow In 1: "..round(crowGetIn(1)/((5*params:get("crowIn1Range"))*127)) )
      end
      if params:get("mod"..i.."Src") == 17 then
        screen.move(64,63)
       screen.text("Crow In 2: "..round(crowGetIn(2)/((5*params:get("crowIn2Range"))*127)) )
      end
    end
    
    
    
  elseif selPage == 7 then -- midi note settings
    screenClear()
    
    --- TOP
    screen.level(1)
    screen.rect(0,0,128,7)
    screen.fill()
    screen.level(4)
    screen.move(64,5)
    screen.text_center(pageLabels[selPage])

    --- MIDDLE
    
    screen.level(noteSelColor(1))
    screen.move(32,14)
    screen.text("Output: "..modSources[noteOutSel])
    
    screen.level(noteSelColor(2))
    screen.move(32,21)
    screen.text("Note On: "..allBitNames[params:get(midiNoteStarts[noteOutSel])])
    
    screen.level(noteSelColor(3))
    screen.move(32,28)
    screen.text("Note Off: "..allBitNames[params:get(midiNoteEnds[noteOutSel])])
    
    noteDrawDsrs(0,9)
    
    
    --- BOTTOM
    screen.level(1)
    screen.rect(0,57,128,14)
    screen.fill()
    screen.level(4)
    screen.move(0,63)
    screen.text("")
    
    
    elseif selPage == 8 then -- visualizer
      drawViz(1)
  end
  
  if k1held == 1 then
    drawManual(selPage)
  end
  
  
  
  if midiPanic == 1 then
    screen.level(10)
    screen.rect(0,0,128,64)
    screen.fill()
    screen.level(0)
    screen.move(64,32)
    screen.text_center("PANIC!")
  end
  
  if savedState == 1 then
    screen.level(5)
    screen.rect(0,0,128,64)
    screen.fill()
    screen.level(15)
    screen.move(64,32)
    screen.text_center("SAVED: laststate.pset")
  end
  
  
  screen.update()

end


local msgs = {
  "ken stone 4 ever",
  "to infinity and beyond",
  "i <3 u",
  "you're a nice person",
  "this is modern art",
  "pling",
  "plong",
  "boop",
  "beep",
  "listen to the machine",
  "bleep",
  "bloop",
  "synth nerds unite",
  "norns for president",
  "it's mono-me",
  "listen",
  "watch",
  "fall sleep",
  "ever tried this on drugs?",
  "say no to drugs",
  "billions of stars",
  "someone loves you",
  "improvise. adapt. norns.",
  "you're a wizard",
  " ",
  " ",
  " ",
  " ",
  " ",
  " "
}



-- MANUAL
function drawManual(page)
  
  if page == 1 then -- infinite melody
    screenClear()
    if imSelUI == 1 then --clock
      screen.move(0,7)
      screen.level(15)
      screen.text("Clock")
      
      screen.level(8)
      screen.move(0,17)
      screen.text("- 'DSR In' clock rate")
      screen.move(0,27)
      screen.text("- Pushes 1 or 0 into 'DSR In'")
      screen.move(0,37)
      screen.text("- Faster = more randomness")
      screen.move(0,47)
      screen.text("- Synced to norns' clock")
    elseif imSelUI == 2 then -- advance
      screen.move(0,7)
      screen.level(15)
      screen.text("Advance")
      
      screen.level(8)
      screen.move(0,17)
      screen.text("- Rhythm clock rate")
      screen.move(0,27)
      screen.text("- Pushes 'DSR In' bits down")
      screen.move(0,37)
      screen.text("- Faster = faster melodies")
      screen.move(0,47)
      screen.text("- Synced to norns' clock")
    elseif imSelUI == 3 then --mode
      screen.move(0,7)
      screen.level(15)
      screen.text("Advance Mode")
      
      screen.level(8)
      screen.move(0,17)
      screen.text("rnd: all bits are pushed")
      screen.move(0,27)
      screen.text("at once (more randomness)")
      screen.move(0,40)
      screen.text("1/f: low bits are pushed more")
      screen.move(0,50)
      screen.text("often (more small changes)")
      
    elseif imSelUI == 4 or imSelUI == 5 then --noise gen
      screen.move(0,7)
      screen.level(15)
      screen.text("Digital Noise Generator")
      
      screen.level(8)
      screen.move(0,17)
      screen.text("- Queues 1 or 0 at 'DSR In'")
      screen.move(0,27)
      screen.text("- int: internal noise gen")
      screen.move(0,37)
      screen.text("- ext: external signal")
      screen.move(0,50)
      screen.text("Hint:")
      screen.move(0,57)
      screen.text("Map ext. signal to MIDI CC!")
    elseif imSelUI == 6 then --sense
      screen.move(0,7)
      screen.level(15)
      screen.text("Sense / Comparator")
      
      screen.level(8)
      screen.move(0,17)
      screen.text("- Digital noise threshold")
      screen.move(0,27)
      screen.text("- Noise > Sense: 1")
      screen.move(0,37)
      screen.text("- Noise <= Sense: 0")
      screen.move(0,47)
      screen.text("- Sense = 64: 50/50 chance")
    elseif imSelUI > 6 then --mix pots
      screen.move(0,7)
      screen.level(15)
      screen.text("Mixer")
      
      screen.level(8)
      screen.move(0,17)
      screen.text("m1-6 correspond to the")
      screen.move(0,27)
      screen.text("bottom row of bits and add")
      screen.move(0,37)
      screen.text("their values to the mix")
      screen.move(0,47)
      screen.text("output when bits are high.")
    end
  elseif page == 2 then -- diatonic converter
    screenClear()
    if dcSelUI == 1 then -- input
      screen.move(0,7)
      screen.level(15)
      screen.text("Input")
      
      screen.level(8)
      screen.move(0,20)
      screen.text("Select an output to be converted")
      screen.move(0,30)
      screen.text("to diatonic note numbers")
    elseif dcSelUI == 2+dcSelOffset then -- root
      screen.move(0,7)
      screen.level(15)
      screen.text("Root")
      
      screen.move(0,20)
      screen.level(8)
      screen.text("Offsets diatonic note output")
    elseif dcSelUI == 3+dcSelOffset then -- scale
      screen.move(0,7)
      screen.level(15)
      screen.text("Scale")
      
      screen.level(8)
      screen.move(0,17)
      screen.text("- Diatonic output scale")
      screen.move(0,27)
      screen.text("- Maj: C D E F G A B C")
      screen.move(0,37)
      screen.text("- Min: C D Eb F G Ab Bb C")
    elseif dcSelUI == 4+dcSelOffset then -- scaling
      screen.move(0,7)
      screen.level(15)
      screen.text("Ouput Scaling")
      
      screen.level(8)
      screen.move(0,17)
      screen.text("- Scales output values")
      screen.move(0,27)
      screen.text("- Scaling < 1.0 deteriorates")
      screen.move(0,37)
      screen.text("diatonic note intervals")
      
    elseif dcSelUI > 4+dcSelOffset then -- bit disable
      screen.move(0,7)
      screen.level(15)
      screen.text("Bit Disable")
      
      screen.level(8)
      screen.move(0,17)
      screen.text("- Bits 4+5+6: octaves -1 to 6")
      screen.move(0,27)
      screen.text("- Bit 4 only: octaves -1 to 0")
      screen.move(0,40)
      screen.text("Hint:")
      screen.move(0,47)
      screen.text("Use 'Root' to offset notes!")
      
      
    end
  elseif page == 3 or page == 5 then -- output processing
      screenClear()
      screen.move(0,7)
      screen.level(15)
      screen.text("Output Processing")
      
      screen.level(8)
      screen.move(0,17)
      screen.text("- Scale and offset outputs")
      screen.move(0,27)
      screen.text("- Each processed output has")
      screen.move(0,37)
      screen.text("an individual MIDI setting!")
      screen.move(0,57)
      screen.text("See EDIT>MIDI Output Settings")
      
  elseif page == 4 then -- modulo magic
    screenClear()
    if mmSelUI == 1 then -- input
      screen.move(0,7)
      screen.level(15)
      screen.text("Input")
      
      screen.level(8)
      screen.move(0,17)
      screen.text("- Select output to process")
    elseif mmSelUI == 2+mmSelOffset then -- initiation
      screen.move(0,7)
      screen.level(15)
      screen.text("Initiation")
      
      screen.level(8)
      screen.move(0,17)
      screen.text("- Threshold for processing")
      screen.move(0,27)
      screen.text("- Triggerable multiple times")
      screen.move(0,37)
      screen.text("as set by 'Steps'")
    elseif mmSelUI == 3+mmSelOffset then -- offset
      screen.move(0,7)
      screen.level(15)
      screen.text("Offset")
      
      screen.level(8)
      screen.move(0,17)
      screen.text("- Added to 1st 'Initiation'")
    elseif mmSelUI == 4+mmSelOffset then -- offset
      screen.move(0,7)
      screen.level(15)
      screen.text("Step Size")
      
      screen.level(8)
      screen.move(0,17)
      screen.text("- Added/subtracted from")
      screen.move(0,27)
      screen.text("input on 'Initiation' trigger")
    elseif mmSelUI == 5+mmSelOffset or mmSelUI == 6+mmSelOffset then -- offset
      screen.move(0,7)
      screen.level(15)
      screen.text("Add/Subtract")
      
      screen.level(8)
      screen.move(0,17)
      screen.text("- ... from 'Step Size' value")
      screen.move(0,27)
      screen.text("- Used for modulation")
    elseif mmSelUI == 7+mmSelOffset then -- offset
      screen.move(0,7)
      screen.level(15)
      screen.text("Steps")
      
      screen.level(8)
      screen.move(0,17)
      screen.text("- Number of times that")
      screen.move(0,27)
      screen.text("'Initiation' can be triggered")
      
    end
  elseif page == 6 then -- modulation
      screenClear()
      screen.move(0,7)
      screen.level(15)
      screen.text("Modulation")
      
      screen.level(8)
      screen.move(0,17)
      screen.text("- Modulate 'Target'w/'Source")
      screen.move(0,27)
      screen.text("- 'Amount' can be negative")
      screen.move(0,37)
      screen.text("- 3 'Manual' sources M1-3")
      screen.move(0,47)
      screen.text("can be mapped to MIDI CC")
      
  elseif page == 7 then -- midi note settings
      screenClear()
      screen.move(0,7)
      screen.level(15)
      screen.text("Note On/Off Settings")
      
      screen.level(8)
      screen.move(0,17)
      screen.text("- Choose output and select")
      screen.move(0,24)
      screen.text("bits to turn on and off")
      screen.move(0,31)
      screen.text("its notes")
      screen.move(0,45)
      screen.text("- A note must be off")
      screen.move(0,52)
      screen.text("before a new one can start")
      
  elseif page == 8 then -- modern art
    if artOn == 0 then
      screen.move(math.random(32,96),math.random(7,57))
      screen.level(math.random(1,10))
      screen.text_center(msgs[math.random(1,#msgs)])
      artOn = 1
    end

  end
end


function num2Note(val)
  return dcMidiNotes[val%12+1]..math.floor(val/12)-1
end

function drawViz(bang)
  if selPage== 8 then
    screen.ping()
    xCounter = (xCounter+1*bang*bang)%360
    xAdd = round((math.sin(xCounter*math.pi/180)*50)+54)
    --rotateCounter = rotateCounter+1
    --screen.rotate(math.pi/180)
    
    local lvl, x, y, a, b, type
    local ins = {imDsrOuts[1], imDsrOutsProc[1], imDsrOuts[2],imDsrOutsProc[2], imDsrOuts[3],imDsrOutsProc[3], imMixOut, imMixOutProc, dcOut, dcOutProc, mmOut, mmOutProc, params:get("mmSteps"), params:get("mmOff"), params:get("imSense"), imNoiseVal, mmStepCount, dcRoot, mmStepSize}
    
    lvl = round((ins[math.random(1,#ins)]/127)*15)
    x = xAdd+round((ins[math.random(1,#ins)]/127)*20)
    y = round((ins[math.random(1,#ins)]/127)*48)+10
    a = round((ins[math.random(1,#ins)]/127)*16*bang)
    b = round((ins[math.random(1,#ins)]/127)*16*bang)
    type = math.random(1,3)
    screen.level(lvl)
    screen.move(x,y)
    if type == 1 then
      screen.rect(x,y,a,b)
    elseif type == 2 and bang==1 then
      screen.line(x,y,a,b)
    elseif type == 2 and bang>1 then
      screen.arc(x,y,a,b,lvl)
    elseif type == 3 then
      screen.circle(x,y,a/3)
      screen.fill()
    --else
    --  screen.pixel(x,y)
    --  screen.fill()
    end
    
    if math.random(1,2)>1 then
      screen.stroke()
    else
      screen.fill()
    end
    
    if bang > 1 then
      screen.level(math.random(1,8))
--      screen.move(math.random(1,128),math.random(1,64))
      screen.font_size(math.random(1,4)*bang)
      screen.text_center_rotate(math.random(1,128),math.random(1,64),string.char(math.random(1,127)),math.random(0,360))
      screen.font_size(8)
    end
  end
  
end


function screenClear()  
  screen.clear()
  screen.level(0)
  screen.move(0,0)
  screen.rect(0,0,128,64)
  screen.fill()
end

function noteDrawDsrs(x,y)
  screen.level(1)
  screen.rect(x,y,25,5)
  screen.fill()
  screen.rect(x,y+13,25,17)
  screen.fill()
  
  local val1 = params:get(midiNoteStarts[noteOutSel])
  local val2 = params:get(midiNoteEnds[noteOutSel])
  local sel = 3
  
  if noteSelUI == 1 then
  elseif noteSelUI == 2 then
  else
  end
  
  
  
  for i=1,6 do -- draw DSR in
    screen.level(imDsrIn[i]*2)
    screen.rect(x+21-(i-1)*4,y+1,3,3)
    screen.fill()
  end
  
  for i=1,6 do -- NOTE
    if val1 == i or val2 == i then
      screen.level(15)
      screen.rect(x+21-(i-1)*4,y+1,3,3)
      screen.fill()
    end
  end
  
  -- ------ draw DSR 1-4
  
  for i=1,6 do
    screen.level(imDsrBits[i][1]*2)
    screen.rect(x+21-(i-1)*4,y+14,3,3)
    screen.fill()
  end
  
  for i=1,6 do
    screen.level(imDsrBits[i][2]*2)
    screen.rect(x+21-(i-1)*4,y+18,3,3)
    screen.fill()
  end

  for i=1,6 do
    screen.level(imDsrBits[i][3]*2)
    screen.rect(x+21-(i-1)*4,y+22,3,3)
    screen.fill()
  end

  for i=1,6 do
    screen.level(imDsrBits[i][4]*2)
    screen.rect(x+21-(i-1)*4,y+26,3,3)
    screen.fill()
  end
  
  -- ------- NOTEs
  
  for i=7,12 do
    if val1 == i or val2 == i then
      screen.level(15)
      screen.rect(x+21-(i-7)*4,y+14,3,3)
      screen.fill()
    end
  end
  
  for i=13,18 do
    if val1 == i or val2 == i then
      screen.level(15)
      screen.rect(x+21-(i-13)*4,y+18,3,3)
      screen.fill()
    end
    
  end

  for i=19,24 do
    if val1 == i or val2 == i then
      screen.level(15)
      screen.rect(x+21-(i-19)*4,y+22,3,3)
      screen.fill()
    end
    
  end

  for i=25,30 do
    if val1 == i or val2 == i then
      screen.level(15)
      screen.rect(x+21-(i-25)*4,y+26,3,3)
      screen.fill()
    end
    
  end
  
end



function mmDrawVis(x,y)
  local inTrack = round((mmTracker/128)*40)
  local outTrack = round((mmOut/128)*40)
  local offLev = 55-round((params:get("mmOff")/128)*40)
  local initLev = 55-round((params:get("mmOff")/128)*40)-round((params:get("mmInit")/128)*40)
  local stepLev = 55-round(((params:get("mmStepSize")+params:get("mmAdd")-params:get("mmSub"))/128)*40)-round((params:get("mmOff")/128)*40)-round((params:get("mmInit")/128)*40)

  screen.level(8)
  
  -- input bar
  screen.move(14,55)
  screen.line_rel(0,-1*inTrack)  
  screen.stroke()
  
  -- output bar
  screen.move(18,55)
  screen.line_rel(0,-1*outTrack)  
  screen.stroke()
  
  
  --screen.level(1)
  --screen.move(8,offLev)
  --screen.line_rel(4,0)
  --screen.stroke()

  -- inti indicator
  screen.level(1)
  screen.move(8, initLev)
  screen.line_rel(5,0)
  screen.stroke()

  -- step indicator
  screen.level(1)
  screen.move(18,stepLev)
  screen.line_rel(5,0)
  screen.stroke()
  
  --screen.move(11,stepLev)
  --screen.line(11,initLev)
  --screen.stroke()

  -- difference init to step
  screen.move(21,stepLev)
  screen.line(21,initLev)
  screen.stroke()

  
  -- step indicators
  for i=1,params:get("mmSteps")-1 do
    screen.move(11,util.clamp(initLev-i*round((params:get("mmInit")/128)*40),15,55))
    screen.line_rel(2,0)
    screen.stroke()
  end
  
--  for i=1,mmStepCount do
--    screen.move(23,util.clamp(stepLev-i*round((params:get("mmStepSize")/128)*40),15,55))
--    screen.line_rel(1,0)
--    screen.stroke()
--  end
  
  -- white line at bottom
  screen.level(8)
  screen.move(8,15)
  screen.line_rel(15,0)
  screen.stroke()

  screen.move(8,55)
  screen.line_rel(15,0)
  screen.stroke()
  
  
end




function dcDrawVis(x,y)
  screen.level(1)
  screen.rect(x,y,13,5)
  screen.fill()
  screen.rect(x+15,y,13,5)
  screen.fill()
  
  for i=1,3 do -- draw note DSR in
    screen.level(tonumber(string.sub(dcStringNote,i,i))*8)
    screen.rect(x+16+(i-1)*4,y+1,3,3)
    screen.fill()
  end

  for i=1,3 do -- draw octave DSR in
    screen.level(tonumber(string.sub(dcStringOctave,i,i))*8)
    screen.rect(x+1+(i-1)*4,y+1,3,3)
    screen.fill()
  end  
  
  screen.level(1)  
  screen.move(x+21,y+13)
  screen.text_center(dcNote-1)

  screen.move(x+6,y+13)
  screen.text_center(dcOctave-1)
  
  screen.move(x+7,y+15)
  screen.line_rel(0,11)
  screen.stroke()
  screen.move(x+6,y+25)
  screen.line_rel(-2,-2)
  screen.stroke()
  screen.move(x+7,y+25)
  screen.line_rel(2,-2)
  screen.stroke()
  screen.move(x+6,y+33)
  if dcNote==8 then
    screen.text_center(dcOctave-1)
  else
    screen.text_center(dcOctave-2)
  end

  screen.move(x+22,y+15)
  screen.line_rel(0,11)
  screen.stroke()
  screen.move(x+21,y+25)
  screen.line_rel(-2,-2)
  screen.stroke()
  screen.move(x+22,y+25)
  screen.line_rel(2,-2)
  screen.stroke()
  screen.move(x+21,y+33)
  if params:get("dcMajMin")== 1 then
    screen.text_center(dcNotesMaj[dcNote])
  else
    screen.text_center(dcNotesMin[dcNote])
  end
  --  screen.move(x+20,y+20)
--  screen.text(dcMidiNotes[dcOut%12+1])
  

  
end




function imDrawDsrs(x,y)
  screen.level(1)
  screen.rect(x,y,25,5)
  screen.fill()
  screen.rect(x,y+13,25,17)
  screen.fill()
  
  for i=1,6 do -- draw DSR in
    screen.level(imDsrIn[i]*8)
    screen.rect(x+21-(i-1)*4,y+1,3,3)
    screen.fill()
  end
  
  if imClockTick == 1 then -- draw clock arrow
    
    if imSelUI == 1 then
      screen.level(15)
    else
      screen.level(1)
    end
    screen.move(x+26,y+3)
    screen.line_rel(5,0)
    screen.stroke()
    screen.move(x+28,y+3)
    screen.line_rel(0,-2)
    screen.stroke()
    screen.move(x+28,y+3)
    screen.line_rel(0,1)
    screen.stroke()
  end

  for i=1,6 do -- draw advance arrows
    if imSelUI==2 then
      screen.level(imAdvTicks[i]*15)
    else
      screen.level(imAdvTicks[i])
    end
    screen.move(x+23-(i-1)*4,y+6)
    screen.line_rel(0,6)
    screen.stroke()
    screen.move(x+23-(i-1)*4,y+11)
    screen.line_rel(1,0)
    screen.stroke()
    screen.move(x+23-(i-1)*4,y+11)
    screen.line_rel(-2,0)
    screen.stroke()
    
  end
  
  for i=1,6 do
    screen.level(imDsrBits[i][1]*8)
    screen.rect(x+21-(i-1)*4,y+14,3,3)
    screen.fill()
  end
  
  for i=1,6 do
    screen.level(imDsrBits[i][2]*8)
    screen.rect(x+21-(i-1)*4,y+18,3,3)
    screen.fill()
  end

  for i=1,6 do
    screen.level(imDsrBits[i][3]*8)
    screen.rect(x+21-(i-1)*4,y+22,3,3)
    screen.fill()
  end

  for i=1,6 do
    screen.level(imDsrBits[i][4]*8)
    screen.rect(x+21-(i-1)*4,y+26,3,3)
    screen.fill()
  end
  
end




re = metro.init() -- screen refresh
re.time = 1.0 / 15
re.event = function()
  redraw()
end
re:start()




-- MIDI Stuff

function updateImMidiOutput()
  
  if params:get("imDAC1Ch") > 1 then -- if output on
    if params:get("imDAC1Midi") == 1 then -- MIDI Note
      local i=1
      if allBits[params:get(midiNoteEnds[i])] == 1 and activeNotes[i] >= 0 then
          midi_output:note_off(activeNotes[i], 0, params:get(midiChIds[i])-1)
          activeNotes[i]=-1
      elseif allBits[params:get(midiNoteStarts[i])] == 1 and activeNotes[i] == -1 then
        activeNotes[i] = imDsrOuts[1]
        midi_output:note_on(activeNotes[i], 100, params:get(midiChIds[i])-1)
        if audioOut==1 then
          engine.hz(midi_to_hz(activeNotes[i]))
        end
        drawViz(4)
      end
    else -- MIDI CC
      local outCC = params:get("imDAC1Midi")-1
        midi_output:cc(outCC,imDsrOuts[1],params:get("imDAC1Ch")-1)
    end
  end

  if params:get("imDAC1pCh") > 1 then -- if output on
    if params:get("imDAC1pMidi") == 1 then -- MIDI Note
      local i=2
      if allBits[params:get(midiNoteEnds[i])] == 1 and activeNotes[i] >= 0 then
          midi_output:note_off(activeNotes[i], 0, params:get(midiChIds[i])-1)
          activeNotes[i]=-1
      elseif allBits[params:get(midiNoteStarts[i])] == 1 and activeNotes[i] == -1 then
        activeNotes[i] = imDsrOutsProc[1]
        midi_output:note_on(activeNotes[i], 100, params:get(midiChIds[i])-1)
        if audioOut==1 then
          engine.hz(midi_to_hz(activeNotes[i]))
        end
        drawViz(4)
      end
    else -- MIDI CC
      local outCC = params:get("imDAC1pMidi")-1
        midi_output:cc(outCC,imDsrOutsProc[1],params:get("imDAC1pCh")-1)
    end
  end
  
  
  if params:get("imDAC2Ch") > 1 then -- if output on
    if params:get("imDAC2Midi") == 1 then -- MIDI Note
      local i=3
      if allBits[params:get(midiNoteEnds[i])] == 1 and activeNotes[i] >= 0 then
          midi_output:note_off(activeNotes[i], 0, params:get(midiChIds[i])-1)
          activeNotes[i]=-1
      elseif allBits[params:get(midiNoteStarts[i])] == 1 and activeNotes[i] == -1 then
        activeNotes[i] = imDsrOuts[2]
        midi_output:note_on(activeNotes[i], 100, params:get(midiChIds[i])-1)
        if audioOut==1 then
          engine.hz(midi_to_hz(activeNotes[i]))
        end
        drawViz(4)
      end
    else -- MIDI CC
      local outCC = params:get("imDAC2Midi")-1
        midi_output:cc(outCC,imDsrOuts[2],params:get("imDAC2Ch")-1)
    end
  end
  
  
  if params:get("imDAC2pCh") > 1 then -- if output on
    if params:get("imDAC2pMidi") == 1 then -- MIDI Note
      local i=4
      if allBits[params:get(midiNoteEnds[i])] == 1 and activeNotes[i] >= 0 then
          midi_output:note_off(activeNotes[i], 0, params:get(midiChIds[i])-1)
          activeNotes[i]=-1
      elseif allBits[params:get(midiNoteStarts[i])] == 1 and activeNotes[i] == -1 then
        activeNotes[i] = imDsrOutsProc[2]
        midi_output:note_on(activeNotes[i], 100, params:get(midiChIds[i])-1)
        if audioOut==1 then
          engine.hz(midi_to_hz(activeNotes[i]))
        end
        drawViz(4)
      end
    else -- MIDI CC
      local outCC = params:get("imDAC2pMidi")-1
        midi_output:cc(outCC,imDsrOutsProc[2],params:get("imDAC2pCh")-1)
    end
  end
  
  
  if params:get("imDAC3Ch") > 1 then -- if output on
    if params:get("imDAC3Midi") == 1 then -- MIDI Note
      local i=5
      if allBits[params:get(midiNoteEnds[i])] == 1 and activeNotes[i] >= 0 then
          midi_output:note_off(activeNotes[i], 0, params:get(midiChIds[i])-1)
          activeNotes[i]=-1
      elseif allBits[params:get(midiNoteStarts[i])] == 1 and activeNotes[i] == -1 then
        activeNotes[i] = imDsrOuts[3]
        midi_output:note_on(activeNotes[i], 100, params:get(midiChIds[i])-1)
        if audioOut==1 then
          engine.hz(midi_to_hz(activeNotes[i]))
        end
        drawViz(4)
      end
    else -- MIDI CC
      local outCC = params:get("imDAC3Midi")-1
        midi_output:cc(outCC,imDsrOuts[3],params:get("imDAC3Ch")-1)
    end
  end

  if params:get("imDAC3pCh") > 1 then -- if output on
    if params:get("imDAC3pMidi") == 1 then -- MIDI Note
      local i=6
      if allBits[params:get(midiNoteEnds[i])] == 1 and activeNotes[i] >= 0 then
          midi_output:note_off(activeNotes[i], 0, params:get(midiChIds[i])-1)
          activeNotes[i]=-1
      elseif allBits[params:get(midiNoteStarts[i])] == 1 and activeNotes[i] == -1 then
        activeNotes[i] = imDsrOutsProc[3]
        midi_output:note_on(activeNotes[i], 100, params:get(midiChIds[i])-1)
        if audioOut==1 then
          engine.hz(midi_to_hz(activeNotes[i]))
        end
        drawViz(4)
      end
    else -- MIDI CC
      local outCC = params:get("imDAC3pMidi")-1
        midi_output:cc(outCC,imDsrOutsProc[3],params:get("imDAC3pCh")-1)
    end
  end
  
  
  if params:get("imMixCh") > 1 then -- if output on
    if params:get("imMixMidi") == 1 then -- MIDI Note
      local i=7
      if allBits[params:get(midiNoteEnds[i])] == 1 and activeNotes[i] >= 0 then
          midi_output:note_off(activeNotes[i], 0, params:get(midiChIds[i])-1)
          activeNotes[i]=-1
      elseif allBits[params:get(midiNoteStarts[i])] == 1 and activeNotes[i] == -1 then
        activeNotes[i] = imMixOut
        midi_output:note_on(activeNotes[i], 100, params:get(midiChIds[i])-1)
        if audioOut==1 then
          engine.hz(midi_to_hz(activeNotes[i]))
        end
        drawViz(4)
      end
    else -- MIDI CC
      local outCC = params:get("imMixMidi")-1
        midi_output:cc(outCC,imMixOut,params:get("imMixCh")-1)
    end
  end

  if params:get("imMixpCh") > 1 then -- if output on
    if params:get("imMixpMidi") == 1 then -- MIDI Note
      local i=8
      if allBits[params:get(midiNoteEnds[i])] == 1 and activeNotes[i] >= 0 then
          midi_output:note_off(activeNotes[i], 0, params:get(midiChIds[i])-1)
          activeNotes[i]=-1
      elseif allBits[params:get(midiNoteStarts[i])] == 1 and activeNotes[i] == -1 then
        activeNotes[i] = imMixOutProc
        midi_output:note_on(activeNotes[i], 100, params:get(midiChIds[i])-1)
        if audioOut==1 then
          engine.hz(midi_to_hz(activeNotes[i]))
        end
        drawViz(4)
      end
    else -- MIDI CC
      local outCC = params:get("imMixpMidi")-1
        midi_output:cc(outCC,imMixOutProc,params:get("imMixpCh")-1)
    end
  end
  
  
  

end



function updateDcMidiOutput()
  
  if params:get("dcOutCh") > 1 then -- if output on
    if params:get("dcOutMidi") == 1 then -- MIDI Note
      local i=9
      if allBits[params:get(midiNoteEnds[i])] == 1 and activeNotes[i] >= 0 then
          midi_output:note_off(activeNotes[i], 0, params:get(midiChIds[i])-1)
          activeNotes[i]=-1
      elseif allBits[params:get(midiNoteStarts[i])] == 1 and activeNotes[i] == -1 then
        activeNotes[i] = dcOut
        midi_output:note_on(activeNotes[i], 100, params:get(midiChIds[i])-1)
        if audioOut==1 then
          engine.hz(midi_to_hz(activeNotes[i]))
        end
        drawViz(4)
      end
    else -- MIDI CC
      local outCC = params:get("dcOutMidi")-1
        midi_output:cc(outCC,dcOut,params:get("dcOutCh")-1)
    end
  end

  if params:get("dcOutpCh") > 1 then -- if output on
    if params:get("dcOutpMidi") == 1 then -- MIDI Note
      local i=10
      if allBits[params:get(midiNoteEnds[i])] == 1 and activeNotes[i] >= 0 then
          midi_output:note_off(activeNotes[i], 0, params:get(midiChIds[i])-1)
          activeNotes[i]=-1
      elseif allBits[params:get(midiNoteStarts[i])] == 1 and activeNotes[i] == -1 then
        activeNotes[i] = dcOutProc
        midi_output:note_on(activeNotes[i], 100, params:get(midiChIds[i])-1)
        if audioOut==1 then
          engine.hz(midi_to_hz(activeNotes[i]))
        end
        drawViz(4)
      end
    else -- MIDI CC
      local outCC = params:get("dcOutpMidi")-1
        midi_output:cc(outCC,dcOutProc,params:get("dcOutpCh")-1)
    end
  end

end



function updateMmMidiOutput()  
  if params:get("mmOutCh") > 1 then -- if output on
    if params:get("mmOutMidi") == 1 then -- MIDI Note
      local i=11
      if allBits[params:get(midiNoteEnds[i])] == 1 and activeNotes[i] >= 0 then
          midi_output:note_off(activeNotes[i], 0, params:get(midiChIds[i])-1)
          activeNotes[i]=-1
      elseif allBits[params:get(midiNoteStarts[i])] == 1 and activeNotes[i] == -1 then
        activeNotes[i] = mmOut
        midi_output:note_on(activeNotes[i], 100, params:get(midiChIds[i])-1)
        if audioOut==1 then
          engine.hz(midi_to_hz(activeNotes[i]))
        end
        drawViz(4)
      end
    else -- MIDI CC
      local outCC = params:get("mmOutMidi")-1
        midi_output:cc(outCC,mmOut,params:get("mmOutCh")-1)
    end
  end

  if params:get("mmOutpCh") > 1 then -- if output on
    if params:get("mmOutpMidi") == 1 then -- MIDI Note
      local i=12
      if allBits[params:get(midiNoteEnds[i])] == 1 and activeNotes[i] >= 0 then
          midi_output:note_off(activeNotes[i], 0, params:get(midiChIds[i])-1)
          activeNotes[i]=-1
      elseif allBits[params:get(midiNoteStarts[i])] == 1 and activeNotes[i] == -1 then
        activeNotes[i] = mmOutProc
        midi_output:note_on(activeNotes[i], 100, params:get(midiChIds[i])-1)
        if audioOut==1 then
          engine.hz(midi_to_hz(activeNotes[i]))
        end
        drawViz(4)
      end
    else -- MIDI CC
      local outCC = params:get("mmOutpMidi")-1
        midi_output:cc(outCC,mmOutProc,params:get("mmOutpCh")-1)
    end
  end
  
end





function allNotesOff()
  for h=1,16 do
    for i=0,127 do
      midi_output:note_off(i, 0, h)
    end
  end
  
  for i=1,#activeNotes do
    activeNotes[i]= -1
  end
  
  for i=1,4 do
    crow.output[i].volts = 0
  end
end


function midi2cv(val)
  return (util.clamp(val,0,119)/119)*10.0
end



function set_midi_output(x)
  update_midi()
end

function set_midi_input(x)
  update_midi()
end

local midi_input_event = function(data) 

end

local midi_output_event = function(data) 

end

function update_midi()
  if midi_output and midi_output.event then
    midi_output.event = nil
  end
  midi_output = midi.connect(params:get("midi_output"))
  midi_output.event = midi_output_event
  
  if midi_input and midi_input.event then
    midi_input.event = nil
  end
  midi_input = midi.connect(params:get("midi_input"))
  midi_input.event = midi_input_event
end


function midi_to_hz(note)
  return (440/32) * (2 ^ ((note - 9) / 12))
end

-- round
function round(n)
  return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end
  
function intoBinary(n)
	local binNum = ""
	if n ~= 0 then
		while n >= 1 do
			if n %2 == 0 then
				binNum = binNum.."0"
				n = n / 2
			else
				binNum = binNum.."1"
				n = (n-1)/2
			end
		end
    while #binNum < 6 do
      binNum = binNum.."0"
    end
      
	else
		binNum = "000000"
	end
	return string.reverse(binNum)
end  


function cleanup ()
  if selPage == 8 then
    _norns.screen_export_png(norns.state.data.."modernart.png")
  end
  --params:save("laststate.pset",laststate)
  screenClear()
  allNotesOff()
  print("Ken Stone 4 ever!")
  clock.cancel(clockClk)
  clock.cancel(advanceClk)
  clock.cancel(noiseClk)
  
end