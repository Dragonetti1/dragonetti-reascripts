-- @version 1.7.4
-- @author Dragonetti
-- @provides 
--    functions.lua
--    Fonts/*.ttf
-- @changelog
--    + more tooltips
--    + fix length function



------------------------------
info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]] -- this script folder

------------------------------

dofile(script_path .. 'functions.lua') -- functions needed


r=reaper
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end
dinger = 4 
teiler = 1
sub = 1
x=1
s1=s1
tt=true

function GuiInit()
    
    ctx = reaper.ImGui_CreateContext('ReaComposer', reaper.ImGui_ConfigFlags_DockingEnable()) -- Add VERSION TODO
    draw_list = r.ImGui_GetWindowDrawList(ctx)
    FONT = reaper.ImGui_CreateFont('Arial', 14) -- Create the fonts you need
    reaper.ImGui_Attach(ctx, FONT)-- Attach the fonts you need
    SymbolFont = reaper.ImGui_CreateFont(script_path..'Fonts/Symbols.ttf', 14)
        reaper.ImGui_Attach(ctx, SymbolFont)
end    

function HSV(h, s, v, a)
    local r, g, b = reaper.ImGui_ColorConvertHSVtoRGB(h, s, v)
    return reaper.ImGui_ColorConvertDouble4ToU32(r, g, b, a or 1.0)
end



function ToolTip(is_tooltip, text)
    if is_tooltip and reaper.ImGui_IsItemHovered(ctx) then
        reaper.ImGui_PushFont(ctx, FONT)
        reaper.ImGui_BeginTooltip(ctx)
       -- reaper.ImGui_PushTextWrapPos(ctx, reaper.ImGui_GetFontSize(ctx) * 40)
        reaper.ImGui_PushTextWrapPos(ctx, 200)
        reaper.ImGui_Text(ctx, text)
        reaper.ImGui_PopTextWrapPos(ctx)
        reaper.ImGui_EndTooltip(ctx)
        reaper.ImGui_PopFont(ctx)
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


b=2
ICount=2
am=0

function loop()

reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),   0, 0)
reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 8, 6)
reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),8,2)
reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_CellPadding(),   10, 5)
reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameBorderSize(), 1)

reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x444141F0)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x444141F0)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(), 0x0797979AB)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), 0x797979AB)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(), 0x797979AB)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x797979AB)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x6A6A6AFF)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0x444141c6)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0x5D5D5D74)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0xC8C8C8FF)
reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TextSelectedBg(), 0x646464FF)  


if set_dock_id then
    reaper.ImGui_SetNextWindowDockID(ctx, set_dock_id)
    set_dock_id = nil
  end


    local window_flags = reaper.ImGui_WindowFlags_MenuBar() 
    reaper.ImGui_SetNextWindowSize(ctx, 1440, 180, reaper.ImGui_Cond_Once())-- Set the size of the windows.  Use in the 4th argument reaper.ImGui_Cond_FirstUseEver() to just apply at the first user run, so ImGUI remembers user resize s2

reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 2, 1)




    
    reaper.ImGui_PushFont(ctx, FONT) -- Says you want to start using a specific font
   
    local visible, open  = reaper.ImGui_Begin(ctx, 'ReaComposer', true)

    if visible then
    
   local dock_id = reaper.ImGui_GetWindowDockID(ctx)
              if reaper.ImGui_BeginPopupContextItem(ctx, 'window_menu') then
                if reaper.ImGui_MenuItem(ctx, 'Dock', nil, dock_id ~= 0) then
                  set_dock_id = dock_id == 0 and -1 or 0
                end
                reaper.ImGui_EndPopup(ctx)
              end  
              
           
   
   
local y=32
   
    
local btn_w = 32
local spacing_x = reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing())

--========================= GRID ============================================================================  

               reaper.ImGui_BeginGroup(ctx) 
               reaper.ImGui_Button(ctx, 'GRID', (btn_w*3)+(spacing_x*2),y) 
            if reaper.ImGui_Button(ctx, '1/1',(btn_w),y) then reaper.Main_OnCommand(40781,0) read_grid()end
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, '1/2',(btn_w),y) then reaper.Main_OnCommand(40780,0)read_grid()end
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, '1/4',(btn_w),y) then reaper.Main_OnCommand(40779,0)read_grid()end
            if reaper.ImGui_Button(ctx, '1/8',(btn_w),y)  then reaper.Main_OnCommand(40778,0)read_grid()end
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, '1/16',(btn_w),y) then reaper.Main_OnCommand(40776,0)read_grid()end 
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, '1/32',(btn_w),y) then reaper.Main_OnCommand(40775,0)read_grid()end
              
               toggle_triplet = reaper.NamedCommandLookup("_SWS_AWTOGGLETRIPLET")
            if reaper.ImGui_Button(ctx, 'T',(btn_w),y) then reaper.Main_OnCommand(toggle_triplet,0)read_grid() end
               reaper.ImGui_SameLine( ctx)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0x00D8C6B9)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x006159B9)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),0x00D8C6B9)
               read_grid() 
               reaper.ImGui_Button(ctx, grid_setting,(btn_w*2)+(spacing_x*1),y) 
               reaper.ImGui_PopStyleColor(ctx,3)               
               reaper.ImGui_EndGroup(ctx)
               
--========================= LENGTH ============================================================================

               reaper.ImGui_SameLine(ctx, nil, 10)
               reaper.ImGui_BeginGroup(ctx)
            if reaper.ImGui_Button(ctx, 'LENGTH', (btn_w*3)+(spacing_x*2),y) then reset_rate_length() end
               ToolTip(tt, "reset item length")
            if reaper.ImGui_Button(ctx, 'tripl',32,y)then length_triplet()end
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, 'x0.5', 32,y) then length_half() end
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, 'x2', 32,y) then length_double() end
               
            if reaper.ImGui_Button(ctx, 'a##b1', 15,y) then  b = math.floor(ICount/2) crazy_length(b,am) end
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, 'b##b2', 15,y) then  b = math.floor(ICount/4) crazy_length(b,am) end
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, 'split at grid', 32,32)then reaper.Main_OnCommand(40932,0)end
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, 'SEQ##2', 32,32)then length_input() end
            ToolTip (tt, "changes the item length. \n1 for one grid\n2 for two grids \netc \nfactor 3 for triplet \nfactor 5 for quintole \netc." )
              
       
         -- if xpi == nil then xpi = 2 end
          if ICount== nil then ICount = 2 end
                     
               reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),   0,9)
               reaper.ImGui_NewLine(ctx)
               reaper.ImGui_SameLine( ctx ,0,0)
               reaper.ImGui_PushItemWidth( ctx, 32 )
                         local   old_b = b
                        ret, b = reaper.ImGui_DragInt( ctx, "##Drag",b, 0.1, 1,(ICount))
                          if ret then
                          
                            crazy_length(b,am)
                         end
                       
               reaper.ImGui_SameLine( ctx ,0,2)
                                           
                         ret, xpi = reaper.ImGui_DragInt( ctx, "##xpi",xpi, 0.1, 1,32)
                           if ret then
                                             
                        --      crazy_length(_,_,xpi)
                                     end 
                              reaper.ImGui_SameLine( ctx ,0,2)
                              local   old_am = am
                  ret, am = reaper.ImGui_DragInt( ctx, "##am",0, 1, -4,4)
                      if ret then
                     am = am - old_am
                        crazy_length(b,am)
                                                                                        end 
               reaper.ImGui_EndGroup(ctx)
            --  reaper.ImGui_PopStyleVar(ctx)
--========================= RATE ============================================================================    

               reaper.ImGui_SameLine(ctx, nil, 10)
               reaper.ImGui_BeginGroup(ctx)
              
            if reaper.ImGui_Button(ctx, 'RATE', (btn_w*2)+(spacing_x*1),y) then rate_reset() end
               ToolTip(tt, "reset item rate")
            if reaper.ImGui_Button(ctx, 'triplet',(btn_w*2)+(spacing_x*1),y) then rate_triplet() end
            if reaper.ImGui_Button( ctx, "0.5x##5", 32,y ) then rate_half() end
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button( ctx, "2x##5", 32,y ) then rate_double() end
            if reaper.ImGui_Button(ctx, 'random', (btn_w*2)+(spacing_x*1),y) then rate_random() end
               reaper.ImGui_EndGroup(ctx)
               
               
            
--========================= SOURCE ============================================================================  

               reaper.ImGui_SameLine(ctx, nil, 10)
               reaper.ImGui_BeginGroup(ctx)
               reaper.ImGui_Button(ctx, 'SOURCE', (btn_w*2)+(spacing_x*1),y)
               reaper.ImGui_PushFont(ctx, SymbolFont)
            if reaper.ImGui_Button(ctx, 'A##1',32,y) then prev_source = reaper.NamedCommandLookup("_XENAKIOS_SISFTPREVIF") reaper.Main_OnCommand(prev_source,0) end
               ToolTip(tt, "only audio!! \nSwitch item source file to previous in folder")
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, 'B##1',32,y) then next_source = reaper.NamedCommandLookup("_XENAKIOS_SISFTNEXTIF") reaper.Main_OnCommand(next_source,0) end
              reaper.ImGui_PopFont(ctx)
               ToolTip(tt, "only audio!! \nSwitch item source file to next in folder")
            
            if reaper.ImGui_Button(ctx, 'rand src', (btn_w*2)+(spacing_x*1),y) then random_source_x() end
               ToolTip(tt, "only audio!! \nswitch item source file to random in folder \nlength remain")  
            if reaper.ImGui_Button(ctx, 'rand src', (btn_w*2)+(spacing_x*1),y) then random_source_length_x() end
               ToolTip(tt, "only audio!! \nswitch item source file to random in folder \nold source length")  
               reaper.ImGui_EndGroup(ctx)
               
--========================= CONTENT ============================================================================                 
               
               
               reaper.ImGui_SameLine(ctx, nil, 10)
               reaper.ImGui_BeginGroup(ctx)
               reaper.ImGui_Button(ctx, 'CONTENT', (btn_w*2)+(spacing_x*1),y)
               ToolTip(tt, 'reset content to start 0')
               reaper.ImGui_PushFont(ctx, SymbolFont)
            if reaper.ImGui_Button(ctx, 'A##2',32,y) then startoffs_left() end
               ToolTip(tt, "useful for longer midi or audio phrases \ncontent one grid left")
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, 'B##2',32,y) then startoffs_right() end 
               reaper.ImGui_PopFont(ctx)
               ToolTip(tt, "useful for longer midi or audio phrases \ncontent one grid right")
            if reaper.ImGui_Button(ctx, 'rand', (btn_w*2)+(spacing_x*1),y) then shuffle_startoffs() end
               ToolTip(tt, "useful for longer midi or audio phrases \ncontent start random depending on grid")               
               reaper.ImGui_EndGroup(ctx)
               
--========================= SCALE ============================================================================                           
               
               
               reaper.ImGui_SameLine(ctx, nil, 10)
               reaper.ImGui_BeginGroup(ctx)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xF5FB2780)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),0xC5C93366)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xF5FB2780)
            if reaper.ImGui_Button(ctx, 'SCALE', (btn_w*3.5)+(spacing_x*6),y) then scale_builder() end
               ToolTip(tt, "ARPEGGIATOR \nq,w,e,r... = scale tones      \n1,2,3,4... =scale tones +1 \na,s,d...     =scale tones -12 \n1,0 accent")
               reaper.ImGui_PopStyleColor(ctx, 3)
               
               if reaper.ImGui_Button(ctx, '1##a',btn_w*0.5,y) then scale_step(1) end
                  ToolTip(tt, "Transposed within the scale depending on the chord symbol of the chord track.\nalso works with chords \nfor example:\nCmaj7 becomes Dm7")
                  reaper.ImGui_SameLine( ctx)
               if reaper.ImGui_Button(ctx, '2##a',btn_w*0.5,y) then scale_step(2) end
                  ToolTip(tt, "Transposed within the scale depending on the chord symbol of the chord track.\nalso works with chords \nfor example:\nCmaj7 becomes Em7")
               reaper.ImGui_SameLine( ctx)
               if reaper.ImGui_Button(ctx, '3##a',btn_w*0.5,y) then scale_step(3) end
               ToolTip(tt, "Transposed within the scale depending on the chord symbol of the chord track\nalso works with chords \nfor example:\nCmaj7 becomes Fmaj7")
                reaper.ImGui_SameLine( ctx)
               if reaper.ImGui_Button(ctx, '4##a',btn_w*0.5,y) then scale_step(4) end
                 reaper.ImGui_SameLine( ctx)
               if reaper.ImGui_Button(ctx, '5##a',btn_w*0.5,y) then scale_step(5) end
                 reaper.ImGui_SameLine( ctx)
               if reaper.ImGui_Button(ctx, '6##a',btn_w*0.5,y) then scale_step(6) end
                 reaper.ImGui_SameLine( ctx)
               if reaper.ImGui_Button(ctx, '7##a',btn_w*0.5,y) then scale_step(7) end
               if reaper.ImGui_Button(ctx, '-1##a',btn_w*0.5,y) then scale_step(-1) end                
                  reaper.ImGui_SameLine( ctx)
               if reaper.ImGui_Button(ctx, '-2##a',btn_w*0.5,y) then scale_step(-2) end
               reaper.ImGui_SameLine( ctx)
               if reaper.ImGui_Button(ctx, '-3##a',btn_w*0.5,y) then scale_step(-3) end
                reaper.ImGui_SameLine( ctx)
               if reaper.ImGui_Button(ctx, '-4##a',btn_w*0.5,y) then scale_step(-4) end
                 reaper.ImGui_SameLine( ctx)
               if reaper.ImGui_Button(ctx, '-5##a',btn_w*0.5,y) then scale_step(-5) end
                 reaper.ImGui_SameLine( ctx)
               if reaper.ImGui_Button(ctx, '-6##a',btn_w*0.5,y) then scale_step(-6) end
                 reaper.ImGui_SameLine( ctx)
               if reaper.ImGui_Button(ctx, '-7##a',btn_w*0.5,y) then scale_step(-7) end               
               
               
               reaper.ImGui_EndGroup(ctx)
               
--========================= PHRASE CHORD  ============================================================================    

               reaper.ImGui_SameLine(ctx, nil, 10)
               reaper.ImGui_BeginGroup(ctx)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xFF000080)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),0x971616AA)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xFF000080)
            if reaper.ImGui_Button(ctx, 'PHRASE', (btn_w*2)+(spacing_x*1),y) then phrase_builder() end
               ToolTip(tt, 'A phrase in "C" major scale (white keys) is required.The transposition depends on the chord.\nExample: \n"Cmaj7" transpose 0\n"Dmaj7" transpose +2\n"Cm"      transpose +3\n"Dm7"(dorian) transpose 0 ')
               reaper.ImGui_PopStyleColor(ctx, 3)
               reaper.ImGui_PushFont(ctx, SymbolFont)
               if reaper.ImGui_Button( ctx,"A##3", 32, y ) then phrase_1_left() end
               reaper.ImGui_PopFont( ctx )
               ToolTip(tt, "transpose phrase one fifth to left")
               reaper.ImGui_SameLine( ctx)
               reaper.ImGui_PushFont(ctx, SymbolFont)
            if reaper.ImGui_Button( ctx,"B##3", 32, y )then phrase_1_right() end 
               reaper.ImGui_PopFont( ctx )
               ToolTip(tt, "transpose phrase one fifth to right")
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xE67A00B9)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x894A02B9)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),0xE67A00B9)
            if reaper.ImGui_Button(ctx, 'CHORD', (btn_w*2)+(spacing_x*1),y) then chord_builder() end
               ToolTip(tt, "Transposes items(midi:note c, audio:metadata key) that lie on top of each other.\nExample : 3 items - triad root position")
               reaper.ImGui_PopStyleColor(ctx, 3)
               reaper.ImGui_PushFont(ctx, SymbolFont)
            if reaper.ImGui_Button( ctx,"D##1", 32, y ) then chord_inversion_down() end
               ToolTip(tt, "chord_inversion_down")
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button( ctx,"C##1", 32, y)   then chord_inversion_up() end
               ToolTip(tt, "chord_inversion_up")
               reaper.ImGui_PopFont( ctx )
               reaper.ImGui_EndGroup(ctx)
                
               
--========================= PITCH  ============================================================================    

              reaper.ImGui_SameLine(ctx, nil, 10)
              reaper.ImGui_BeginGroup(ctx) 
               
      
            if reaper.ImGui_Button(ctx, 'PITCH',(btn_w*3)+(spacing_x*2),y)then reaper.Main_OnCommand(40653,0) end
               ToolTip(tt, "reset pitch")
            if reaper.ImGui_Button(ctx, '+1',32,y) then reaper.Main_OnCommand(40204,0) end
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, '+7',32,y) then pitch_plus_7() end
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, '+12',32,y) then reaper.Main_OnCommand(40515,0) end
            if reaper.ImGui_Button(ctx, '-1',32,y) then reaper.Main_OnCommand(40205,0) end
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, '-7',32,y) then pitch_minus_7() end
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, '-12',32,y) then reaper.Main_OnCommand(40516,0) end
            if reaper.ImGui_Button(ctx, 'com.',32,y) then  pitch_comp() end
               ToolTip(tt, "compress pitch \npitch above +12 is octaved down \npitch below -12 is octaved up")
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, 'inv.',32,y) then pitch_invers_x() end
               ToolTip(tt, "the scale tones are inverted \nexample(Cmaj7): \nc e g becomes c a f")
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, 'rand',32,y) then pitch_rand() end
               ToolTip(tt, "the transposition is random but fitting to the chord")            
               reaper.ImGui_EndGroup(ctx)   
               
--========================= SELECT ============================================================================   

               reaper.ImGui_SameLine(ctx, nil, 10)
               reaper.ImGui_BeginGroup(ctx) 
               
            if reaper.ImGui_Button(ctx, 'SELECT',(btn_w*3)+(spacing_x*2),y) then pattern_select() end
               ToolTip(tt, "Creates a select pattern \n0 = unselected \n1 = selected")
               reaper.ImGui_PushFont(ctx, SymbolFont)
            if reaper.ImGui_Button(ctx, 'A##4',32,y) then select_prev_item() end
               reaper.ImGui_PopFont(ctx)
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, 'inv.',32,y) then invert_item_selection() end
               reaper.ImGui_SameLine( ctx)
               reaper.ImGui_PushFont(ctx, SymbolFont)
            if reaper.ImGui_Button(ctx, 'B##4',32,y ) then select_next_item() end
               reaper.ImGui_PopFont(ctx)
            if reaper.ImGui_Button(ctx, 'chord',32,y) then select_chord() end
               ToolTip(tt, "Select only the selected items that are in the chord range \nunder which the cursor is positioned.")
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, 'root',32,y) then select_root_note() end
               ToolTip(tt, "select root note")
               reaper.ImGui_SameLine( ctx)
            if reaper.ImGui_Button(ctx, 'grid##1',32,y) then select_only_on_grid() end
               ToolTip(tt, "only selects items that start on the grid")            
               reaper.ImGui_EndGroup(ctx)  
            
--========================= MUTE  ============================================================================  

               reaper.ImGui_SameLine(ctx, nil, 10)
               reaper.ImGui_BeginGroup(ctx) 
            if reaper.ImGui_Button(ctx, 'MUTE', (btn_w*2)+(spacing_x*1),y) then reaper.Main_OnCommand(40175,0) end
               reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),   0,9)
              reaper.ImGui_PushItemWidth( ctx, (btn_w*2)+(spacing_x*1))
               retval, dinger = reaper.ImGui_DragInt( ctx, "##d", dinger, 0.1, 0,128)
               if retval then
               mute_exact(dinger,teiler) end
              
               ToolTip(tt, "Unmuted group consists of x items")
               reaper.ImGui_PopStyleVar(ctx,1)
             
               reaper.ImGui_PushItemWidth( ctx, (btn_w*1) )
               reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),   0,9)
               ret, teiler = reaper.ImGui_DragInt( ctx, "##1", teiler, 0.1, 1,24)
                if ret then 
               mute_exact(teiler,dinger) end
               ToolTip(tt, "how many unmuted groups")
               reaper.ImGui_SameLine(ctx)
               ret, sub = reaper.ImGui_DragInt( ctx, "##3", sub, 0.1, 1,16)
                if ret then 
               mute_exact(sub) end 
               ToolTip(tt, "push unmuted groups")
               reaper.ImGui_PopStyleVar(ctx,1)
            if reaper.ImGui_Button(ctx, 'rand##1', (btn_w), y) then
                       ran = false
               mute_exact(teiler,dinger,ran) end
               reaper.ImGui_SameLine(ctx)
            if reaper.ImGui_Button(ctx, 'nor##1',(btn_w), y) then
                       ran = true
                     mute_exact(teiler,dinger,ran) end
             --  reaper.ImGui_PopStyleVar(ctx,1)
               reaper.ImGui_EndGroup(ctx)  
          
--========================= ORDER  ============================================================================  

              reaper.ImGui_SameLine(ctx, nil, 10)
              reaper.ImGui_BeginGroup(ctx)   
              reaper.ImGui_Button(ctx, 'ORDER',(btn_w*2)+(spacing_x*1),y)
           if reaper.ImGui_Button(ctx, 'rate', btn_w,y) then order_rate() end
              reaper.ImGui_SameLine( ctx )
           if reaper.ImGui_Button(ctx, 'pitch', 32,y) then order_pitch() end               
           if reaper.ImGui_Button(ctx, 'reverse', (btn_w*2)+(spacing_x*1),y) then reverse = reaper.NamedCommandLookup("_XENAKIOS_REVORDSELITEMS")
              reaper.Main_OnCommand(reverse,0) end 
           if reaper.ImGui_Button(ctx, 'rand or', (btn_w*2)+(spacing_x*1),y) then shuffle_order() end
              reaper.ImGui_EndGroup(ctx) 
         
--========================= MIDI  ============================================================================  

              reaper.ImGui_SameLine(ctx, nil, 10)
               reaper.ImGui_BeginGroup(ctx)   
             
             
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(),0x34D632AA)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),0x1A6E19AA)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),0x34D632AA)
            if reaper.ImGui_Button(ctx, 'MIDI', (btn_w*2)+(spacing_x*1),y) then midi_creator() end
               reaper.ImGui_PopStyleColor(ctx, 3) 
            if reaper.ImGui_Button(ctx, 'SEQ', (btn_w*2)+(spacing_x*1),y) then midi_creator() end 
               ToolTip(tt, "Generates midi notes in time selection\n1 for one grid\n2 for two grids\netc. \nfor selected tracks")
            if reaper.ImGui_Button(ctx, 'pattern', (btn_w*2)+(spacing_x*1),y) then midi_rand() end
               ToolTip(tt, "Creates a random midi pattern depending on grid for selected tracks")
               reaper.ImGui_EndGroup(ctx) 
                
               
--========================= CHORDTRACK ============================================================================                
               
               reaper.ImGui_SameLine(ctx, nil, 10)
               reaper.ImGui_BeginGroup(ctx) 
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0x20CFFFAA)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),0x167B97AA)
               reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),0x20CFFFAA)
            if reaper.ImGui_Button(ctx, 'CHORDTRACK', (btn_w*4)+(spacing_x*3),y) then create_chordtrack() end
               ToolTip(tt, "Creates a chordtrack at the top if already available - move above selected track")
               reaper.ImGui_PopStyleColor(ctx, 3)
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
reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),   0,9)
reaper.ImGui_PushItemWidth( ctx, (btn_w*4)+(spacing_x*3) )
if reaper.ImGui_BeginCombo(ctx, '##chord progression', "       chord progression",  reaper.ImGui_ComboFlags_NoArrowButton()) then
  for i, chord in ipairs(chords) do
    i = i
    if reaper.ImGui_Selectable(ctx, chord, ca == i) then
      chord_progression(i)
    end
  end
 
  reaper.ImGui_EndCombo(ctx)
end             
if reaper.ImGui_ArrowButton( ctx, 13, 2 ) then chordsymbol_trans_up() end 
               ToolTip(tt, "Transposes the selected chord symbols up")
               reaper.ImGui_SameLine( ctx )
            if reaper.ImGui_Button(ctx, 'x##2',32,y) then chordsymbol_right() end  
                mods = {"  sudden dominant (2items)", "  minor subdominant (2items)", "  subdominant (1items)", "  parallel key (1item)"}
               reaper.ImGui_SameLine( ctx)
               reaper.ImGui_PushItemWidth( ctx, (btn_w*2)+(spacing_x*1) )
               ToolTip(tt, "quick change of the chord symbols")
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
           
         if reaper.ImGui_ArrowButton( ctx, 14, 3 ) then chordsymbol_trans_down() end
            ToolTip(tt, "Transposes the selected chord symbols down")              
            reaper.ImGui_PopStyleVar(ctx)
               reaper.ImGui_SameLine( ctx )
            if reaper.ImGui_Button(ctx, 'detection',(btn_w*2)+(spacing_x*1),y) then detect_midi_chords() end
            ToolTip(tt, "only midi!! \nWrites the recognised chords into the chordtrack") 
         
             reaper.ImGui_EndGroup(ctx) 
             
--========================= OTHER ============================================================================   

             reaper.ImGui_SameLine(ctx, nil, 10)
             reaper.ImGui_BeginGroup(ctx) 
         
             reaper.ImGui_Button(ctx, 'OTHER',(btn_w*2)+(spacing_x*1),y)
           
             if reaper.ImGui_Button(ctx, 'XML', (btn_w*2)+(spacing_x*1),y) then import_xml() end
                        ToolTip(tt, "loads the appropriate xml file for the audio file.(if available)\nselect track and don't allow import midi tempo..")
           if reaper.ImGui_Button(ctx, 'Color', (btn_w*2)+(spacing_x*1),y) then reaper.Main_OnCommand(40357,0) reaper.Main_OnCommand(40707,0) end 
           
           reaper.ImGui_EndGroup(ctx)     
--=============================================================================================================================
    reaper.ImGui_PopStyleVar(ctx)   
        reaper.ImGui_End(ctx)
        
    end 
  
    reaper.ImGui_PopStyleVar(ctx,6)
    reaper.ImGui_PopStyleColor(ctx, 11)
    reaper.ImGui_PopFont(ctx) -- Pop Font
   
    if open then
        reaper.defer(loop)
    else
        reaper.ImGui_DestroyContext(ctx)
    end
end
             
GuiInit()
loop()

                      
                     
