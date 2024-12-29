-- @name: edit item with touchscreen
-- @version 1.0.0
-- @author Dragonetti
local is_dragging = false
local initial_mouse_x = nil
local initial_length = {}
local selected_items = {}
local selected_items_data = {}
local edge_to_edit = nil -- "left" oder "right", um festzulegen, welche Kante/Fade bearbeitet wird
local edit_mode = nil -- "edges", "fades" oder "volume", um den Bearbeitungsmodus festzulegen

-- Funktion: Prüfen, ob Raster aktiviert ist
function is_grid_enabled()
    local snap_enabled = reaper.GetToggleCommandState(1157) == 1 -- 1157 = "Snap/grid enabled"
    return snap_enabled
end

-- Funktion: Nur aktive Kante auf Raster runden
function round_active_edge_to_grid(data, edge)
    if not is_grid_enabled() then return end -- Raster ist deaktiviert, keine Rundung

    if edge == "left" then
        -- Linke Kante: Position runden
        local current_position = reaper.GetMediaItemInfo_Value(data.item, "D_POSITION")
        local rounded_position = reaper.BR_GetClosestGridDivision(current_position)
        local position_diff = rounded_position - current_position
        local new_length = reaper.GetMediaItemInfo_Value(data.item, "D_LENGTH") - position_diff
        if new_length > 0 then
            reaper.SetMediaItemInfo_Value(data.item, "D_POSITION", rounded_position)
            reaper.SetMediaItemInfo_Value(data.item, "D_LENGTH", new_length)

            -- Startoffset anpassen
            if data.take then
                local current_startoffs = reaper.GetMediaItemTakeInfo_Value(data.take, "D_STARTOFFS")
                reaper.SetMediaItemTakeInfo_Value(data.take, "D_STARTOFFS", current_startoffs + position_diff)
            end
        end
    elseif edge == "right" then
        -- Rechte Kante: Länge runden
        local current_position = reaper.GetMediaItemInfo_Value(data.item, "D_POSITION")
        local current_length = reaper.GetMediaItemInfo_Value(data.item, "D_LENGTH")
        local end_position = current_position + current_length
        local rounded_end = reaper.BR_GetClosestGridDivision(end_position)
        local new_length = rounded_end - current_position
        if new_length > 0 then
            reaper.SetMediaItemInfo_Value(data.item, "D_LENGTH", new_length)
        end
    end
end

-- Funktion: Nach dem Drag auf Raster springen
function snap_items_to_grid()
    for i, item in ipairs(selected_items) do
        local data = selected_items_data[i]
        if edit_mode == "edges" then
            round_active_edge_to_grid(data, edge_to_edit)
        end
    end

    -- Ansicht aktualisieren
    reaper.UpdateArrange()
end

