--============================================================================================================================
--======================================= DETECT_MIDI_CHORDS =================================================================
--============================================================================================================================
-- Notation Events Chords to Regions
-- juliansader https://forum.cockos.com/member.php?u=14710

function CreateTextItem(track, position, length, text, color)

  local item = reaper.AddMediaItemToTrack(track)

  reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)

  if text ~= nil then
    reaper.ULT_SetMediaItemNote(item, text)
  end

  if color ~= nil then
    reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
  end

  return item

end


function getTrackByName(name)
  for trackIndex = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, trackIndex)
    local ok, trackName = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)

    if ok and trackName == name then
      return track -- found it! stopping the search here
    end
  end
end

 ctrack = getTrackByName("chordtrack")
 if ctrack == nil then 
 
-- create chordtrack 
create_track = reaper.NamedCommandLookup("_SWS_CREATETRK1")
reaper.Main_OnCommand(create_track,0)
 ctrack = reaper.GetTrack( 0, 0 )
 reaper.GetSetMediaTrackInfo_String(ctrack, 'P_NAME', 'chordtrack', true)
 reaper.SetMediaTrackInfo_Value( ctrack, "I_WNDH", 50 )
 reaper.SetMediaTrackInfo_Value(ctrack, "I_HEIGHTOVERRIDE", 32)
 reaper.SetMediaTrackInfo_Value(ctrack, "B_HEIGHTLOCK", 1)
 reaper.SetMediaTrackInfo_Value( ctrack, "I_RECARM", 1 )
 reaper.SetMediaTrackInfo_Value( ctrack, "I_RECINPUT", 4096 | 0 | (62 << 5) )
 color = reaper.ColorToNative(95,175,178)
 reaper.SetTrackColor(ctrack, color)

end 
 
reaper.Undo_BeginBlock2(0)
reaper.Main_OnCommand(40644,0)
reaper.Main_OnCommand(42432,0)
--reaper.Main_OnCommand(40421,0) --Item: Select all items in track 40421
sel_item =  reaper.GetSelectedMediaItem( 0, 0 )
--if not sel_item then reaper.MB("Selct Item", "Attention",0) end
if not sel_item then return end
item_length = reaper.GetMediaItemInfo_Value( sel_item, "D_LENGTH" )
item_pos = reaper.GetMediaItemInfo_Value( sel_item, "D_POSITION" )
end_pos = item_pos + item_length
reaper.Main_OnCommand(40153,0) --Item: Open in built-in MIDI editor (set default behavior in preferences) 40153
hwnd = reaper.MIDIEditor_GetActive()
--reaper.MIDIEditor_OnCommand( hwnd, 40954 ) --Mode: Notation3
reaper.MIDIEditor_OnCommand( hwnd, 41281 ) --Notation: Identify chords on editor grid

reaper.SN_FocusMIDIEditor()
reaper.MIDIEditor_OnCommand(40954,0) --Mode: Notation3
reaper.MIDIEditor_OnCommand(41281,0) --Notation: Identify chords on editor grid

  
take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
reaper.MIDI_Sort(take)
MIDIOK, MIDI = reaper.MIDI_GetAllEvts(take, "")
tChords = {}
stringPos, ticks = 1, 0
while stringPos < MIDI:len() do
    offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDI, stringPos)
    ticks = ticks + offset
    if msg:byte(1) == 0xFF then
    chord = msg:match("text (.+)")
    if chord then
    tChords[#tChords+1] = {chord = chord, ticks = ticks}
    end
    end
end
midi_note_end = 0
_, notecnt = reaper.MIDI_CountEvts( take )
for i = 1, notecnt do
  local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, i-1 )

  if endppqpos > midi_note_end then
   midi_note_end = endppqpos
  end
end
midi_note_end_time = reaper.MIDI_GetProjTimeFromPPQPos( take, midi_note_end )


tChords[#tChords+1] = {ticks = ticks}
for i = 1, #tChords do
    tChords[i].time = reaper.MIDI_GetProjTimeFromPPQPos(take, tChords[i].ticks)
end
for i = 1, #tChords-1 do
    -- Set Region Color RGB > reaper.ColorToNative(55,118,235)
  if tChords[i].chord ~= last_chord then
   chord_name = tChords[i].chord
   if chord_name == "C6"  then chord_name = "Am"  end
   if chord_name == "C#6" then chord_name = "A#m" end
   if chord_name == "D6"  then chord_name = "Bm"  end
   if chord_name == "D#6" then chord_name = "Cm"  end
   if chord_name == "E6"  then chord_name = "C#m" end
   if chord_name == "F6"  then chord_name = "Dm"  end
   if chord_name == "F#6" then chord_name = "D#m" end
   if chord_name == "G6"  then chord_name = "Em"  end
   if chord_name == "G#6" then chord_name = "Fm"  end
   if chord_name == "A6"  then chord_name = "F#m" end
   if chord_name == "A#6" then chord_name = "Gm"  end
   if chord_name == "B6"  then chord_name = "G#m" end
   
   time_end = tChords[i+1].time
   
   if tChords[i+1].time > midi_note_end_time then time_end = midi_note_end_time end
   
   CreateTextItem(ctrack,tChords[i].time,time_end - tChords[i].time,chord_name)
   
   last_chord = tChords[i].chord
    end
end     



reaper.Undo_EndBlock2(0, "Chords from midi item", -1)
reaper.MIDIEditor_OnCommand( hwnd, 2 ) --File: Close window

