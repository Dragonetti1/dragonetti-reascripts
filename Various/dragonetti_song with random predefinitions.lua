-- @description song with random predefinitions
-- @author dragonetti
-- @version 1.0
-- @about
-- try to compose a song with these random preconditions
-- Thanks to nofish,mpl,Lokasenna,X-Raym and lb0.

  local
  
  
  
       Song_Tab = {}
       Song_Tab[0] = {title = 'unt',TS = '3/8',tempo ="181",KS ='Dm', chords ="Dm  A", part ="bri", style =" style", instr ="Si", misc ="acc" }
       Song_Tab[1] = {title = 'Norwegian Wood (Beatles)',TS = '3/8',tempo ="181",KS ='Dmajor', chords ="Dm Dm G G Dm Dm Em A", part ="Bridge", style ="beatles style", instr ="Sitar", misc ="acoustic" }
       Song_Tab[2] = {title = 'London Calling (The Clash)',TS = '4/4',tempo ="134",KS ='Eminor', chords ="Em F G D", part ="Vers", style ="punk", instr ="Bass Preci", misc ="shout choir" }
       Song_Tab[3] = {title = 'Guns of Brixton (The Clash)',TS = '4/4',tempo ="96",KS ='Dmajor', chords ="F#m Bm F#m Bm G Bm G Bm", part ="Vers", style ="reggea punk", instr ="mouth organ", misc ="timbales" }
       Song_Tab[4] = {title = 'Take five (Dave Brubeck)',TS = '5/8',tempo ="169",KS ='Ebminor', chords ="Cb Abm Bbm Gbm Abm Db7 Gb Gb", part ="chorus", style ="jazz", instr ="Saxophone", misc ="drumsolo" }
       Song_Tab[5] = {title = 'Pop Muzik (M)',TS = '4/4',tempo ="104",KS ='G#major', chords ="G# G# F# C#", part ="vers", style ="electro pop", instr ="guitar tremolo", misc ="la la laa laa laa laa laa .." }
       Song_Tab[6] = {title = 'Psycho Killer (Talking Heads)',TS = '4/4',tempo ="121",KS ='Amajor', chords ="F G Am Am F G C C", part ="chorus", style ="wave", instr ="quarter bass", misc ="fa fa fa faa" }
       Song_Tab[7] = {title = 'Oh happy Day (Edwin Hawkins Singers)',TS = '4/4',tempo ="114",KS ='Abmajor', chords ="Ab Ab Bbm Gbm Abm Db7 Gb Gb", part ="chorus", style ="gospel", instr ="choir", misc ="piano intro reverb" }
       Song_Tab[8] = {title = 'Whiskey in the Jar (Thin Lizzy)',TS = '4/4',tempo ="126",KS ='Gmajor', chords ="G G Em Em C C G G", part ="vers", style ="glam rock", instr ="guitar compress", misc ="guitar intro" }
       Song_Tab[9] = {title = 'Staying alive (Bee Gees)`',TS = '4/4',tempo ="104",KS ='Em', chords ="Em  A", part ="Intro", style ="disco", instr ="clean guitar", misc ="head voice" }
       Song_Tab[10] = {title = 'Take on me (a-ha)',TS = '4/4',tempo ="169",KS ='A major', chords ="A  E  F#m D", part ="chorus", style ="pop", instr ="DX7 Bass", misc ="Triad" }
       Song_Tab[11] = {title = 'Golden Brown (Stranglers)',TS = '3+3+3+4',tempo ="187",KS ='Dm', chords ="Bm  F#m  G  D", part ="instrumental", style ="pop", instr ="harpsicord", misc ="rhythm change" }
       Song_Tab[12] = {title = 'Heart of Glass (Blondie)',TS = '4/4',tempo ="141",KS ='E', chords ="A A E E A A F# B", part ="chorus", style ="pop", instr ="snare", misc ="snare wums" }
       Song_Tab[13] = {title = 'Don`t kill the whale (Yes)',TS = '4/4',tempo ="93",KS ='Bm', chords ="Bm  A  Em  G  C  F#m  F# ", part ="Intro", style ="prog rock", instr ="Polymoog", misc ="Bass envelope follower" }
       Song_Tab[14] = {title = 'Killing In the Name (Rage Against The Machine)',TS = '4/4',tempo ="126 / 82",KS ='', chords ="", part ="", style ="", instr ="", misc ="Tempo change" }                                         
       Song_Tab[15] = {title = 'Pretty Woman (Roy Orbison)',TS = '4/4',tempo ="130",KS ='Dm', chords ="A F#m  A  F#m D  D  E  E  E..", part ="", style ="", instr ="", misc ="clean guitar riff" }
       Song_Tab[16] = {title = 'Shine on you crazy diamond (Pink Floyd)',TS = '4/4 (tri)',tempo ="46",KS ='Gm', chords ="Gm---F#-Bb-EbEb/DCm7Eb/BbF---", part ="vers", style =" blues", instr ="fender", misc ="gm Pad" }
       Song_Tab[17] = {title = 'Autumn Leaves',TS = '4/4(tri)',tempo ="118?",KS ='Em', chords ="Em A D G C#m F# Bm _ C#m F# Bm Bm Em A D D C#m F# Bm C#m F# Bm Bm ", part ="", style ="jazz", instr ="", misc ="" } 
       

       TS_array = {"4/4", "6/8", "12/8", "4/4", "2/4", "3/8", "7/8","5/8","3/4","2+2+3","4/4","3+3+2","4/4",
        "6/8", "12/8","4/4", "6/8", "12/8", "4/4", "2/4", "3/8", "4/4", "2/4", "3/8"}
  
       instr_array = {"guitar", "bass", "keyboard", "organ", "vocals", "sequenzer", "drums",
        "Synth1", "pad", "drumcomputer", "recorder", "piano", "rhodes", "synth", "pick bass", 
        "funk bass", "drums", "power chords", "double bass", "choir", "string machine",
        "acoustic guitar", "moog"}
       
       tempo_min, tempo_max = 500, 1800
       
       style_array = {"pop","indie", "punk", "opera rock", "country", "folk", "rock`n roll", "wave", "indie", "funk", "soul", "march", "valse", "metal", "rock", "progrock", "jazz", "soul", "electronic",
       "rap","reggea", "classic", "new age", "latin", "world music", "blues", "rockjazz", "tango","polka"}
            
       KS_array = {"C major", "G major", "D major", "A major", "E major", "B major", "F# major", "F major","Bb major","Eb major", "Ab major", "Db major",
       "Gb major","C minor", "G minor", "D minor", "A minor", "E minor", "B minor", "F# minor", "F minor","Bb minor","Eb minor", "Ab minor", "Db minor","Gb minor"}
           
       part_array = {"chorus", "vers", "intro", "bridge", "instrumental","hookline","bassline","melody"}
       
       chords_array = {"I   I   IV   V", "V  IV  I  I", "V  IV  I  V", "Bluesform", "I  II  IV  I","I  VI  IV  V", "IV  V  I  VI", "I  II-  IV  V", "I  VI-  II-  V",
        "I  III-  II-  V","I  V  VI-  IV", "VI-  IV  I  V", "I  V  VI-  III-  IV  I  IV(II-)  V(Pachelbel)" ,
       "VI  V","VI-  V  IV  IIImaj", "VI  II  V  I  IV  VIIm  IIImaj  IIImaj","VI-  VI-  IV  V","VI-  IV  V  V  ","VI-  IV  V  VI-"}
       
       misc_array = {"la la la", "reversereverb", "fa fa fa faa fa fa", "achtel Bass", "mit Auftakt", "Oktav Bass", "geräusche integrieren", "Atmos", "Snare weglassen",
       "ohne Schlagzeug", "Rückung", "Bass Ostinato", "Gitarren Nachschläge", "Kopfstimme", "um eine Quinte transponieren", "Attackzeiten vom Schlagzeug erhöhen",
        "Tempoänderung"}
      
       strategies_array = {"A line has two sides",
       "A very small object" ,        
       "Its center",
       "Abandon desire",
       "Abandon normal instructions",
       "Abandon normal instruments",
       "Accept advice",
       "Accretion",
       "Adding on",
       "Allow an easement (an easement is the abandonment of a stricture)",
       "Always first steps",
       "Always give yourself credit for having more than personality ",
       "Always the first steps",
       "Are there sections?   Consider transitions",
       "Ask people to work against  their better judgement",
       "Ask your body",
       "Assemble some of the elements in a group and treat the group",
       "Balance the consistency principle with the inconsistency principle",
       "Be dirty",
       "Be extravagant",
       "Be less critical",
       "Breathe more deeply",
       "Bridges -build -burn",
       "Cascades",
       "Change ambiguities to specifics",
       "Change instrument roles",
       "Change nothing and continue consistently",
       "Change nothing and continue with immaculate consistency",
       "Change specifics to ambiguities",
       "Children   -speaking     -singing",
       "Cluster analysis",
       "Consider different fading systems",
       "Consider transitions",
       "Consult other sources  -promising -unpromising",
       "Convert a melodic element into a rhythmic element",
       "Courage!",
       "Cut a vital conenction",
       "Decorate, decorate",
       "Define an area as `safe' and use it as an anchor",
       "Destroy  -nothing   -the most important thing",
       "Destroy nothing; Destroy the most important thing",
       "Discard an axiom",
       "Disciplined self-indulgence",
       "Disconnect from desire",
       "Discover the recipes you are using and abandon them",
       "Discover your formulas and abandon them",
       "Display your talent",
       "Distort time",
       "Do nothing for as long as possible",
       "Do something boring",
       "Do something sudden, destructive and unpredictable",
       "Do the last thing first",
       "Do the washing up",
       "Do the words need changing?",
       "Do we need holes?",
       "Don't avoid what is easy",
       "Don't be frightened of cliches",
       "Don't break the silence",
       "Don't stress one thing more than another",
       "Dont be afraid of things because they're easy to do",
       "Dont be frightened to display your talents",
       "Emphasize differences",
       "Emphasize repetitions",
       "Emphasize the flaws",
       "Faced with a choice, do both (from Dieter Rot)",
       "Feed the recording back out of the medium",
       "Fill every beat with something",
       "Find a safe part and use it as an anchor",
       "Get your neck massaged",
       "Ghost echoes",
       "Give the game away",
       "Give the name away",
       "Give way to your worst impulse",
       "Go outside.  Shut the door.",
       "Go outside. Shut the door.",
       "Go slowly all the way round the outside",
       "Go to an extreme, come part way back",
       "Honor thy error as a hidden intention",
       "Honor thy mistake as a hidden intention",
       "How would someone else do it?",
       "How would you have done it?",
       "Humanize something free of error",
       "Idiot glee (?)",
       "Imagine the piece as a set of disconnected events",
       "In total darkness, or in a very large room, very quietly",
       "Infinitesimal gradations",
       "Intentions   -nobility of  -humility of   -credibility of",
       "Into the impossible",
       "Is it finished?",
       "Is something missing?",
       "Is the information correct?",
       "Is the style right?",
       "Is there something missing",
       "It is quite possible (after all)",
       "It is simply a matter or work",
       "Just carry on",
       "Left channel, right channel, center channel",
       "Listen to the quiet voice",
       "Look at the order in which you do things",
       "Look closely at the most embarrassing details & amplify them",
       "Lost in useless territory",
       "Lowest common denominator",
       "Magnify the most difficult details",
       "Make a blank valuable by putting it in an exquisite frame",
       "Make a sudden, destructive unpredictable action; incorporate",
       "Make an exhaustive list of everything you might do & do the last thing on the list",
       "Make it more sensual",
       "Make what's perfect more human",
       "Mechanicalize something idiosyncratic",
       "Move towards the unimportant",
       "Mute and continue",
       "Not building a wall but making a brick",
       "Once the search has begun, something will be found",
       "Only a part, not the whole",
       "Only one element of each kind",
       "Openly resist change",
       "Overtly resist change",
       "Pae White's non-blank graphic metacard",
       "Put in earplugs",
       "Question the heroic",
       "Question the heroic approach",
       "Reevaluation (a warm feeling)",
       "Remember quiet evenings",
       "Remember those quiet evenings",
       "Remove a restriction",
       "Remove ambiguities and convert to specifics",
       "Remove specifics and convert to ambiguities",
       "Repetition is a form of change",
       "Retrace your steps",
       "Reverse",
       "Short circuit (example; a man eating peas with the idea that they will improve  his virility shovels them straight into his lap)",
       "Simple subtraction",
       "Simply a matter of work",
       "Slow preparation, fast execution",
       "Spectrum analysis",
       "State the problem as clearly as possible",
       "State the problem in words as clearly as possible",
       "Take a break",
       "Take away the elements in order of apparent non-importance",
       "Take away the important parts",
       "Tape your mouth (given by Ritva Saarikko)",
       "The inconsistency principle",
       "The most easily forgotten thing is the most important",
       "The most important thing is the thing most easily forgotten",
       "The tape is now the music",
       "Think - inside the work -outside the work",
       "Think of the radio",
       "Tidy up",
       "Towards the insignificant",
       "Trust in the you of now",
       "Try faking it (from Stewart Brand)",
       "Turn it upside down",
       "Twist the spine",
       "Use `unqualified' people",
       "Use an old idea",
       "Use an unacceptable color",
       "Use cliches",
       "Use fewer notes",
       "Use filters",
       "Use something nearby as a model",
       "Use your own ideas",
       "Voice your suspicions",
       "Water",
       "What are the sections sections of? Imagine a caterpillar moving",
       "What are you really thinking about just now?",
       "What context would look right?",
       "What is the reality of the situation?",
       "What is the simplest solution?",
       "What mistakes did you make last time?",
       "What to increase? What to reduce? What to maintain?",
       "What were you really thinking about just now?",
       "What would your closest friend do?",
       "What wouldn't you do?",
       "When is it for?",
       "Where is the edge?",
       "Which parts can be grouped?",
       "Work at a different speed",
       "Would anyone want it?",
       "You are an engineer",
       "You can only make one dot at a time",
       "You don't have to be ashamed of using your own ideas",}
             
       
  -------------------------------  
  local b,m={},{}
  function B_perform(b)
    gfx.rect(b.x,b.y,b.w,b.h,0)
    gfx.setfont(1, "Arial", 16)
    gfx.x, gfx.y = b.x+(b.w-gfx.measurestr(b.txt))/18, b.y+(b.h-gfx.texth)/2
    gfx.drawstr(b.txt)
    
    
  end
 
  -------------------------------
  math.randomseed(os.time())
  function Define_Buttons()    
    local offs = 8
    local w_b, h_b = gfx.w-1.5*offs, 35
        
        
    b.titel = {x=offs,y=offs,w=384,h=h_b, txt='', 
                            func = function()
                            local v = math.random(1,#Song_Tab)
                            
                            b.titel.txt =''..Song_Tab[v].title
                            b.TS.txt = "   "..Song_Tab[v].TS
                            b.tempo.txt = "   "..Song_Tab[v].tempo
                            b.KS.txt = "  "..Song_Tab[v].KS
                            b.chords.txt = " "..Song_Tab[v].chords
                            b.part.txt = "  "..Song_Tab[v].part
                            b.style.txt = "  "..Song_Tab[v].style
                            b.instr.txt = "  "..Song_Tab[v].instr
                            b.misc.txt = "  "..Song_Tab[v].misc                            
                        
                            end}
       
                                                                                                                                       
     b.TS = {x=offs,y=offs*2+h_b,w=70,h=h_b, txt='  ', 
                   func =  function() local val_timesig,val_denom
                             local val = TS_array[ math.random(1,#TS_array) ]
                             
                             b.TS.txt = '   '..val
                            
                                                                                      
                           end}
                           
         b.tempo = {x=85,y=offs*2+h_b,w=70,h=h_b, txt='',
                   func =  function() local val_timesig,val_denom
                             local val = math.random(tempo_min, tempo_max)/10
                             b.tempo.txt = '  '..val
                            
                             
                           end}
           b.KS = {x=161,y=offs*2+h_b,w=70,h=h_b, txt='',
                                    func =  function() local val_instr
                                  local val = KS_array[ math.random(1,#KS_array) ]
                                      b.KS.txt = '  '..val
                                                                        
                                                     end}
            b.chords = {x=offs,y=offs*7+h_b,w=384,h=h_b, txt='',
                                                   func =  function() local val_instr
                                                             local val = chords_array[ math.random(1,#chords_array) ]
                                                             b.chords.txt = ' '..val
                                                                                                 
                                                      end} 
                                                        
                                                      
                                                      
                                                      
                                                                                  
             b.part = {x=104,y=offs*12+h_b,w=90,h=h_b, txt='',
                                                  func =  function() local val_instr
                                                             local val = part_array[ math.random(1,#part_array) ]
                                                             b.part.txt = ' '..val
                                                                                                
                                                      end}
             b.style = {x=offs,y=offs*12+h_b,w=90,h=h_b, txt='',
                                                  func =  function() local val_instr
                                                            local val = style_array[ math.random(1,#style_array) ]
                                                            b.style.txt = ' '..val
                                                                                                  
                                                     end}                                                                                                                                                                                                                               
                                                
              b.instr = {x=200,y=offs*12+h_b,w=140,h=h_b, txt='',
                                func =  function() local val_instr
                                         local val = instr_array[ math.random(1,#instr_array) ]
                                        b.instr.txt = ' '..val
                                       
                          end}
                                       
                              
            b.misc = {x=offs,y=offs*17+h_b,w=384,h=h_b, txt='',
                           func =  function() local val_instr
                                       local val = misc_array[ math.random(1,#misc_array) ]
                                       b.misc.txt = ' '..val
                                                                            
                                end}                      
                           
             b.strat = {x=offs,y=offs*22+h_b,w=384,h=h_b, txt='',
                          
                            func =  function()
                          
                            local val_instr
                                      local val = strategies_array[ math.random(1,#strategies_array) ]
                                      b.strat.txt = ' '..val
                                                                                
                              
                               end}
                               b.itemsend = {x=offs,y=offs*47+h_b,w=120,h=h_b, txt='Send to item',
                                              func =  function() SendToItem()                                             
                                                      end}
             b.itemsend = {x=offs,y=offs*30+h_b,w=120,h=h_b, txt='  Send to text item',
                    func =  function() SendToItem()                                             
                            end}
                            
                            b.clear = {x=332,y=offs*30+h_b,w=60,h=h_b, txt='  CLEAR',
                                                        func =  function() local val_instr
                                                                  local val = strategies_array[ math.random(1,#strategies_array) ]
                                                                  b.strat.txt = ' '
                                                                  b.titel.txt =''
                                                                  b.TS.txt = ''
                                                                  b.tempo.txt = ''
                                                                  b.KS.txt = ''
                                                                  b.chords.txt = ''
                                                                  b.part.txt = ''
                                                                  b.style.txt = ''
                                                                  b.instr.txt = ''
                                                                  b.misc.txt = ''
                                                                                                               
                                                           end}
                            
                            
                                                                                     
                                                                                                                                                                         
      end
      
      -------------------------------
      
      
   
      
      function SendToItem()
      
      reaper.Main_OnCommand(40001,40706,0)
      reaper.Main_OnCommand(40358,0) 
      reaper.ReorderSelectedTracks(0,0)
      reaper.Main_OnCommand(65535,0)
     
      
         reaper.UpdateArrange()
         reaper.Undo_EndBlock("Insert Track and FX with name" , 1)
      
        --Create text string to display in item
        local txt = b.titel.txt..'    '..b.tempo.txt..'    '..b.TS.txt..'    '..b.KS.txt..'    '..b.chords.txt..'    '..b.part.txt..'    '
        ..b.style.txt.."    "..b.instr.txt.."    "..b.misc.txt.."  \n"..b.strat.txt
        
        --Get track 1
        local track = reaper.GetTrack(0,0)
        
        --Create Item - (colour = 128 << 16 + 128 << 8 + 128)
        local item = CreateTextItem(track, 0, 300, txt, 128 << 16 + 128 << 8 + 64)
        
        --Edit item flags (for stretching text)
        local _, chunk = reaper.GetItemStateChunk(item, '', false)
        chunk = string.gsub(chunk, '(IMGRESOURCEFLAGS %d)', 'IMGRESOURCEFLAGS 2')
        reaper.SetItemStateChunk(item, chunk, false)
      
      end
      
      -- ************
      -- * X-RAYM's * 
      -- ************
      
      function CreateTextItem(track, position, length, text, color)
          
        local item = reaper.AddMediaItemToTrack(track)
        
        reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
        reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)
        
        if text then
          reaper.ULT_SetMediaItemNote(item, text)
        end
        if color then
          reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
        end
        return item
      end                                                                                                           
                                                                                                                                                                                                                                                                                                                                                                                                   
                                                                                                                                                                                                    
  -------------------------------
  function mouse()
    m.x = gfx.mouse_x
    m.y = gfx.mouse_y
    m.st = gfx.mouse_cap==1    
    for key in pairs(b) do 
      if m.x > b[key].x and m.x < b[key].x+ b[key].w 
        and m.y > b[key].y and m.y < b[key].y+ b[key].h 
        and m.st and not m.Lst then
        b[key].func()
      end
    end    
    m.Lst =  m.st
  end
  -------------------------------  
  function Main()
    for key in pairs(b) do B_perform(b[key]) end
    local char = gfx.getchar()
    gfx.update()  
    mouse()
    if char ~= 27 and char ~= -1 then reaper.defer(Main) end      
  end
  ------------------------------- 
  gfx.init("Randomizer", 400, 320, 250, 700, 300)
  gfx.set(0.6, 0.6, 0.5, 0.6)
  --gfx.init(wtitle, 275, 405, 1, 200, 100)
  gfx.dock(769)
  reaper.atexit(gfx.quit)
  Define_Buttons()
  Main()