-- Funktion: Länge, Fade oder Lautstärke ändern
function adjust_item_length_or_fades()
    -- 1. Prüfen, ob Win+Alt oder Win+Ctrl gedrückt ist
    local mouse_state = reaper.JS_Mouse_GetState(0xFF)
    local ctrl_held = mouse_state & 4 > 0 -- Strg gedrückt?
    local alt_held = mouse_state & 16 > 0 -- Alt gedrückt?
    local win_held = mouse_state & 0x20 > 0 -- Win gedrückt?
    local left_button = mouse_state & 1 > 0 -- Linke Maustaste gedrückt?

    if win_held and alt_held and ctrl_held then
        edit_mode = "volume"
    elseif win_held and alt_held then
        edit_mode = "fades"
    elseif win_held and ctrl_held then
        edit_mode = "edges"
    else
        -- Reset bei Nicht-Halten der Tasten
        is_dragging = false
        initial_mouse_x = nil
        initial_length = {}
        selected_items = {}
        selected_items_data = {}
        edge_to_edit = nil
        edit_mode = nil
        reaper.defer(adjust_item_length_or_fades)
        return
    end

    -- 2. Warten auf Left-Click durch Touchscreen
    if left_button then
        -- Drag starten
        if not is_dragging then
            -- Füge eine kleine Verzögerung ein, um die Selektion zu erkennen
            reaper.defer(function()
                -- 3. Selektierte Items abfragen
                local num_items = reaper.CountSelectedMediaItems(0)
                if num_items == 0 then
                    -- Keine Items ausgewählt, nichts zu tun
                    reaper.defer(adjust_item_length_or_fades)
                    return
                end

                -- Speichere Mausposition, Länge und Position der ausgewählten Items
                initial_mouse_x = reaper.BR_PositionAtMouseCursor(false)
                selected_items = {}
                selected_items_data = {}
                for i = 0, num_items - 1 do
                    local item = reaper.GetSelectedMediaItem(0, i)
                    local start_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                    local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                    local fade_in_len = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
                    local fade_out_len = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
                    local volume = reaper.GetMediaItemInfo_Value(item, "D_VOL")
                    local take = reaper.GetActiveTake(item)
                    local startoffs = take and reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS") or 0
                    table.insert(selected_items, item)
                    table.insert(selected_items_data, {
                        item = item,
                        start = start_pos,
                        length = length,
                        fade_in_len = fade_in_len,
                        fade_out_len = fade_out_len,
                        volume = volume,
                        take = take,
                        startoffs = startoffs
                    })
                end

                -- Entscheiden, ob linke oder rechte Kante/Fade bearbeitet wird
                local mouse_position = reaper.BR_PositionAtMouseCursor(false)
                for i, data in ipairs(selected_items_data) do
                    local midpoint = data.start + (data.length / 2)
                    if mouse_position < midpoint then
                        edge_to_edit = "left"
                    else
                        edge_to_edit = "right"
                    end
                end

                is_dragging = true
                adjust_item_length_or_fades() -- Skript erneut starten
            end)
            return
        else
            -- 4. Länge, Fades oder Lautstärke durch Draggen ändern
            local current_mouse_x = reaper.BR_PositionAtMouseCursor(false)
            local drag_diff = current_mouse_x - initial_mouse_x

            for i, item in ipairs(selected_items) do
                local data = selected_items_data[i]
                if edit_mode == "edges" then
                    if edge_to_edit == "right" then
                        -- Rechte Kante anpassen: nur die Länge ändern
                        local new_length = math.max(0, data.length + drag_diff)
                        reaper.SetMediaItemInfo_Value(item, "D_LENGTH", new_length)
                    elseif edge_to_edit == "left" then
                        -- Linke Kante anpassen: Position und Länge ändern
                        local new_position = data.start + drag_diff
                        local new_length = math.max(0, data.length - drag_diff)

                        if new_length > 0 then
                            reaper.SetMediaItemInfo_Value(item, "D_POSITION", new_position)
                            reaper.SetMediaItemInfo_Value(item, "D_LENGTH", new_length)

                            -- Startoffset anpassen, falls ein Take vorhanden ist
                            if data.take then
                                local new_startoffs = data.startoffs + drag_diff
                                reaper.SetMediaItemTakeInfo_Value(data.take, "D_STARTOFFS", new_startoffs)
                            end
                        end
                    end
                elseif edit_mode == "fades" and not (win_held and alt_held and ctrl_held) then
                    if edge_to_edit == "left" then
                        -- Fade-In anpassen
                        local new_fade_in = math.max(0, data.fade_in_len + drag_diff)
                        reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", new_fade_in)
                    elseif edge_to_edit == "right" then
                        -- Fade-Out anpassen
                        local new_fade_out = math.max(0, data.fade_out_len - drag_diff)
                        reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", new_fade_out)
                    end
                elseif edit_mode == "volume" then
                    -- Lautstärke anpassen
                    local new_volume = math.max(0, data.volume + drag_diff * 0.01) -- 0.01 als Skalierungsfaktor
                    reaper.SetMediaItemInfo_Value(item, "D_VOL", new_volume)
                end
            end

            -- Ansicht aktualisieren
            reaper.UpdateArrange()
        end
    else
        -- Drag beenden
        if is_dragging then
            if edit_mode == "edges" then
                -- Nach dem Drag auf Raster springen
                snap_items_to_grid()
            end

            is_dragging = false
            initial_mouse_x = nil
            initial_length = {}
            selected_items = {}
            selected_items_data = {}
            edge_to_edit = nil
        end
    end

    -- Skript weiterlaufen lassen
    reaper.defer(adjust_item_length_or_fades)
end

-- Starte die Bearbeitung
adjust_item_length_or_fades()
