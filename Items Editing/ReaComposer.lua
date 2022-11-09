-- @ReaComposer - chordtrack for Reaper
-- @version 1.6.0
-- @author Dragonetti
-- @changelog now based on ReaImGui 
-- @link forum https://forum.cockos.com/showthread.php?t=267849
-- @about
--   CHORDTRACK for REAPER
--    [nomain] Functions/*.lua
--local ctx = reaper.ImGui_CreateContext('Anfang', reaper.ImGui_ConfigFlags_DockingEnable())
local script_path = debug.getinfo(1,'S').source:match[[^@?(.*[\/])[^\/]-$]]
-- dofile all files inside functions folder
dofile(script_path .. 'Functions/functions.lua') -- Functions for using the markov in reaper

r=reaper
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end
dinger = 4 
teiler = 1
sub = 1
x=1
s1=s1
function GuiInit()
    ctx = reaper.ImGui_CreateContext('Anfang', reaper.ImGui_ConfigFlags_DockingEnable()) -- Add VERSION TODO
    draw_list = r.ImGui_GetWindowDrawList(ctx)
    FONT = reaper.ImGui_CreateFont('Arial', 14) -- Create the fonts you need
    reaper.ImGui_AttachFont(ctx, FONT)-- Attach the fonts you need
end    

function HSV(h, s, v, a)
    local r, g, b = reaper.ImGui_ColorConvertHSVtoRGB(h, s, v)
    return reaper.ImGui_ColorConvertDouble4ToU32(r, g, b, a or 1.0)
end



function ToolTip(text)
    if reaper.ImGui_IsItemHovered(ctx) then
        reaper.ImGui_BeginTooltip(ctx)
        reaper.ImGui_PushTextWrapPos(ctx, reaper.ImGui_GetFontSize(ctx) * 35.0)
        reaper.ImGui_PushTextWrapPos(ctx, 200)
        reaper.ImGui_Text(ctx, text)
        reaper.ImGui_PopTextWrapPos(ctx)
        reaper.ImGui_EndTooltip(ctx)
    end
end

function read_grid()
_,grid_raw, save_swing, save_swing_amt = reaper.GetSetProjectGrid(0, false)  --- grid setting to 16tel
             
               grid = math.floor(grid_raw*100000)
             
if grid == 100000 then grid_setting = "1" end               
if grid == 50000  then grid_setting = "1/2" end               
if grid == 25000  then grid_setting = "1/4" end
if grid == 12500  then grid_setting = "1/8" end
if grid == 6250   then grid_setting = "1/16" end
if grid == 3125   then grid_setting = "1/32" end
if grid == 66666  then grid_setting = "1T" end
if grid == 33333  then grid_setting = "1/2T" end
if grid == 16666  then grid_setting = "1/4T" end
if grid == 8333   then grid_setting = "1/8T" end
if grid == 4166   then grid_setting = "1/16T" end
if grid == 2083   then grid_setting = "1/32T" end

end

function loop()

if set_dock_id then
    reaper.ImGui_SetNextWindowDockID(ctx, set_dock_id)
    set_dock_id = nil
  end

--  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),   0, 0)
--reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 8, 6)

reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),   8, 2)
--reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_CellPadding(),   10, 5)



  
reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameBorderSize(), 1)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x444141F0)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x556A678A)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(), 0x797979AB)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xD2D2D203)

reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0x312F2FF0)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0x5D5D5D74)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xC8C8C8FF)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextSelectedBg(), 0x646464FF)



    local window_flags = reaper.ImGui_WindowFlags_MenuBar() 
    reaper.ImGui_SetNextWindowSize(ctx, 1280, 120, reaper.ImGui_Cond_Once())-- Set the size of the windows.  Use in the 4th argument reaper.ImGui_Cond_FirstUseEver() to just apply at the first user run, so ImGUI remembers user resize s2
    
    reaper.ImGui_PushFont(ctx, FONT) -- Says you want to start using a specific font
   
    local visible, open  = reaper.ImGui_Begin(ctx, 'Anfang', true)

    if visible then
    
   local dock_id = reaper.ImGui_GetWindowDockID(ctx)
              if reaper.ImGui_BeginPopupContextItem(ctx, 'window_menu') then
                if reaper.ImGui_MenuItem(ctx, 'Dock', nil, dock_id ~= 0) then
                  set_dock_id = dock_id == 0 and -1 or 0
                end
                reaper.ImGui_EndPopup(ctx)
              end     
    
--==========================================================================================================            
--==================================== LINE 1 ==============================================================
--==========================================================================================================    
               
    a=34
    y=32
    b=78
             
               reaper.ImGui_Button(ctx, 'GRID', 100,y) 
               reaper.ImGui_SameLine( ctx,a+86,0 )
            if reaper.ImGui_Button(ctx, 'LENGTH', 100,y) then reset_rate_length() end
               reaper.ImGui_SameLine( ctx ,a+198,0)
            if reaper.ImGui_Button(ctx, 'RATE', 66,y) then rate_reset() end
               reaper.ImGui_SameLine( ctx,a+276,0)
               reaper.ImGui_Button(ctx, 'SOURCE', 66,y)
               reaper.ImGui_SameLine( ctx ,a+354,0)
               reaper.ImGui_Button(ctx, 'CONTENT', 66,y)
               reaper.ImGui_SameLine( ctx ,a+432,0)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xF5FB2780)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),0xC5C93366)
            if reaper.ImGui_Button(ctx, 'SCALE', 144,y) then scale_builder() end
               reaper.ImGui_PopStyleColor(ctx, 2)
               reaper.ImGui_SameLine( ctx ,a+588,0)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xFF000080)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),0x971616AA)
            if reaper.ImGui_Button(ctx, 'PHRASE', 66,y) then phrase_builder() end
               reaper.ImGui_PopStyleColor(ctx, 2)              
               reaper.ImGui_SameLine( ctx ,a+588+b,0)
            if reaper.ImGui_Button(ctx, 'PITCH', 100,y)then reaper.Main_OnCommand(40653,0) end
               reaper.ImGui_SameLine( ctx ,a+700+b,0)
            if reaper.ImGui_Button(ctx, 'SELECT', 100,y) then pattern_select() end
               reaper.ImGui_SameLine( ctx ,a+812+b,0)
            if reaper.ImGui_Button(ctx, 'MUTE', 100,y) then reaper.Main_OnCommand(40175,0) end
               reaper.ImGui_SameLine( ctx ,a+890+34+b,0)
               reaper.ImGui_Button(ctx, 'ORDER', 66,y)
               reaper.ImGui_SameLine( ctx ,a+968+34+b,0)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(),0x34D632AA)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),0x1A6E19AA)
            if reaper.ImGui_Button(ctx, 'MIDI', 66,y) then midi_creator() end
               reaper.ImGui_PopStyleColor(ctx, 2)              
               reaper.ImGui_SameLine( ctx ,a+1046+34+b,0)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0x20CFFFAA)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),0x167B97AA)
            if reaper.ImGui_Button(ctx, 'CHORDTRACK', 134,y) then create_chordtrack() end
               reaper.ImGui_PopStyleColor(ctx, 2)              
               reaper.ImGui_SameLine( ctx ,a+1192+34+b,0)
               reaper.ImGui_Button(ctx, 'OTHER', 68,y)
              
               
--==========================================================================================================            
--==================================== LINE 2 ==============================================================
--==========================================================================================================    
               
           if  reaper.ImGui_Button(ctx, '1/1',32,y) then reaper.Main_OnCommand(40781,0)read_grid()end
               reaper.ImGui_SameLine( ctx,42,0)
            if reaper.ImGui_Button(ctx, '1/2',32,y) then reaper.Main_OnCommand(40780,0)read_grid()end
               reaper.ImGui_SameLine( ctx,76,0)
            if reaper.ImGui_Button(ctx, '1/4',32,y) then reaper.Main_OnCommand(40779,0)read_grid()end
               reaper.ImGui_SameLine( ctx,110,0)
               reaper.ImGui_SameLine( ctx,a+86,0 )
            if reaper.ImGui_Button(ctx, 'tripl',32,y)then length_triplet()end
               reaper.ImGui_SameLine( ctx,a+120,0)
            if reaper.ImGui_Button(ctx, 'x0.5', 32,y) then length_half() end
               reaper.ImGui_SameLine( ctx,a+154,0)
            if reaper.ImGui_Button(ctx, 'x2', 32,y) then length_double() end
               reaper.ImGui_SameLine( ctx,a+198,0)
            if reaper.ImGui_Button(ctx, 'triplet',66,y) then rate_triplet() end
               reaper.ImGui_SameLine( ctx,a+276,0)
            if reaper.ImGui_Button(ctx, 'left',32,y) then startoffs_left() end
               reaper.ImGui_SameLine( ctx,a+310,0)
            if reaper.ImGui_Button(ctx, 'right',32,y) then startoffs_right() end
               reaper.ImGui_SameLine( ctx,a+354,0)
            if reaper.ImGui_Button(ctx, 'prev',32,y) then startoffs_left() end
               reaper.ImGui_SameLine( ctx,a+388,0)
            if reaper.ImGui_Button(ctx, 'next',32,y) then startoffs_right() end 
            
               reaper.ImGui_SameLine( ctx,a+432,0)
            if reaper.ImGui_Button(ctx, '1##a',22,y) then scale_step(1) end                
               reaper.ImGui_SameLine( ctx,a+454,0)
            if reaper.ImGui_Button(ctx, '2##a',20,y) then scale_step(2) end
               reaper.ImGui_SameLine( ctx,a+474,0)
            if reaper.ImGui_Button(ctx, '3##a',20,y) then scale_step(3) end
               reaper.ImGui_SameLine( ctx,a+494,0)
            if reaper.ImGui_Button(ctx, '4##a',20,y) then scale_step(4) end
               reaper.ImGui_SameLine( ctx,a+514,0)
            if reaper.ImGui_Button(ctx, '5##a',20,y) then scale_step(5) end
               reaper.ImGui_SameLine( ctx,a+534,0)
            if reaper.ImGui_Button(ctx, '6##a',20,y) then scale_step(6) end
               reaper.ImGui_SameLine( ctx,a+554,0)
            if reaper.ImGui_Button(ctx, '7##a',22,y) then scale_step(7) end
              
              
               reaper.ImGui_SameLine( ctx,a+588,0)
               reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),   0,9)
            if reaper.ImGui_ArrowButton( ctx, 1, 0 ) then phrase_1_left() end
               reaper.ImGui_SameLine( ctx,a+622,0)
            if reaper.ImGui_ArrowButton( ctx, 2, 1 )then phrase_1_right() end               
                                                                        
                                                                                   
               reaper.ImGui_SameLine( ctx,a+588+b,0)
            if reaper.ImGui_Button(ctx, '+1',32,y) then reaper.Main_OnCommand(40204,0) end
               reaper.ImGui_SameLine( ctx,a+622+b,0)
            if reaper.ImGui_Button(ctx, '+7',32,y) then pitch_plus_7() end
               reaper.ImGui_SameLine( ctx,a+656+b,0)
            if reaper.ImGui_Button(ctx, '+12',32,y) then reaper.Main_OnCommand(40515,0) end
               reaper.ImGui_SameLine( ctx,a+700+b,0)
               reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),   0,9)
            if reaper.ImGui_ArrowButton( ctx, 5, 0 ) then select_prev_item() end
               reaper.ImGui_SameLine( ctx,a+734+b,0)
            if reaper.ImGui_Button(ctx, 'inv.',32,y) then invert_item_selection() end
               reaper.ImGui_SameLine( ctx,a+768+b,0)
            if reaper.ImGui_ArrowButton( ctx, 6, 1 ) then select_next_item() end
               reaper.ImGui_PopStyleVar(ctx)
               reaper.ImGui_SameLine( ctx ,a+812+b,0)
               reaper.ImGui_PushItemWidth( ctx, 100 )
             
               retval, dinger = reaper.ImGui_DragInt( ctx, "##d", dinger, 0.1, 0,128)
               if retval then
               mute_exact(dinger,teiler) end
               reaper.ImGui_SameLine( ctx ,a+890+34+b,0)
            if reaper.ImGui_Button(ctx, 'rate', 32,y) then order_rate() end
               reaper.ImGui_SameLine( ctx ,a+924+34+b,0)
            if reaper.ImGui_Button(ctx, 'pitch', 32,y) then order_pitch() end
               reaper.ImGui_SameLine( ctx ,a+968+34+b,0)
            if reaper.ImGui_Button(ctx, 'SEQ', 66,y) then midi_creator() end
               reaper.ImGui_PushItemWidth( ctx, 134 )
               reaper.ImGui_SameLine( ctx,a+1046+34+b,0)
local chords = {
'  Pachelbel"s Canon  -  C G Am Em F C F G',
'  50s progression  -  C Am F G',
'  Cadence progression  -  Dm G C',
'  Happy progression  -  C C F G',
'  Sad 1 progression  -  Am F C G',
'  Sad 2 progression  -  Am Em G F',
'  Sad 3 progression  -  Cm Gm Bb Fm',
'  Sadder progression  -  Cm Gm Bb F',
'  Uplifting progression  -  Am G F G',
'  Andalusian Cadence progression  -  Cm Bb Ab G',
'  Storyteller progression  -  C F Am G',
'  Bass Player progression  -  C Dm C F',
'  Journey progression  -  F C G G',
'  Secondary Dominants progression  -  F G E Am',
'  Circle progression  -  Am Dm G C',
'  Minor Change progression  -  F Fm C C',
'  La Bamba progression  -  C F G F',
'  Epic progression  -  C Ab G G',
'  Blues 12-bar progression  -  C(4x) F(2x) C(2x) G F C G',
'  Blues 12-bar V2 progression  -  C F C C F F C C G F C G',
'  Pop 1 progression  -  C Am Em D',
'  Pop 2 progression  -  C G Am F',
'  Rock 1 progression  -  C F C G+',
'  Rock 2 progression  -  Cm Ab Fm Fm',
'  Rock 3 progression  -  F G Am C',
'  Rock 4 progression  -  C C Bb F',
'  Rock 5 progression  -  C G Dm F',
'  Jazz 1  -  ii V I',
'  Jazz 2  -  ii V i',
'  Jazz 3  -  I vi ii V',
'  Jazz 4  -  i vi ii V',
'  Jazz 5  -  iii vi ii V',
'  Jazz 6  -  I #idim ii V',
'  Jazz 7  -  I IV iii VI',
'  Jazz 8  -  #ii #V ii V I',
'  Jazz 9  -  ii Tri Sub of V I',
'  Trap progression  -  Cm Ab Cm Gm',
'  Würm progression  -  G Eb C C'}


if reaper.ImGui_BeginCombo(ctx, '##chord progression', "       chord progression",  reaper.ImGui_ComboFlags_NoArrowButton()) then
  for i, chord in ipairs(chords) do
    i = i - 1
    if reaper.ImGui_Selectable(ctx, chord, ca == i) then
      chord_progression(i)
    end
  end
  reaper.ImGui_EndCombo(ctx)
end


         --    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),   9,9)
           --  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),   4,4)
           --  local changed, chord_prog =reaper.ImGui_Combo(ctx, '  ', ca, chords, 38)
           --  if changed then
          --   ca =  tonumber(chord_prog) 
          --   chord_progression(ca) chord_prog = a-1
          --   end
           --    reaper.ImGui_PopStyleVar(ctx,2)
               reaper.ImGui_SameLine( ctx ,a+1192+34+b,0)
            if reaper.ImGui_Button(ctx, 'XML', 68,y) then import_xml() end
         
      
--==========================================================================================================            
--==================================== LINE 3 ==============================================================
--==========================================================================================================          
              
            if reaper.ImGui_Button(ctx, '1/8',32,y)  then reaper.Main_OnCommand(40778,0)read_grid()end
               reaper.ImGui_SameLine( ctx,42,0)
            if reaper.ImGui_Button(ctx, '1/16',32,y) then reaper.Main_OnCommand(40776,0)read_grid()end 
               reaper.ImGui_SameLine( ctx,76,0)
            if reaper.ImGui_Button(ctx, '1/32',32,y) then reaper.Main_OnCommand(40775,0)read_grid()end
               reaper.ImGui_SameLine( ctx,a+120,0)
               reaper.ImGui_SameLine( ctx,a+86,0)
            if reaper.ImGui_Button(ctx, 'split at grid', 32,32)then reaper.Main_OnCommand(40932,0)end
               reaper.ImGui_SameLine( ctx,a+120,0)
            if reaper.ImGui_Button(ctx, 'SEQ##2', 32,32)then length_input() end
               reaper.ImGui_SameLine( ctx)
               reaper.ImGui_SameLine( ctx,a+154,0 )
            if reaper.ImGui_Button(ctx, 'grid', 32,y) then  length_to_grid() end
               reaper.ImGui_SameLine( ctx,a+198,0)
               reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),   0,9)
            if reaper.ImGui_ArrowButton( ctx, 7, 0 ) then rate_half() end
               reaper.ImGui_SameLine( ctx,a+232,0)
            if reaper.ImGui_ArrowButton( ctx, 8, 1 ) then rate_double() end
               reaper.ImGui_SameLine( ctx,a+276,0)
            if reaper.ImGui_Button(ctx, 'rand src', 66,y) then random_startoffs() end
               reaper.ImGui_SameLine( ctx,a+354,0)
            if reaper.ImGui_Button(ctx, 'rand', 66,y) then shuffle_startoffs() end             
               reaper.ImGui_SameLine( ctx,a+432,0)
            if reaper.ImGui_Button(ctx, '-1##a',22,y) then scale_step(-1) end                
               reaper.ImGui_SameLine( ctx,a+454,0)
            if reaper.ImGui_Button(ctx, '-2##a',20,y) then scale_step(-2) end
               reaper.ImGui_SameLine( ctx,a+474,0)
            if reaper.ImGui_Button(ctx, '-3##a',20,y) then scale_step(-3) end
               reaper.ImGui_SameLine( ctx,a+494,0)
            if reaper.ImGui_Button(ctx, '-4##a',20,y) then scale_step(-4) end
               reaper.ImGui_SameLine( ctx,a+514,0)
            if reaper.ImGui_Button(ctx, '-5##a',20,y) then scale_step(-5) end
               reaper.ImGui_SameLine( ctx,a+534,0)
            if reaper.ImGui_Button(ctx, '-6##a',20,y) then scale_step(-6) end
               reaper.ImGui_SameLine( ctx,a+554,0)
            if reaper.ImGui_Button(ctx, '-7##a',22,y) then scale_step(-7) end
              
     
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xE67A00B9)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x894A02B9)
               reaper.ImGui_SameLine( ctx,a+588,0)
            if reaper.ImGui_Button(ctx, 'CHORD', 66,y) then chord_builder() end
               reaper.ImGui_PopStyleColor(ctx, 2)
               reaper.ImGui_SameLine( ctx,a+588+b,0)
            if reaper.ImGui_Button(ctx, '-1',32,y) then reaper.Main_OnCommand(40205,0) end
               reaper.ImGui_SameLine( ctx,a+622+b,0)
            if reaper.ImGui_Button(ctx, '-7',32,y) then pitch_minus_7() end
               reaper.ImGui_SameLine( ctx,a+656+b,0)
            if reaper.ImGui_Button(ctx, '-12',32,y) then reaper.Main_OnCommand(40516,0) end
               reaper.ImGui_SameLine( ctx,a+700+b,0)
            if reaper.ImGui_Button(ctx, 'chord',32,y) then select_chord() end 
               reaper.ImGui_SameLine( ctx,a+734+b,0)
            if reaper.ImGui_Button(ctx, 'root',32,y) then select_root_note() end
               reaper.ImGui_SameLine( ctx,a+768+b,0)
            if reaper.ImGui_Button(ctx, 'grid##1',32,y) then select_only_on_grid() end
               reaper.ImGui_SameLine( ctx ,a+812+b,0)
               reaper.ImGui_PushItemWidth( ctx, 49 )
               ret, teiler = reaper.ImGui_DragInt( ctx, "##1", teiler, 0.1, 1,24)
                if ret then 
               mute_exact(teiler,dinger) end
                                   
               reaper.ImGui_SameLine( ctx ,a+863+b,0)
               reaper.ImGui_PushItemWidth( ctx, 49 )
                                                                 
               ret, sub = reaper.ImGui_DragInt( ctx, "##2", sub, 0.1, 1,16)
                if ret then 
               mute_exact(sub) end               
               reaper.ImGui_SameLine( ctx ,a+890+34+b,0)
            if reaper.ImGui_Button(ctx, 'reverse', 66,y) then reverse = reaper.NamedCommandLookup("_XENAKIOS_REVORDSELITEMS")
                       reaper.Main_OnCommand(reverse,0) end
               reaper.ImGui_SameLine( ctx ,a+968+34+b,0)
            if reaper.ImGui_Button(ctx, 'pattern', 66,y) then midi_rand() end
               reaper.ImGui_SameLine( ctx ,a+1046+34+b,0)
            if reaper.ImGui_ArrowButton( ctx, 13, 2 ) then chordsymbol_trans_up() end
            reaper.ImGui_PopStyleVar(ctx)
               reaper.ImGui_SameLine( ctx ,a+1080+34+b,0)
            if reaper.ImGui_Button(ctx, 'x',32,y) then chordsymbol_right() end
            mods = {"  sudden dominant (2items)", "  minor subdominant (2items)", "  subdominant (1items)", "  parallel key (1item)"}
               reaper.ImGui_SameLine( ctx ,a+1114+34+b,0)
               reaper.ImGui_PushItemWidth( ctx, 66 )
               if reaper.ImGui_BeginCombo(ctx, '##modulationen', " modulation",reaper.ImGui_ComboFlags_NoArrowButton()) then
                 for m, mods in ipairs(mods) do
                   m = m - 1
                   if reaper.ImGui_Selectable(ctx, mods, ma == i) then
                   if m==0 then sudden_dominant()end
                   if m==1 then minor_subdominant()end
                   if m==2 then create_subdominant()end
                   if m==3 then create_parallel()end   
                 
               end
               end
              reaper.ImGui_EndCombo(ctx)
              
              end
              
                             
               reaper.ImGui_SameLine( ctx ,a+1192+34+b,0)
            if reaper.ImGui_Button(ctx, 'Color', 68,y) then reaper.Main_OnCommand(40357,0) reaper.Main_OnCommand(40707,0) end
            
            
--==========================================================================================================            
--==================================== LINE 4 ==============================================================
--==========================================================================================================  

               toggle_triplet = reaper.NamedCommandLookup("_SWS_AWTOGGLETRIPLET")
            if reaper.ImGui_Button(ctx, 'T',32,y) then reaper.Main_OnCommand(toggle_triplet,0)read_grid() end
               reaper.ImGui_SameLine( ctx,42,0)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0x00D8C6B9)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x006159B9)
               read_grid() 
               reaper.ImGui_Button(ctx, grid_setting,66,y) 
               reaper.ImGui_PopStyleColor(ctx,2)
               reaper.ImGui_SameLine( ctx,76,0)
               reaper.ImGui_NewLine(ctx )
               
               reaper.ImGui_SameLine( ctx,a+86,0)
                
             if  reaper.ImGui_Button(ctx, '-##1', 32,y) then x=1 s1=s2 length_sinus(x,s1)end
              
               reaper.ImGui_SameLine( ctx,a+120,0)   
                  reaper.ImGui_PushItemWidth( ctx, 32 )
                sinus={"  f(x)=0.01x  ","  sinus1  ","  sinus2  ","  sinus3  ","  sinus4  ","  sinus5  "}  
                if reaper.ImGui_BeginCombo(ctx, '##modulatio', "  f (x)",reaper.ImGui_ComboFlags_NoArrowButton()) then
                        for s1, sinus in ipairs(sinus) do
                                  s1 = s1 - 1
                         if reaper.ImGui_Selectable(ctx, sinus, sa == s1) then
                                length_sinus(x,s1) 
                                      end
                                       end
                                      
                        reaper.ImGui_EndCombo(ctx)
               end
              reaper.ImGui_SameLine( ctx,a+154,0) 
              if  reaper.ImGui_Button(ctx, '+##2', 32,y) then x=-1 s1=s2 length_sinus(x,s1)end
             
                           
              
               reaper.ImGui_SameLine( ctx,a+198,0)
            if reaper.ImGui_Button(ctx, 'random', 66,y) then rate_random() end
               reaper.ImGui_SameLine( ctx,a+276,0)
               reaper.ImGui_Button(ctx, 'rand src', 66,y)
               
               reaper.ImGui_SameLine( ctx,a+588,0)
               
            if reaper.ImGui_ArrowButton( ctx, 11, 3 ) then chord_inversion_down() end
               reaper.ImGui_SameLine( ctx,a+622,0)
            if reaper.ImGui_ArrowButton( ctx, 12, 2 )   then chord_inversion_up() end
               
               reaper.ImGui_SameLine( ctx,a+276,0)
               reaper.ImGui_PopStyleColor(ctx,1)
               reaper.ImGui_SameLine( ctx,a+588+b,0)
            if reaper.ImGui_Button(ctx, 'ran',32,y) then pitch_rand() end 
               reaper.ImGui_SameLine( ctx,a+622+b,0)
            if reaper.ImGui_Button(ctx, 'inv.',32,y) then pitch_invers_x() end
               reaper.ImGui_SameLine( ctx,a+656+b,0)
            if reaper.ImGui_Button(ctx, 'com.',32,y) then pitch_comp() end
           --    reaper.ImGui_SameLine( ctx,a+700+b,0)
            --   reaper.ImGui_PushItemWidth( ctx, 34 )
            --     local old_val1 = val1
            --   ret, val1 = reaper.ImGui_DragInt( ctx, "##1112", val1, 1,1,16)
            --         if ret then
           --          length_half_1(val1 - old_val1)
                    
                 --       end
          --  if reaper.ImGui_Button(ctx, 'unmuted',66,y) then select_unmuted() end 
               
               reaper.ImGui_SameLine( ctx,a+812+b,0)
               if reaper.ImGui_Button(ctx, 'random##1', 49, y) then
                  ran = false
                 mute_exact(teiler,dinger,ran)
               end
               reaper.ImGui_SameLine( ctx,a+863+b,0)
                              if reaper.ImGui_Button(ctx, 'normal##1', 49, y) then
                                ran = true
                                mute_exact(teiler,dinger,ran)
                              end
               reaper.ImGui_SameLine( ctx ,a+890+34+b,0)
            if reaper.ImGui_Button(ctx, 'rand or', 66,y) then shuffle_order() end
               reaper.ImGui_SameLine( ctx ,a+1046+34+b,0)
               
            if reaper.ImGui_ArrowButton( ctx, 14, 3 ) then chordsymbol_trans_down() end
            reaper.ImGui_PopStyleVar(ctx)
               reaper.ImGui_SameLine( ctx ,a+1114+34+b,0)
            if reaper.ImGui_Button(ctx, 'detection',66,y) then detect_midi_chords() end
          
        reaper.ImGui_PopStyleVar(ctx,2)
        reaper.ImGui_PopStyleColor(ctx, 7)
        reaper.ImGui_End(ctx)
    end 

    
    reaper.ImGui_PopFont(ctx) -- Pop Font

    if open then
        reaper.defer(loop)
    else
        reaper.ImGui_DestroyContext(ctx)
    end
end
                
GuiInit()
loop()

                      
                       
