-- @version 0.3.5
-- @author Dragonetti
-- @provides 
--    get_synonyms_de.py
--    get_synonyms_en.py
--    pyphen_syllable_splitter.py
--    translate_to_german.py
-- @changelog
--    +  bug fixes
function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

version = " 0.3.5"

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' ('0.9.2')
font = reaper.ImGui_CreateFont('arial', 15 )

-- Define the stateColors table before using it
local stateColors = {
    [0] = { 0.0, 0.3, 0.5, 0.6 },  -- neutral (standard)
    [1] = { 1.0, 0.0, 0.0, 1.0 },  -- red
    [2] = { 0.0, 1.0, 0.0, 1.0 },  -- green
    [3] = { 0.0, 0.0, 1.0, 1.0 },  -- blue
    [4] = { 1.0, 1.0, 0.0, 1.0 }   -- yellow
}
-- Function to pack RGBA values into a 32-bit integer
local function packColor(r, g, b, a)
    local r255 = math.floor(r * 255)
    local g255 = math.floor(g * 255)
    local b255 = math.floor(b * 255)
    local a255 = math.floor(a * 255)
    local color = (r255 << 24) | (g255 << 16) | (b255 << 8) | a255
    return color
end
local availableLanguages = { "en", "de", "fr", "es", "it", "jp" }
local availableModels = { "base", "small", "medium", "large", "tiny" }

local selectedLanguage = "en"
local selectedModel = "base"
-- Erzeuge den ImGui-Kontext, falls noch nicht geschehen
local ctx = ImGui.CreateContext("ReaLy")  -- More unique context name
ImGui.Attach(ctx, font)
-- Setze die Flags für das Fenster
local window_flags = ImGui.WindowFlags_AlwaysAutoResize |
                     ImGui.WindowFlags_NoCollapse |
                     ImGui.WindowFlags_None


local styleBuf = "Nick Cave"  -- Standardwert für den Stil
local showStyleAndCopyButtons = false

-- Tabellen zum Speichern der Texteingaben und Button-Status
local widgets = {
    input = {
        field1 = { text = "They tumble blindly as they make their way across the universe" }, -- Beispieltext für Textfeld 1
        field2 = { text = "" }, -- Ausgabe der Zählung für Textfeld 1
        field3 = { text = "" }, -- Ausgabe der Zählung für Textfeld 4
        field4 = { text = "" }, -- Textfeld 4 für die Silbenzählung
    },
    buttons = { placeholders = {} } -- Speichern der Placeholder-Buttons
}


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
-- Function to get a track by its name
function getTrackByName(name)
    for i = 0, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, i)
        local _, trackName = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
        if trackName == name then
            return track
        end
    end
    return nil
end

-- Variablen zum Speichern des Originaltexts
local original_text = nil
local is_split = false  -- Status, ob die Silbentrennung ausgeführt wurde

-- Funktion zur Silbentrennung mit Pyphen (ausgeführtes Python-Skript)
local function split_syllables_field1(lang)
    -- Speichere den Originaltext nur beim ersten Aufruf
    if not original_text then
        original_text = widgets.input.field1.text
    end

    -- Ersetze Zeilenumbrüche durch Platzhalter
    local text = widgets.input.field1.text:gsub("\n", "NEWLINE_MARKER")

    -- Entferne alle Anführungszeichen (sowohl einfache als auch doppelte)
    text = text:gsub('"', ''):gsub("'", "")

    -- Der Pfad zum Python-Skript, relativ zum Speicherort des Lua-Skripts
    local script_directory = reaper.GetResourcePath() .. "/Scripts/dragonetti-reascripts/Various/ReaLy"
    local python_script_path = script_directory .. "/pyphen_syllable_splitter.py"
    
    local command = string.format('python "%s" "%s" "%s"', python_script_path, text, lang)
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()

    -- Rückgängig machen der Platzhalter-Ersetzung
    result = result:gsub("NEWLINE_MARKER", "\n")

    -- Aktualisiere `field1` mit dem geteilten Text und setze den Status auf "geteilt"
    widgets.input.field1.text = result
    is_split = true
end



-- Funktion zum Zurücksetzen auf den Originaltext
local function unsplit_field1()
    if original_text then
        widgets.input.field1.text = original_text
    end
end

----------------------- synonyme ----------------------
-- Lua function to call the correct Python script based on the selected language

local function get_synonyms_with_nltk(word)
    local script_directory = reaper.GetResourcePath() .. "/Scripts/dragonetti-reascripts/Various/ReaLy/"
    local python_script_path

    -- Choose the script based on selected language
    if selectedLanguage == "en" then
        python_script_path = script_directory .. "get_synonyms_en.py"
    elseif selectedLanguage == "de" then
        python_script_path = script_directory .. "get_synonyms_de.py"
    else
        reaper.ShowMessageBox("Unsupported language: " .. selectedLanguage, "Error", 0)
        return {}
    end

    -- Execute the selected Python script with the word as argument
    local command = 'python "' .. python_script_path .. '" "' .. word .. '"'
    local handle = io.popen(command)
    local result = handle:read("*a")  -- Read the entire output from the script
    handle:close()

    -- Parse the result into a table of synonyms
    synonymsList = {}
    if result and result ~= "" then
        for synonym in result:gmatch("[^,]+") do
            table.insert(synonymsList, synonym:match("^%s*(.-)%s*$"))  -- Trim whitespace
        end
    end

    return synonymsList
end



