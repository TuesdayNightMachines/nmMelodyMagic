-- nmMelodyMagic
-- 0.5.1 @NightMachines
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
-- Lots of parameters to adjust
-- in the EDIT menus!
-- 
-- K1: -
-- E1: Switch Page
-- K2: Manual Clock Pulse
-- K1 + K2: MIDI Panic
-- E2: Choose Parameter
-- K3: Manual Advance Pulse
-- E3: Change Parameter
-- 


-- _norns.screen_export_png("/home/we/dust/nmMelodyMagic.png")
-- norns.script.load("code/nmMelodyMagic/nmMelodyMagic.lua")


--adjust encoder settigns to your liking
--norns.enc.sens(0,2)
--norns.enc.accel(0,false)

local selPage = 1
local pageLabels = {"Infinite Melody >","< Diatonic Converter >", "< Output Processing >", "< Modulo Magic >", "< Output Processing"}
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
local activeNotes = {0,0,0,0,0,0,0,0,0,0,0,0}
local midiPanic = 0


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
local dcMidiNotes = {"C","C#","D","D#","E","F","F#","G","G#","A","A#","B"}
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



function init()
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

  params:add_separator("nmMelodyMagic") 
  params:add{type = "option", id = "midi_input", name = "Midi Input", options = devices, default = 2, action=set_midi_input}
  params:add{type = "option", id = "midi_output", name = "Midi Output", options = devices, default = 1, action=set_midi_output}
  
  
  midi_output = midi.connect(params:get("midi_output"))
  
  
  
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
  params:add{type = "number", id = "imDsrOutsProcOff1", name = "DAC 1 Offset", min = 0, max = 127, default = 0, wrap = false}
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
  
  params:add_group("MIDI Output Settings",24)
  params:add{type = "option", id = "imDAC1Midi", name = "DAC 1 Out", options = midiOuts, default = 2, wrap = false, action = function(x) allNotesOff() end}
  params:add{type = "option", id = "imDAC1Ch", name = "DAC 1 Channel", options = midiChs, default = 2, wrap = false, action = function(x) allNotesOff() end}
  params:add{type = "option", id = "imDAC1pMidi", name = "DAC 1 Proc. Out", options = midiOuts, default = 2, wrap = false, action = function(x) allNotesOff() end}
  params:add{type = "option", id = "imDAC1pCh", name = "DAC 1 Proc. Channel", options = midiChs, default = 1, wrap = false, action = function(x) allNotesOff() end}
 
  params:add{type = "option", id = "imDAC2Midi", name = "DAC 2 Out", options = midiOuts, default = 2, wrap = false, action = function(x) allNotesOff() end}
  params:add{type = "option", id = "imDAC2Ch", name = "DAC 2 Channel", options = midiChs, default = 1, wrap = false, action = function(x) allNotesOff() end}
  params:add{type = "option", id = "imDAC2pMidi", name = "DAC 2 Proc. Out", options = midiOuts, default = 2, wrap = false, action = function(x) allNotesOff() end}
  params:add{type = "option", id = "imDAC2pCh", name = "DAC 2 Proc. Channel", options = midiChs, default = 1, wrap = false, action = function(x) allNotesOff() end}

  params:add{type = "option", id = "imDAC3Midi", name = "DAC 3 Out", options = midiOuts, default = 2, wrap = false, action = function(x) allNotesOff() end}
  params:add{type = "option", id = "imDAC3Ch", name = "DAC 3 Channel", options = midiChs, default = 1, wrap = false, action = function(x) allNotesOff() end}
  params:add{type = "option", id = "imDAC3pMidi", name = "DAC 3 Proc. Out", options = midiOuts, default = 2, wrap = false, action = function(x) allNotesOff() end}
  params:add{type = "option", id = "imDAC3pCh", name = "DAC 3 Proc. Channel", options = midiChs, default = 1, wrap = false, action = function(x) allNotesOff() end}

  params:add{type = "option", id = "imMixMidi", name = "Mix Out", options = midiOuts, default = 2, wrap = false, action = function(x) allNotesOff() end}
  params:add{type = "option", id = "imMixCh", name = "Mix Channel", options = midiChs, default = 1, wrap = false, action = function(x) allNotesOff() end}
  params:add{type = "option", id = "imMixpMidi", name = "Mix Proc. Out", options = midiOuts, default = 2, wrap = false, action = function(x) allNotesOff() end}
  params:add{type = "option", id = "imMixpCh", name = "Mix Proc. Channel", options = midiChs, default = 1, wrap = false, action = function(x) allNotesOff() end}

  params:add{type = "option", id = "dcOutMidi", name = "Dia Out", options = midiOuts, default = 2, wrap = false, action = function(x) allNotesOff() end}
  params:add{type = "option", id = "dcOutCh", name = "Dia Channel", options = midiChs, default = 1, wrap = false, action = function(x) allNotesOff() end}
  params:add{type = "option", id = "dcOutpMidi", name = "Dia Proc. Out", options = midiOuts, default = 2, wrap = false, action = function(x) allNotesOff() end}
  params:add{type = "option", id = "dcOutpCh", name = "Dia Proc. Channel", options = midiChs, default = 1, wrap = false, action = function(x) allNotesOff() end}
  
  params:add{type = "option", id = "mmOutMidi", name = "Modulo Out", options = midiOuts, default = 2, wrap = false, action = function(x) allNotesOff() end}
  params:add{type = "option", id = "mmOutCh", name = "Modulo Channel", options = midiChs, default = 1, wrap = false, action = function(x) allNotesOff() end}
  params:add{type = "option", id = "mmOutpMidi", name = "Modulo Proc. Out", options = midiOuts, default = 2, wrap = false, action = function(x) allNotesOff() end}
  params:add{type = "option", id = "mmOutpCh", name = "Modulo Proc. Channel", options = midiChs, default = 1, wrap = false, action = function(x) allNotesOff() end}
  
  
  
  
  params:add_separator("Encoder Settings")
  params:add{type = "number", id = "encSens", name = "Encoder Sensitivity", min = 0, max = 16, default = 0, wrap = false, action=function(x) norns.enc.sens(0,x) end} 
  params:add{type = "option", id = "encAccel", name = "Encoder Acceleration", options = onOff, default = 1, wrap = false, action=function(x) if x==0 then norns.enc.accel(0,false) else norns.enc.accel(0,true) end end} 
  
  
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
  redraw()