-- Update the rotate_synonym_label function to use the button label directly
local function rotate_synonym_label(button)
    -- Only fetch synonyms on the first right-click
    if not button.synonyms or #button.synonyms == 0 then
        -- Fetch synonyms based on the button's current label
        button.synonyms = get_synonyms_with_nltk(button.label)
        
        -- Add the original label as the last item in the synonyms list for a cyclic rotation
        table.insert(button.synonyms, button.label)
        button.synonym_index = 1  -- Reset index
    end

    -- Rotate through synonyms and update the label
    button.label = button.synonyms[button.synonym_index]
    button.synonym_index = (button.synonym_index % #button.synonyms) + 1
end

--------------------------------------------------------------------------


function import_selected_empty_items()
    -- Get the number of selected media items
    local itemCount = reaper.CountSelectedMediaItems(0)

    -- Check if there are selected items
    if itemCount == 0 then
        reaper.ShowMessageBox("No items selected!", "Error", 0)
        return
    end

    -- Variable to hold all the notes
    local allNotes = ""

    -- Loop through selected items
    for i = 0, itemCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        
        -- Check if the item is empty (no media source)
        local take = reaper.GetActiveTake(item)
        if take == nil then
            -- Get the item notes (assuming notes are stored in "P_NOTES")
            local itemNotes = reaper.ULT_GetMediaItemNote(item)
            
            -- Append the notes to the collection
            if itemNotes and itemNotes ~= "" then
                allNotes = allNotes .. itemNotes .. "\n\n"  -- Add notes followed by two newlines
            end
        end
    end

    -- Set the collected notes to the text field "textfield1"
    widgets.input.field1.text = allNotes
end

-- Update the arrangement to reflect changes
reaper.UpdateArrange()


-- Function to create a new track above a specific track
function createTrackAbove(trackIndex, name)
    -- Insert a new track at the specified index
    reaper.InsertTrackAtIndex(trackIndex, false) -- Insert track at the given index
    -- Get the newly created track
    local newTrack = reaper.GetTrack(0, trackIndex)
    -- Set the name of the new track
    reaper.GetSetMediaTrackInfo_String(newTrack, 'P_NAME', name, true)
    return newTrack
end


-- Function to create an empty item on the 'lyrics' track
function create_empty_item_on_lyrics_track(item_start, item_length)
    -- Find the 'lyrics' track by name
    local lyricsTrack = getTrackByName("lyrics")
    
    -- If the 'lyrics' track doesn't exist, create it
    if lyricsTrack == nil then
        -- Get the selected item
        local selectedItem = reaper.GetSelectedMediaItem(0, 0)
        if not selectedItem then
            reaper.ShowMessageBox("Kein Item ausgewählt!", "Fehler", 0)
            return nil
        end
        
        -- Get the track of the selected item
        local selectedTrack = reaper.GetMediaItem_Track(selectedItem)
        local trackIndex = reaper.GetMediaTrackInfo_Value(selectedTrack, "IP_TRACKNUMBER") - 1
        
        -- Create a new 'lyrics' track above the selected track
        lyricsTrack = createTrackAbove(trackIndex, "lyrics")
        if lyricsTrack == nil then
            reaper.ShowMessageBox("Track 'lyrics' konnte nicht erstellt werden!", "Fehler", 0)
            return nil
        end
    end
    
    -- Create an empty item on the 'lyrics' track
    local emptyItem = reaper.AddMediaItemToTrack(lyricsTrack)
    if emptyItem ~= nil then
        reaper.SetMediaItemInfo_Value(emptyItem, "D_POSITION", item_start)
        reaper.SetMediaItemInfo_Value(emptyItem, "D_LENGTH", item_length)
        reaper.UpdateArrange() -- Refresh the arrangement
        return emptyItem
    else
        reaper.ShowMessageBox("Leeres Item konnte nicht erstellt werden!", "Fehler", 0)
        return nil
    end
end

-- Function to write text into the notes of a media item
function write_text_to_item_notes(item, text)
    if item ~= nil then
        -- Write the text into the notes section of the media item
        reaper.GetSetMediaItemInfo_String(item, "P_NOTES", text, true)
        -- Update the arrangement to reflect the change
        reaper.UpdateArrange()
    else
        reaper.ShowMessageBox("Kein gültiges Item ausgewählt!", "Fehler", 0)
    end
end

-- Funktion, um den Text aus den Wort-Buttons in field1 zu kopieren und Leerzeichen vor "-" zu entfernen
local function copyButtonsToField1()
    -- Überprüfe, ob Buttons vorhanden sind
    if #widgets.buttons.placeholders == 0 then
        return  -- Nichts tun, wenn keine Buttons vorhanden sind
    end
    
    local newText = ""
    
    -- Iteriere über jede Zeile der Buttons
    for lineIndex, buttonLine in ipairs(widgets.buttons.placeholders) do
        local lineText = ""
        -- Iteriere über jeden Button in der Zeile
        for _, button in ipairs(buttonLine) do
            lineText = lineText .. button.label .. " "  -- Füge den Button-Text hinzu
        end
        newText = newText .. lineText:sub(1, -2) .. "\n"  -- Entferne das letzte Leerzeichen und füge einen Zeilenumbruch hinzu
    end
    
    -- Entferne Leerzeichen vor Bindestrichen
    newText = newText:gsub(" %-", "-") -- Entferne Leerzeichen vor Bindestrichen
    
    -- Setze den formatierten Text in field1
    widgets.input.field1.text = newText
end

-- Funktion zum Kopieren der Placeholder-Labels in die Zwischenablage
local function copyPlaceholdersToClipboard()
    -- Verwende den aktuellen Stil aus styleBuf und füge ihn in den zusätzlichen Text ein
    local additionalText = "It's supposed to be a song lyric in the style of " .. styleBuf .. ".\n" ..
                           "Please replace the (monosyllabic) with your own syllables so that the lyrics make sense,\n" ..
                           "Note the frequency of the (monosyllabic) without changing the order!!\n" ..
                           "Please 2 attempts.\n" ..
                           "Now the lyric:"

    -- Füge den zusätzlichen Text am Anfang des Clipboard-Textes hinzu
    local clipboardText = additionalText .. "\n"
    
    -- Tabelle, um die Zeilen-States zu sammeln, um Reimhinweise hinzuzufügen
    local lineStates = {}

    -- Variable für dynamisches Zählen der Zeilen
    local dynamicLineIndex = 1

    -- Iteriere über jede Zeile der Placeholder-Buttons
    for _, buttonLine in ipairs(widgets.buttons.placeholders) do
        -- Check if buttonLine exists and has buttons
        if buttonLine and #buttonLine > 0 then
            local lineText = ""
            for _, button in ipairs(buttonLine) do
                -- Wenn kein Placeholder-Text vorhanden ist, füge (monosyllabic) hinzu
                if button.placeholder == "" then
                    lineText = lineText .. "(monosyllabic) "
                else
                    lineText = lineText .. button.placeholder .. " "
                end
            end
            -- Entferne das letzte Leerzeichen und füge die dynamische Zeilennummer hinzu
            lineText = lineText:sub(1, -2) .. " (" .. dynamicLineIndex .. ")"  -- Dynamische Zeilennummer am Ende hinzufügen

            -- Füge die fertige Zeile zum Clipboard-Text hinzu
            clipboardText = clipboardText .. lineText .. "\n"

            -- Sammle den State des ersten Buttons jeder Zeile
            local state = buttonLine[1].state or 0  -- Use 0 as default if state is nil
            if not lineStates[state] then
                lineStates[state] = {}
            end
            table.insert(lineStates[state], dynamicLineIndex)

            -- Erhöhe den dynamischen Zeilenindex für die nächste Zeile
            dynamicLineIndex = dynamicLineIndex + 1
        end
    end

    -- Füge Reimhinweise hinzu basierend auf den States
    local rhymeHints = ""

    -- Überprüfe die Zeilen-Gruppen nach Farben
    for state, rhymeGroup in pairs(lineStates) do
        if state ~= 0 and #rhymeGroup > 1 then  -- Überspringe den neutralen Zustand (0) und schreibe nur bei mehr als 1 Zeile
            rhymeHints = rhymeHints .. "Lines " .. table.concat(rhymeGroup, " and ") .. " should rhyme.\n"
        end
    end

    -- Füge die Reimhinweise zum Clipboard-Text hinzu, aber nur, wenn welche existieren
    if rhymeHints ~= "" then
        clipboardText = clipboardText .. "\n" .. rhymeHints
    end

    -- Entferne Leerzeichen vor Bindestrichen
    clipboardText = clipboardText:gsub(" %-", "-")

    -- Entferne alle Bindestriche
    clipboardText = clipboardText:gsub("%-", "")

    -- Kopiere den Text in die Zwischenablage
    reaper.CF_SetClipboard(clipboardText)
end

local function translate_text_to_german()
    -- Get the text from field1 and replace newlines with a placeholder
    local text_to_translate = widgets.input.field1.text:gsub("\n", "NEWLINE_MARKER")

    -- Path to the Python translation script
    local script_directory = reaper.GetResourcePath() .. "/Scripts/dragonetti-reascripts/Various/ReaLy"
    local python_script_path = script_directory .. "/translate_to_german.py"

    -- Run the Python script and pass the modified text as an argument
    local command = string.format('python "%s" "%s"', python_script_path, text_to_translate)
    local handle = io.popen(command)
    local translated_text = handle:read("*a")
    handle:close()

    -- Replace the placeholder with newlines again in the translated text
    translated_text = translated_text:gsub("NEWLINE_MARKER", "\n")
    
    -- Set the translated text into field4
    widgets.input.field4.text = widgets.input.field4.text or ""
    widgets.input.field4.text = translated_text
end




-- Funktion zum Entfernen nicht relevanter Fehlermeldungen und Bereinigung des Timecodes
function remove_text_before_sprache_and_clean_timecodes(transcribed_text)
    local clean_text = transcribed_text:match("%[%d%d:%d%d%.%d%d%d%s*%-%->%s*%d%d:%d%d%.%d%d%d%](.*)")
    if not clean_text then
        clean_text = transcribed_text  
    end
    clean_text = clean_text:gsub("%[%d%d:%d%d%.%d%d%d%s*%-%->%s*%d%d:%d%d%.%d%d%d%]", "")
    clean_text = clean_text:gsub("%[%d%d:%d%d%.%d%d%d%]", "")
    clean_text = clean_text:gsub("^%s+", "")
    clean_text = clean_text:gsub("%s+\n", "\n"):gsub("\n%s+", "\n")
    return clean_text
end
local default_whisper_exe = "C:\\Users\\mark\\AppData\\Local\\Programs\\Python\\Python311\\Scripts\\whisper.exe"
local path_file = reaper.GetResourcePath() .. "\\whisper_path.txt"



function get_whisper_executable_path()
    -- Versuche, den gespeicherten Pfad zu laden, oder verwende den voreingestellten Pfad
    local whisper_exe = default_whisper_exe
    local file = io.open(path_file, "r")
    if file then
        whisper_exe = file:read("*all")
        file:close()
    end

    -- Überprüfe, ob der gespeicherte oder voreingestellte Pfad funktioniert
    local file_check = io.open(whisper_exe, "r")
    if not file_check then
        -- Der Pfad ist falsch, fordere den Benutzer zur Eingabe auf
        local retval, new_path = reaper.GetUserInputs("Whisper Executable Not Found", 1, "Enter the correct Whisper.exe path: extrawidth=400", whisper_exe)
        
        if retval then
            -- Speichere den neuen Pfad in der Datei
            local save_file = io.open(path_file, "w")
            if save_file then
                save_file:write(new_path)
                save_file:close()
            end
            return new_path
        else
            reaper.ShowMessageBox("Whisper executable path not provided. Exiting...", "Error", 0)
            return nil
        end
    else
        file_check:close()
    end
    
    return whisper_exe
end


function glue_and_transcribe_item(item)
    if not item then
        reaper.ShowMessageBox("Fehler: Kein gültiges Item ausgewählt!", "Fehler", 0)
        return
    end

    reaper.SetMediaItemSelected(item, true)
    reaper.Undo_BeginBlock()
    reaper.Main_OnCommand(40362, 0) -- Glue the item

    local glued_item = reaper.GetSelectedMediaItem(0, 0)
    if not glued_item then
        reaper.ShowMessageBox("Fehler: Das geklebte Item konnte nicht gefunden werden!", "Fehler", 0)
        reaper.Undo_EndBlock("Glue and Whisper", -1)
        return
    end

    local glued_take = reaper.GetActiveTake(glued_item)
    local glued_source = reaper.GetMediaItemTake_Source(glued_take)
    local glued_file_path = reaper.GetMediaSourceFileName(glued_source, "")

    -- Verarbeite die geklebte Datei mit Whisper
    local transcribed_text = execute_whisper(glued_file_path, selectedLanguage, selectedModel or "base")

    -- Debug: Zeige den transkribierten Text an
    if transcribed_text then
       -- reaper.ShowConsoleMsg("Transkribierter Text (von Whisper):\n" .. transcribed_text .. "\n")
        local clean_text = remove_text_before_sprache_and_clean_timecodes(transcribed_text)
        widgets.input.field1.text = clean_text
    else
        reaper.ShowMessageBox("Fehler: Whisper konnte die Datei nicht verarbeiten!", "Fehler", 0)
    end

    reaper.Undo_EndBlock("Glue and Whisper", -1)
    reaper.UpdateArrange()
end




function execute_whisper(input_file, language, model)
    -- Überprüfe, ob das Modell korrekt übergeben wurde, sonst Standardmodell setzen
    if not model then
        model = "base" -- Standardmodell, falls keines ausgewählt wurde
    end

    -- Überprüfe, ob die Sprache korrekt übergeben wurde, sonst Standardsprache setzen
    if not language then
        language = "en" -- Standardsprache Englisch, falls keine ausgewählt wurde
    end

    -- Whisper executable path
    local whisper_exe = get_whisper_executable_path()
    
    -- Falls der Pfad immer noch nicht korrekt ist, abbrechen
    if not whisper_exe then
        return nil
    end

    -- Überprüfe, ob Whisper.exe existiert
    local file_check = io.open(whisper_exe, "r")
    if not file_check then
        reaper.ShowMessageBox("Whisper executable not found at: " .. whisper_exe, "Error", 0)
        return nil
    else
        file_check:close() -- Schließe die Datei, wenn sie gefunden wurde
    end

    -- Erstelle temporäre Dateien für Whisper
    local temp_dir = os.getenv("TEMP")
    local batch_file = temp_dir .. "\\whisper_batch.bat"
    local log_file = temp_dir .. "\\whisper_log.txt"

    -- Erstelle das Whisper-Kommando
    local whisper_cmd = '@echo off\n'
    whisper_cmd = whisper_cmd .. '"' .. whisper_exe .. '" "' .. input_file .. '" --language ' .. language .. ' --model ' .. model .. ' --output_format txt > "' .. log_file .. '" 2>&1\n'

    local file = io.open(batch_file, "w")
    if file then
        file:write(whisper_cmd)
        file:close()
    else
        reaper.ShowMessageBox("Error creating batch file for Whisper execution!", "Error", 0)
        return nil
    end

    -- Führe das Kommando aus
    os.execute('cmd.exe /C ' .. batch_file)

    -- Lese die Transkription aus der Log-Datei
    local transcribed_text = ""
    local output_file_handle = io.open(log_file, "r")
    if output_file_handle then
        transcribed_text = output_file_handle:read("*all")
        output_file_handle:close()
    else
        reaper.ShowMessageBox("Error reading the transcription log file!", "Error", 0)
        return nil
    end

    -- Lösche die temporären Dateien
    os.remove(batch_file)
    os.remove(log_file)

    return transcribed_text
end


-- Funktion zum Zählen der Silben in jeder Zeile
local function countSyllablesPerLine(text)
    local lines = {}
    for line in text:gmatch("([^\r\n]*)\r?\n?") do
        if line == "" then
            table.insert(lines, "") 
        else
            local syllableCount = 0
            for word in line:gmatch("%S+") do
                local hyphenCount = select(2, word:gsub("%-", ""))
                syllableCount = syllableCount + 1 + hyphenCount
            end
            table.insert(lines, tostring(syllableCount)) 
        end
    end
    return table.concat(lines, "\n") 
end

-- Funktion zum Generieren der Buttons basierend auf den Wörtern in Field 1
local function makeButtonsFromWords(text)
    local buttons = {}
    for line in text:gmatch("[^\r\n]+") do
        local buttonLine = {}
        for word in line:gmatch("%S+") do
            -- Split the word at hyphens
            local parts = {}
            for part in word:gmatch("[^%-]+") do
                table.insert(parts, part)
            end
            
            -- Create buttons for each part of the word
            for i, part in ipairs(parts) do
                local label
                if i == 1 then
                    label = part  -- First part without a hyphen
                else
                    label = "-" .. part  -- Subsequent parts with a hyphen
                end
                
                local wordLength = ImGui.CalcTextSize(ctx, label) + 8 -- Adjust button length to word length
                table.insert(buttonLine, { 
                    label = label, 
                    length = wordLength, 
                    placeholder = label, 
                    state = 0  -- Default state (neutral)
                })
                
                -- If there are more parts, place buttons next to each other with no spacing
                if i < #parts then
                    ImGui.SameLine(ctx, nil, 0) -- No spacing between buttons
                end
            end
        end
        table.insert(buttons, buttonLine) -- Store each line of buttons
    end
    return buttons
end



-- Standardpfad zur HTML-Datei
local default_html_file_path = "C:\\Users\\mark\\AppData\\Roaming\\REAPER\\reaper_www_root\\song_lyrics.html"
local path_file = reaper.GetResourcePath() .. "\\html_file_path.txt"

-- Funktion zum Abrufen oder Festlegen des Dateipfads
function get_html_file_path()
    -- Versuche, den gespeicherten Pfad zu laden, oder verwende den voreingestellten Pfad
    local file_path = default_html_file_path
    local file = io.open(path_file, "r")
    if file then
        file_path = file:read("*all")
        file:close()
    end

    -- Überprüfe, ob die Datei am gespeicherten/voreingestellten Pfad existiert
    local file_check = io.open(file_path, "r")
    if not file_check then
        -- Falls der Pfad falsch ist, fordere den Benutzer zur Eingabe auf
        local retval, new_path = reaper.GetUserInputs("HTML-Datei nicht gefunden", 1, "Enter the correct HTML file path: extrawidth=360", file_path)
        
        if retval then
            -- Speichere den neuen Pfad in der Datei
            local save_file = io.open(path_file, "w")
            if save_file then
                save_file:write(new_path)
                save_file:close()
            end
            return new_path
        else
            reaper.ShowMessageBox("Kein HTML-Dateipfad angegeben. Vorgang wird abgebrochen.", "Fehler", 0)
            return nil
        end
    else
        file_check:close()
    end
    
    return file_path
end

-- Funktion zum Schreiben des Texts in die HTML-Datei
function write_text_to_html(text)
    -- Hole den Dateipfad
    local file_path = get_html_file_path()
    
    -- Falls kein Dateipfad verfügbar ist, breche ab
    if not file_path then
        return
    end

    -- Öffne die Datei im Lesemodus
    local file = io.open(file_path, "r")
    if not file then
        reaper.ShowMessageBox("Fehler: Die Datei konnte nicht geöffnet werden!", "Fehler", 0)
        return
    end

    -- Lese den Inhalt der HTML-Datei
    local html_content = file:read("*all")
    file:close()

    -- Ersetze alle Zeilenumbrüche (\n) durch <br>, damit sie in HTML angezeigt werden
    local text_with_breaks = text:gsub("\n", "<br>")
    
    -- Ersetze den Inhalt des Div mit der ID lyricsContainer
    local new_html_content = html_content:gsub('<div id="lyricsContainer">.-</div>', '<div id="lyricsContainer">' .. text_with_breaks .. '</div>')
    
    -- Öffne die Datei im Schreibmodus, um den neuen Inhalt zu schreiben
    file = io.open(file_path, "w")
    if not file then
        reaper.ShowMessageBox("Fehler beim Schreiben in die Datei!", "Fehler", 0)
        return
    end

    -- Schreibe den aktualisierten HTML-Inhalt in die Datei
    file:write(new_html_content)
    file:close()

    -- Optional: Bestätigungsmeldung anzeigen
    -- reaper.ShowMessageBox("Text erfolgreich in die HTML-Datei eingefügt!", "Erfolg", 0)
end

-- Define the function here
function transcribe_and_update_field1()
    local selected_item = reaper.GetSelectedMediaItem(0, 0)
    if selected_item then
        glue_and_transcribe_item(selected_item)
    else
        reaper.ShowMessageBox("Fehler: Kein Item ausgewählt!", "Fehler", 0)
    end
end


local function safe_utf8_codes(text)
    local success, result = pcall(function()
        local sanitized_text = ""
        for _, char in utf8.codes(text or "") do
            local valid_char = utf8.char(char)
            sanitized_text = sanitized_text .. (valid_char or "?") -- Ersetze ungültige Zeichen
        end
        return sanitized_text
    end)
    return success and result or ""
end





-- Track the button being edited
local editingButton = nil
local editingButtonIndex = nil
local inputBuffer = ""
-- Funktion zum Ersetzen typografischer Apostrophe in den Textfeldern
local function replace_typographic_apostrophes()
    widgets.input.field1.text = widgets.input.field1.text:gsub("′", "'"):gsub("’", "'")
    widgets.input.field2.text = widgets.input.field2.text:gsub("′", "'"):gsub("’", "'")
end

if not widgets.input.field4 then
    widgets.input.field4 = { text = "" }
end

local showPlaceholders = false  -- Default to show placeholders initially
---------------------------------------
------------------------------
------------------------------------
local function loop()
    reaper.ImGui_PushFont(ctx, font)

    -- Adjust window size dynamically
    if buttonsCreated then
        ImGui.SetNextWindowSize(ctx, 1300, 620)  -- Extended size if buttons are created
    else
        ImGui.SetNextWindowSize(ctx, 1300, 320)  -- Standard size otherwise
    end

    local visible, open = ImGui.Begin(ctx, "ReaLy" .. version, true, window_flags)
    if visible then
        -- Define window component styles
        ImGui.PushStyleColor(ctx, ImGui.Col_Border, 0xE35858F0)
        ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0x803232F0)
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, 0x803232F0)
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0xCC6868F0)
        ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, 0x803232F0)
        ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, 0x803232F0)
        ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xFFFFFFFF)

        -- Transcribe Selected Audio Button
        if ImGui.Button(ctx, 'Transcribe Selected Audio') then
            transcribe_and_update_field1()
        end
        ToolTip(ctx, "the selected audio item is transcribed with the help of whisper, choose language")

        -- Language Combo Box
        ImGui.SameLine(ctx)
        ImGui.SetNextItemWidth(ctx, 40)
        if ImGui.BeginCombo(ctx, "##language", selectedLanguage) then
            for i, language in ipairs(availableLanguages) do
                local isSelected = (selectedLanguage == language)
                if ImGui.Selectable(ctx, language, isSelected) then
                    selectedLanguage = language
                end
                if isSelected then
                    ImGui.SetItemDefaultFocus(ctx)
                end
            end
            ImGui.EndCombo(ctx)
        end
        ToolTip(ctx, "select language")

        -- Model Combo Box
        ImGui.SameLine(ctx)
        ImGui.SetNextItemWidth(ctx, 58)
        if ImGui.BeginCombo(ctx, "##model", selectedModel) then
            for i, model in ipairs(availableModels) do
                local isSelected = (selectedModel == model)
                if ImGui.Selectable(ctx, model, isSelected) then
                    selectedModel = model
                end
                if isSelected then
                    ImGui.SetItemDefaultFocus(ctx)
                end
            end
            ImGui.EndCombo(ctx)
        end
        ToolTip(ctx, "select model")

        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, 'Import empty item notes') then
            import_selected_empty_items()
        end

        ImGui.PopStyleColor(ctx, 7)
        ImGui.SameLine(ctx)

        ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0x444141c6)
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0x444141c6)
        ImGui.SameLine(ctx)

        -- Toggle Button for Syllable Splitting and Restoring
        if ImGui.Button(ctx, split_state and "Unsplit" or "Split", 80, 20) then
            if split_state then
                unsplit_field1()
            else
                split_syllables_field1(selectedLanguage)
            end
            split_state = not split_state
        end
        ToolTip(ctx, "split with pyphen select language")

        ImGui.SameLine(ctx)
        reaper.ImGui_InvisibleButton(ctx, "#a", 60, 20, 1)
        ImGui.SameLine(ctx)

        -- Syllable Buttons
        if ImGui.Button(ctx, 'Syl##1', 30, 20) then
            widgets.input.field2.text = countSyllablesPerLine(widgets.input.field1.text)
        end
        ToolTip(ctx, "count syllables")
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, 'Syl##2', 30, 20) then
            widgets.input.field3.text = countSyllablesPerLine(widgets.input.field4.text)
        end
        reaper.ImGui_SameLine(ctx)
        if ImGui.Button(ctx, 'Translate Field1 to German',180,20) then
            translate_text_to_german()
        end
        ToolTip(ctx, "Translate English text in Field1 to German and place it in Field4")
        ImGui.PopStyleColor(ctx, 2)

        -- Scrollable Text Fields Area
        local child_flags = ImGui.WindowFlags_HorizontalScrollbar
        local size_w = 0.0
        local size_h = 200

        if ImGui.BeginChild(ctx, "TextFieldsScrollableRegion", size_w, size_h, 1, child_flags) then
            ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, 0x444141c6)
            ImGui.SameLine(ctx)

            -- Text Field 1
            local rv1, newText1 = ImGui.InputTextMultiline(ctx, '##field1', widgets.input.field1.text, 574, ImGui.GetTextLineHeight(ctx) * 50)
            if rv1 then
                newText1 = newText1:gsub("′", "'"):gsub("’", "'")
                widgets.input.field1.text = newText1
            end

            ImGui.SameLine(ctx)
            -- Text Field 2
            local rv2, newText2 = ImGui.InputTextMultiline(ctx, '##field2', widgets.input.field2.text, 30, ImGui.GetTextLineHeight(ctx) * 50)
            if rv2 then
                widgets.input.field2.text = newText2
            end

            ImGui.PopStyleColor(ctx)
            ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, 0x444141c6)

            ImGui.SameLine(ctx)
            local rv3, newText3 = ImGui.InputTextMultiline(ctx, '##field3', widgets.input.field3.text, 30, ImGui.GetTextLineHeight(ctx) * 50)
            if rv3 then
                widgets.input.field3.text = newText3
            end

            ImGui.SameLine(ctx)
            local text_field4 = widgets.input.field4.text or ""
            
            -- Prüfe, ob der Text gültig ist
            if not utf8.len(text_field4) then
                text_field4 = "Ungültige Eingabe"
            end
            
            -- Bereinige den Text
            text_field4 = safe_utf8_codes(text_field4)
            
            -- Übergib den bereinigten Text an ImGui
            local rv4, newText4 = ImGui.InputTextMultiline(ctx, '##field4', text_field4, 574, ImGui.GetTextLineHeight(ctx) * 50)
            if rv4 then
                newText4 = safe_utf8_codes(newText4 or "")
                widgets.input.field4.text = newText4:gsub("′", "'"):gsub("’", "'")
            end
            

            ImGui.PopStyleColor(ctx)
            ImGui.EndChild(ctx)
        end

        -- Button to transfer text to an empty item
        ImGui.PushStyleColor(ctx, ImGui.Col_Border, 0x3F3F3FFF)
        ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0x1A6E19AA)
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0xFFFFFFFF)

        if ImGui.Button(ctx, 'text to empty item') then
            if widgets.input and widgets.input.field1 and widgets.input.field1.text then
                local selectedItem = reaper.GetSelectedMediaItem(0, 0)
                if selectedItem then
                    local itemStart = reaper.GetMediaItemInfo_Value(selectedItem, "D_POSITION")
                    local itemLength = reaper.GetMediaItemInfo_Value(selectedItem, "D_LENGTH")
                    local emptyItem = create_empty_item_on_lyrics_track(itemStart, itemLength)
                    if emptyItem then
                        write_text_to_item_notes(emptyItem, widgets.input.field1.text)
                    end
                else
                    reaper.ShowMessageBox("No item selected!", "Error", 0)
                end
            else
                reaper.ShowMessageBox("No text entered!", "Error", 0)
            end
        end
        
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, 'lyrics_to_html') then
            if widgets.input and widgets.input.field1.text then
                write_text_to_html(widgets.input.field1.text)
            else
                reaper.ShowMessageBox("No text entered!", "Error", 0)
            end
        end
        reaper.ImGui_PopStyleColor(ctx, 3)
        ToolTip(ctx, "send your lyrics to your mobile device")

        -- Button to create placeholders from text in `field1`
        ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0x302F2FC6)
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0x302F2FC6)
        if ImGui.Button(ctx, 'Make Buttons from Text') then
            -- Generate buttons from the text in field1
            widgets.buttons.placeholders = makeButtonsFromWords(widgets.input.field1.text)
        
            -- Initialize the synonym index for each button
            for _, buttonLine in ipairs(widgets.buttons.placeholders) do
                for _, button in ipairs(buttonLine) do
                    button.synonym_index = 1  -- Set the index to 1 for each synonym
                    button.synonyms = {}  -- Initialize an empty list for synonyms
                end
            end
        
            showStyleAndCopyButtons = true
            buttonsCreated = true  -- Set status to true once buttons are created
        end
        ImGui.SameLine(ctx)
        
        
        
        ImGui.PopStyleColor(ctx, 2)

        -- Show the style and copy buttons if buttons have been created
        if showStyleAndCopyButtons then
        ImGui.PushStyleColor(ctx, ImGui.Col_Border, 0x302F2FC6)
        ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0x302F2FC6)
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0x302F2FC6)
        ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, 0x302F2FC6)
            if ImGui.Button(ctx, 'Buttontext to Field1') then
                copyButtonsToField1()
            end
            reaper.ImGui_SameLine(ctx)
            ImGui.Text(ctx, "    Style:")
            ImGui.SameLine(ctx)
            

            ImGui.SetNextItemWidth(ctx, 200)
            local styleChanged, newStyle = ImGui.InputText(ctx, "##style_input", styleBuf)
            if styleChanged then
                styleBuf = newStyle
            end

            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, 'Copy text buttons to clipboard for chatgpt') then
                copyPlaceholdersToClipboard()
            end
            if ImGui.Button(ctx, showPlaceholders and "Hide Placeholders" or "Show Placeholders") then
                showPlaceholders = not showPlaceholders  -- Toggle the visibility state
            end
            ImGui.PopStyleColor(ctx, 4)
        end
        
        
        --------------------------------------------------------------------------
        -----------------------------------------------------------------------
        
        
        
        -- Editable Buttons Region (only if buttons are created)
        if buttonsCreated then
        
        
           
                   
            ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 2, 1)
            ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 2)
        
            local button_child_flags = ImGui.WindowFlags_HorizontalScrollbar
            local button_size_w = 0.0
            local button_size_h = 300
       
            if ImGui.BeginChild(ctx, "ButtonScrollableRegion", button_size_w, button_size_h, 1, button_child_flags) then
                for lineIndex, buttonLine in ipairs(widgets.buttons.placeholders) do
                    for buttonIndex, button in ipairs(buttonLine) do
                        -- Inline Editing for Wordline Buttons
                        if editingButton == button and editingButtonIndex == buttonIndex then
                            -- Render an InputText field to edit the button label
                            local retval, newLabel = ImGui.InputText(ctx, '##edit_' .. lineIndex .. '_' .. buttonIndex, button.label, ImGui.InputTextFlags_EnterReturnsTrue)
                           if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Enter()) and not ImGui.IsItemActive(ctx) then
                                   editingButton = nil  -- Exit edit mode
                                   editingButtonIndex = nil
                               end
                           if retval then
                                  -- If Enter is pressed
                                  if newLabel == "" then
                                      -- Remove the button if the label is empty
                                      table.remove(buttonLine, buttonIndex)
                                      -- Remove line if it’s empty
                                      if #buttonLine == 0 then
                                          table.remove(widgets.buttons.placeholders, lineIndex)
                                      end
                                  else
                                      -- Split the label by spaces and hyphens
                                      local parts = {}
                                      for part in newLabel:gmatch("[^%s%-]+") do
                                          if newLabel:find("%-" .. part) then
                                              part = "-" .. part
                                          end
                                          table.insert(parts, part)
                                      end
                                      if #parts > 1 then
                                          -- Replace the original button with split parts
                                          table.remove(buttonLine, buttonIndex)
                                          for i, part in ipairs(parts) do
                                              table.insert(buttonLine, buttonIndex + i - 1, {
                                                  label = part,
                                                  length = ImGui.CalcTextSize(ctx, part) + 8,
                                                  placeholder = part,  -- Sync placeholder with label
                                                  state = 0
                                              })
                                          end
                                      else
                                          -- If no split, update the label directly
                                          button.label = newLabel
                                          button.length = ImGui.CalcTextSize(ctx, newLabel) + 8
                                          button.placeholder = newLabel  -- Sync placeholder with label
                                      end
                                  end
                                  editingButton = nil  -- Exit edit mode
                                  editingButtonIndex = nil
                              end
       
                           -- Exit edit mode if input is deactivated (e.g., clicking outside)
                               if ImGui.IsItemDeactivated(ctx) then
                                   editingButton = nil
                                   editingButtonIndex = nil
                               end
                           
                        else
                            -- Normal Button Rendering
                            ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0x2A2A2AFF)
                            ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0x222222C6)
                            ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xFFFFFFFF)

                            -- Check for labels that start with a hyphen and adjust spacing accordingly
                           
                            -- Wenn das Label mit einem Bindestrich beginnt, setze den Cursor näher an den Rand
                            if button.label:sub(1, 1) == "-" then
                                local posX, posY = ImGui.GetCursorPos(ctx)
                                ImGui.SetCursorPos(ctx, posX - 4, posY)  -- Den linken Rand um 4 Pixel nach links verschieben
                            end
                            local buttonClicked = ImGui.Button(ctx, button.label .. '##' .. lineIndex .. '_' .. buttonIndex, button.length, 19)
                            if buttonClicked then
                                editingButton = button
                                editingButtonIndex = buttonIndex
                            end
       
                            -- Alt + Left Click to delete button
                            if reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftAlt()) and ImGui.IsItemClicked(ctx, 0) then
                                table.remove(buttonLine, buttonIndex)
                                -- Remove line if it’s empty after deletion
                                if #buttonLine == 0 then
                                    table.remove(widgets.buttons.placeholders, lineIndex)
                                end
                            end
       
                            -- Right-click to show synonyms in a separate window
                            if ImGui.IsItemClicked(ctx, 1) then
                                selectedButton = button
                                synonymsList = get_synonyms_with_nltk(button.label)  -- Retrieve synonyms for the word
                                showSynonymWindow = true
                            end
       
                            ImGui.PopStyleColor(ctx, 3)
                        end
                        ImGui.SameLine(ctx)
                    end
                    ImGui.NewLine(ctx)
       
                    if showPlaceholders then
                                        for buttonIndex, button in ipairs(buttonLine) do
                                            ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0x302F2FC6)
                                            ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0x302F2FC6)
                                            if ImGui.Button(ctx, button.placeholder .. '##placeholder' .. lineIndex .. '_' .. buttonIndex, button.length, 19) then
                                                if button.placeholder == "" then
                                                    button.placeholder = button.label
                                                else
                                                    button.placeholder = ""
                                                end
                                            end
                                            ImGui.PopStyleColor(ctx, 2)
                                            ImGui.SameLine(ctx)
                                        end
                                    end
       
                    -- Add rhyme group color button at the end of each line
                    ImGui.SameLine(ctx)
                    if buttonLine[1] then
                        local color = stateColors[buttonLine[1].state]
                        local colorU32 = packColor(color[1], color[2], color[3], color[4])
                        ImGui.PushStyleColor(ctx, ImGui.Col_Button, colorU32)
                        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, colorU32)
       
                        if ImGui.Button(ctx, '##stateButton' .. lineIndex, 20, 18) then
                            for _, button in ipairs(buttonLine) do
                                button.state = (button.state + 1) % 5
                            end
                        end
                        ToolTip(ctx, "rhyme group")
                        ImGui.PopStyleColor(ctx, 2)
                    end
       
                    ImGui.Dummy(ctx, 0, 4)
                end
                ImGui.EndChild(ctx)
            end
       
            ImGui.PopStyleVar(ctx, 2)
        end

        if showSynonymWindow and selectedButton then
            -- Add the NoDocking and AlwaysOnTop flags to window_flags
            local window_flags = reaper.ImGui_WindowFlags_NoDocking() |
                                 reaper.ImGui_WindowFlags_AlwaysAutoResize() |
                                 reaper.ImGui_WindowFlags_NoCollapse() |
                                 reaper.ImGui_WindowFlags_TopMost()
        
            -- Fokussiere das Fenster, um sicherzustellen, dass es oben bleibt
            reaper.ImGui_SetNextWindowFocus(ctx)
        
            -- Begin the synonym selection window
            local synonymVisible, synonymOpen = ImGui.Begin(ctx, "Select Synonym", showSynonymWindow, window_flags)
        
            -- Update showSynonymWindow if the window is closed
            showSynonymWindow = synonymOpen
        
            if synonymVisible then
                ImGui.Text(ctx, "Select a synonym for: " .. (selectedButton.label or ""))
        
                ImGui.Separator(ctx) -- Optional: fügt eine Linie zur Trennung hinzu
        
                for _, synonym in ipairs(synonymsList) do
                    if ImGui.Button(ctx, synonym) then
                        -- Update label and placeholder with the selected synonym
                        selectedButton.label = synonym
                        selectedButton.placeholder = synonym  -- Sync placeholder with synonym
                        selectedButton.length = ImGui.CalcTextSize(ctx, synonym) + 8
                        showSynonymWindow = false -- Close the window
                        selectedButton = nil
                    end
                end 
                ImGui.End(ctx)
            end
        end
        
        

        -- End main window
        ImGui.End(ctx)
    end

    reaper.ImGui_PopFont(ctx)
    if open then
        reaper.defer(loop)
    end
end

reaper.defer(loop)