end





function imClockIn()
  while true do
    if params:get("imClockRate")==0 then
      clock.sync(1/1)
    elseif params:get("imClockRate") < 0 then
      clock.sync(math.abs(params:get("imClockRate")/2))
      imClockTick = 1
      imClockPulse()
      clock.sync(math.abs(params:get("imClockRate")/2))
      imClockTick = 0
    else
      clock.sync((1/params:get("imClockRate"))/2)
      imClockTick = 1
      imClockPulse()
      clock.sync((1/params:get("imClockRate"))/2)
      imClockTick = 0
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
  --print("imDsrIn: "..imDsrIn[6]..imDsrIn[5]..imDsrIn[4]..imDsrIn[3]..imDsrIn[2]..imDsrIn[1])
end




function imAdvanceIn()
  while true do
    if params:get("imAdvanceRate")==0 then
      clock.sync(1/1)
    elseif params:get("imAdvanceRate")<0 then 
      clock.sync(math.abs(params:get("imAdvanceRate")/2))
      imAdvTick = 1
      imAdvancePulse()
      clock.sync(math.abs(params:get("imAdvanceRate")/2))
      imAdvTick = 0
      for i=1,6 do
        imAdvTicks[i]=0
      end
    else
      clock.sync((1/params:get("imAdvanceRate"))/2)
      imAdvTick = 1
      imAdvancePulse()
      clock.sync((1/params:get("imAdvanceRate"))/2)
      imAdvTick = 0
      for i=1,6 do
        imAdvTicks[i]=0
      end
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
  --print("imDsrBits "..dsr..": "..imDsrBits[dsr][4]..imDsrBits[dsr][3]..imDsrBits[dsr][2]..imDsrBits[dsr][1])
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


function updateImOut()

   -- IM DSR DAC outs
  for d=1,3 do
    local dsr = ""
    for i=1,6 do
      dsr=imDsrBits[i][d]..dsr -- reverse array order
    end
    imDsrStrings[d] = dsr
    --print(dsr.." = "..tonumber(dsr,2))
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
  imMixOut = util.clamp(mix,0,127) -- clamp to 0-127
  imMixOutProc = util.clamp(round(imMixOut*params:get("imMixOutProcAtt")+params:get("imMixOutProcOff")),0,127)
  
  updateImMidiOutput()
  
  if params:get("mmIns") < 11 then
    updateMmOut()
  end
  
  if params:get("dcIns") < 5 then
    updateDcOut()
  end
  
end


function updateDcOut()
  -- DC OUT
  
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
  
end









function updateMmOut()
  
  -- MODULO MAGIC OUT
--  local mmTracker = 0

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
  
end


-- BUTTONS
function key(id,st)
  if id==1 then
    if st==1 then
      k1held = 1
    else
      k1held = 0
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
    if st==1 then
      imAdvTick=1
      imAdvancePulse()
    else
      imAdvTick=0
      for i=1,6 do
        imAdvTicks[i]=0
      end
    end
  end
end


-- ENCODERS
function enc(id,delta)
  if id==1 then
    selPage = util.clamp(selPage + delta, 1,5)
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
    
    
    end
  end
end



function redraw()
  screen.clear()
  screen.line_width(1)
  
  screen.level(0)
  screen.move(0,0)
  screen.rect(0,0,128,64)
  screen.fill()
  
  if selPage == 1 then -- infinite melody UI
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
    screen.text("D1: "..imDsrOuts[1])
    screen.move(32,63)
    screen.text("D2: "..imDsrOuts[2])
    screen.move(64,63)
    screen.text("D3: "..imDsrOuts[3])
    screen.move(96,63)
    screen.text("Mix: "..imMixOut)
   
   
   
   
   
   
    
  elseif selPage == 2 then -- diatonic converter UI
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
    screen.text("Out: "..dcOut.." / "..dcMidiNotes[dcOut%12+1]..math.floor(dcOut/12)-1)
  
    
  elseif selPage == 3 then -- output processors 1
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
    screen.text("D1-p: "..imDsrOutsProc[1])
    screen.move(42,56)
    screen.text("D2-p: "..imDsrOutsProc[2])
    screen.move(85,56)
    screen.text("D3-p: "..imDsrOutsProc[3])
    screen.move(0,63)
    screen.text("Mix-p: "..imMixOutProc)
    screen.move(85,63)
    screen.text("Dia-p: "..dcOutProc)

    
    
    
    
    
    
  elseif selPage == 4 then -- modulo magic
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
    screen.text("Out: "..mmOut)
    screen.move(96,63)
    screen.text("Step: "..mmStepCount)
    
    
  elseif selPage == 5 then -- output processors 2
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
    screen.rect(0,50,128,14)
    screen.fill()
    screen.level(4)
    screen.move(0,56)
    screen.text("Mod-p: "..mmOutProc)
  end
  
  if midiPanic == 1 then
    screen.level(10)
    screen.rect(0,0,128,64)
    screen.fill()
    screen.level(0)
    screen.move(64,32)
    screen.text_center("PANIC!")
  end
  
  screen.update()

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
      midi_output:note_off(activeNotes[1], 100, params:get("imDAC1Ch")-1)
      activeNotes[1] = imDsrOuts[1]
      midi_output:note_on(activeNotes[1], 100, params:get("imDAC1Ch")-1)
    else -- MIDI CC
      local outCC = params:get("imDAC1Midi")-1
        midi_output:cc(outCC,imDsrOuts[1],params:get("imDAC1Ch")-1)
    end
  end

  if params:get("imDAC1pCh") > 1 then -- if output on
    if params:get("imDAC1pMidi") == 1 then -- MIDI Note
      midi_output:note_off(activeNotes[2], 100, params:get("imDAC1pCh")-1)
      activeNotes[2] = imDsrOutsProc[1]
      midi_output:note_on(activeNotes[2], 100, params:get("imDAC1pCh")-1)
    else -- MIDI CC
      local outCC = params:get("imDAC1pMidi")-1
        midi_output:cc(outCC,imDsrOutsProc[1],params:get("imDAC1pCh")-1)
    end
  end
  
  
  if params:get("imDAC2Ch") > 1 then -- if output on
    if params:get("imDAC2Midi") == 1 then -- MIDI Note
      midi_output:note_off(activeNotes[3], 100, params:get("imDAC2Ch")-1)
      activeNotes[3] = imDsrOuts[2]
      midi_output:note_on(activeNotes[3], 100, params:get("imDAC2Ch")-1)
    else -- MIDI CC
      local outCC = params:get("imDAC2Midi")-1
        midi_output:cc(outCC,imDsrOuts[2],params:get("imDAC2Ch")-1)
    end
  end
  
  
  if params:get("imDAC2pCh") > 1 then -- if output on
    if params:get("imDAC2pMidi") == 1 then -- MIDI Note
      midi_output:note_off(activeNotes[4], 100, params:get("imDAC2pCh")-1)
      activeNotes[4] = imDsrOutsProc[2]
      midi_output:note_on(activeNotes[4], 100, params:get("imDAC2pCh")-1)
    else -- MIDI CC
      local outCC = params:get("imDAC2pMidi")-1
        midi_output:cc(outCC,imDsrOutsProc[2],params:get("imDAC2pCh")-1)
    end
  end
  
  
  if params:get("imDAC3Ch") > 1 then -- if output on
    if params:get("imDAC3Midi") == 1 then -- MIDI Note
      midi_output:note_off(activeNotes[5], 100, params:get("imDAC3Ch")-1)
      activeNotes[5] = imDsrOuts[3]
      midi_output:note_on(activeNotes[5], 100, params:get("imDAC3Ch")-1)
    else -- MIDI CC
      local outCC = params:get("imDAC3Midi")-1
        midi_output:cc(outCC,imDsrOuts[3],params:get("imDAC3Ch")-1)
    end
  end

  if params:get("imDAC3pCh") > 1 then -- if output on
    if params:get("imDAC3pMidi") == 1 then -- MIDI Note
      midi_output:note_off(activeNotes[6], 100, params:get("imDAC3pCh")-1)
      activeNotes[6] = imDsrOutsProc[3]
      midi_output:note_on(activeNotes[6], 100, params:get("imDAC3pCh")-1)
    else -- MIDI CC
      local outCC = params:get("imDAC3pMidi")-1
        midi_output:cc(outCC,imDsrOutsProc[3],params:get("imDAC3pCh")-1)
    end
  end
  
  
  if params:get("imMixCh") > 1 then -- if output on
    if params:get("imMixMidi") == 1 then -- MIDI Note
      midi_output:note_off(activeNotes[7], 100, params:get("imMixCh")-1)
      activeNotes[7] = imMixOut
      midi_output:note_on(activeNotes[7], 100, params:get("imMixCh")-1)
    else -- MIDI CC
      local outCC = params:get("imMixMidi")-1
        midi_output:cc(outCC,imMixOut,params:get("imMixCh")-1)
    end
  end

  if params:get("imMixpCh") > 1 then -- if output on
    if params:get("imMixpMidi") == 1 then -- MIDI Note
      midi_output:note_off(activeNotes[8], 100, params:get("imMixpCh")-1)
      activeNotes[8] = imMixOutProc
      midi_output:note_on(activeNotes[8], 100, params:get("imMixpCh")-1)
    else -- MIDI CC
      local outCC = params:get("imMixpMidi")-1
        midi_output:cc(outCC,imMixOutProc,params:get("imMixpCh")-1)
    end
  end
  

end


function updateDcMidiOutput()
  if params:get("dcOutCh") > 1 then -- if output on
    if params:get("dcOutMidi") == 1 then -- MIDI Note
      midi_output:note_off(activeNotes[9], 100, params:get("dcOutCh")-1)
      activeNotes[9 ] = dcOut
      midi_output:note_on(activeNotes[9], 100, params:get("dcOutCh")-1)
    else -- MIDI CC
      local outCC = params:get("dcOutMidi")-1
        midi_output:cc(outCC,dcOut,params:get("dcOutCh")-1)
    end
  end

  if params:get("dcOutpCh") > 1 then -- if output on
    if params:get("dcOutpMidi") == 1 then -- MIDI Note
      midi_output:note_off(activeNotes[10], 100, params:get("dcOutpCh")-1)
      activeNotes[10] = dcOutProc
      midi_output:note_on(activeNotes[10], 100, params:get("dcOutpCh")-1)
    else -- MIDI CC
      local outCC = params:get("dcOutpMidi")-1
        midi_output:cc(outCC,dcOutProc,params:get("dcOutpCh")-1)
    end
  end

end



function updateMmMidiOutput()
  if params:get("mmOutCh") > 1 then -- if output on
    if params:get("mmOutMidi") == 1 then -- MIDI Note
      midi_output:note_off(activeNotes[11], 100, params:get("mmOutCh")-1)
      activeNotes[11] = mmOut
      midi_output:note_on(activeNotes[11], 100, params:get("mmOutCh")-1)
    else -- MIDI CC
      local outCC = params:get("mmOutMidi")-1
        midi_output:cc(outCC,mmOut,params:get("mmOutCh")-1)
    end
  end

  if params:get("mmOutpCh") > 1 then -- if output on
    if params:get("mmOutpMidi") == 1 then -- MIDI Note
      midi_output:note_off(activeNotes[12], 100, params:get("mmOutpCh")-1)
      activeNotes[12] = mmOutProc
      midi_output:note_on(activeNotes[12], 100, params:get("mmOutpCh")-1)
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
    activeNotes[i]= 0
  end
end


function set_midi_output(x)
  update_midi()
end

function set_midi_input(x)
  update_midi()
end

local midi_input_event = function(data) 
  --print('input',midi.to_msg(data))
end

local midi_output_event = function(data) 
  print('output',midi.to_msg(data))
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