script_name('Helper Kit')
script_version('1')
script_author('Evan West')

local mad = require('MoonAdditions')
local sampev = require 'lib.samp.events'

local events = require('samp.events')

imgui, handle = require('imgui'), PLAYER_HANDLE

local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local dictPath = 'moonloader\\config\\helper-kit\\dict.json'
local dict = {}

local locationsPath = 'moonloader\\config\\helper-kit\\locations.json'
local locations = {}

local checkpoint, blip

function getMatch(a, kw)
    kw = kw:lower():gsub(' ', ''):gsub('-', '')
    local bm, bmd
    for _, e in ipairs(a) do
        if e.keywords and type(e.keywords) == 'table' then
            for _, ekw in ipairs(e.keywords) do
                local ekws = ekw:lower():gsub(' ', ''):gsub('-', '')
                if kw == ekws:sub(1, #kw) then
                    local d = math.abs(#kw - #ekws)
                    if bmd == nil or d < bmd then
                        bmd = d
                        bm = e
                    end
                end
            end
        end
    end
    return bm
end

function numWithCommas(n)
    return tostring(math.floor(n)):reverse():gsub("(%d%d%d)","%1,"):gsub(",(%-?)$","%1"):reverse()
end

function clearCheckpoint()
    if blip ~= nil then
        removeBlip(blip)
        blip = nil
    end
    if checkpoint ~= nil then
        deleteCheckpoint(checkpoint)
        checkpoint = nil
    end
end

function cmdDef(kw)
    if #kw == 0 then
        sampAddChatMessage('USAGE: (/def)ine [query]', 0xAFAFAF)
        return
    end
    local bm = getMatch(dict, kw)
    if bm == nil then
        sampAddChatMessage('No match found.', -1)
        return
    end
    local msgt = {bm.keywords[1]}
    for n, v in pairs(bm) do
        if n == 'keywords' then goto continue end
        table.insert(msgt, string.format('%s: %s', n:sub(1, 1):upper() .. n:sub(2, #n), v))
        ::continue::
    end
    local msg = ''
    for i, v in pairs(msgt) do
        msg = msg .. v
        if i == #msgt then goto continue end
        msg = msg .. ' | '
        ::continue::
    end
    msgt = nil
    while #msg > 144 do
        sampAddChatMessage(msg:sub(1, 144), -1)
        msg = '-..' .. msg:sub(145, #msg)
    end
    sampAddChatMessage(msg, -1)
end

function cmdLoc(kw)
    if #kw == 0 then
        sampAddChatMessage('USAGE: (/loc)ate [query]', 0xAFAFAF)
        return
    end
    local bm = getMatch(locations, kw)
    if bm == nil then
        sampAddChatMessage('No match found.', -1)
        return
    end
    clearCheckpoint()
    blip = addBlipForCoord(bm.X, bm.Y, bm.Z)
    setCoordBlipAppearance(blip, 2)
    checkpoint = createCheckpoint(2, bm.X, bm.Y, bm.Z, bm.X, bm.Y, bm.Z, 15)
    lua_thread.create(function()
        while checkpoint ~= nil or blip ~= nil do
            local cx, cy, cz = getCharCoordinates(PLAYER_PED)
            if getDistanceBetweenCoords3d(cx, cy, cz, bm.X, bm.Y, bm.Z) <= 15 then
                clearCheckpoint()
                addOneOffSound(cx, cy, cz, 1058)
                break
            end
            wait(100)
        end
    end)
    sampAddChatMessage(string.format('Follow the checkpoint to %s.', bm.keywords[1]), -1)
end

function cmdLvl(level)
    level = tonumber(level)
    if level == nil or level < 2 then
        sampAddChatMessage('USAGE: /lvl [n>=2]', 0xAFAFAF)
        return
    end
    local rp = 8 + (level - 2) * 4
    local mon = 5000 + (level - 2) * 2500
    local rpsum = (level - 1) * (8 + rp) / 2
    local monsum = (level - 1) * (5000 + mon) / 2
    sampAddChatMessage(string.format("{33CCFF}Level %s:{FFFFFF} %s respect points + $%s | {33CCFF}Total:{FFFFFF} %s respect points + $%s",
        numWithCommas(level),
        numWithCommas(rp),
        numWithCommas(mon),
        numWithCommas(rpsum),
        numWithCommas(monsum)
    ), -1)
end

function cmdN(msg)
    if #msg == 0 then
        sampAddChatMessage('USAGE: (/n)ewbie [text]', 0xAFAFAF)
        return
    end
    sampSendChat('/newb ' .. msg)
end

function cmdHrs()
    sampSendChat('/helprequests')
end

function cmdAhr(params)
    if #params == 0 then
        sampAddChatMessage('USAGE: (/a)ccept(h)elp(r)equest [playerid]', 0xAFAFAF)
        return
    end
    sampSendChat('/accepthelp ' .. params)
end

function cmdLvl1s()
    local lvl1s = {}
    for id = 0, sampGetMaxPlayerId(false), 1 do
        if sampIsPlayerConnected(id) then
            if sampGetPlayerScore(id) == 1 then
                if string.find(sampGetPlayerNickname(id), '_') then
                    table.insert(lvl1s, id)
                end
            end
        end
    end     
    if #lvl1s == 0 then
        sampAddChatMessage('No level 1 player is online, but this may be a mistake. Try pressing TAB and waiting a few moments.', -1)
        return
    end
    sampAddChatMessage('Level 1 Players Online:', 0xFFA500)
    local final = {}
    local team = {}
    local r = 1
    for i, id in pairs(lvl1s) do
        if r == 4 then
            r = 1
            table.insert(final, team)
            team = {}
        end
        table.insert(team, string.format('{33CCFF}(%i){FFFFFF} %s', id, string.gsub(sampGetPlayerNickname(id), '_', ' ')))
        r = r + 1
    end
    for i, team in pairs(final) do
        sampAddChatMessage(table.concat(team, " | "), -1)
    end
end

function cmdHkhelp()
    sampAddChatMessage('_______________________________________', 0x33CCFF)
    sampAddChatMessage('*** HELPER KIT HELP *** - type a command for more infomation.', -1)
    sampAddChatMessage('*** HELPER KIT ALL *** /def /loc /lvl /n /hrs /lvl1s', 0xCBCCCE)
    sampAddChatMessage('*** HELPER KIT SENIORS *** /en /ahr', 0xCBCCCE)
end

local Settings = {
    Visible = false,
    Type = 'Location'
}

local searchQuery = imgui.ImBuffer(256)

function imgui.OnDrawFrame()
    width, height = getScreenResolution()
    local windowWidth, windowHeight = 600, 500

    local Alignments = {
        Left = windowWidth / 14,
        Middle = windowWidth / 2,
        Right = (windowWidth / 14) * 13
    }

    imgui.SetNextWindowPos(imgui.ImVec2(width / 2, height / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(windowWidth, windowHeight), imgui.Cond.FirstUseEver)
    imgui.ColorConvertHSVtoRGB(44, 107, 243)
    imgui.Begin(u8("Helper-Kit Definition/Location"), Settings.Visible, imgui.WindowFlags.NoResize)

    imgui.Text(u8("Search:"))
    imgui.SameLine()
    imgui.InputText(u8("##search"), searchQuery)

    local query = searchQuery.v:lower()
    
    if Settings.Type == 'Location' then
        for _, entry in pairs(locations) do
            if type(entry) == 'table' and type(entry.keywords) == 'table' then
                for _, val in ipairs(entry.keywords) do
                    if query == "" or val:lower():find(query) then
                        local textWidth = imgui.CalcTextSize('Locate').x
                        imgui.SetCursorPosX(Alignments.Middle - textWidth / 2)
                        if imgui.Button(u8"Locate##" .. val) then
                            lua_thread.create(function()
                                cmdLoc(val)
                                wait(1000)
                            end)
                        end
                        imgui.NewLine()
                        local textWidth = imgui.CalcTextSize(val).x
                        imgui.SetCursorPosX(Alignments.Middle - textWidth / 2)
                        imgui.Text(val)
                        imgui.NewLine()
                        local divider = '______________________________________________________________________________'
                        local textWidth = imgui.CalcTextSize(divider).x
                        imgui.SetCursorPosX(Alignments.Middle - textWidth / 2)
                        imgui.TextColored(imgui.ImVec4(1.0,1.0,0.0,1.0), divider)
                        imgui.NewLine()
                    end
                end
            end
        end
    else
        for _, entry in pairs(dict) do
            if type(entry) == 'table' and type(entry.keywords) == 'table' then
                local keywordsMatch = false
                local desc = ""
                local first = true
                
                for k, v in pairs(entry) do
                    if k ~= "keywords" then
                        if not first then
                            desc = desc .. ' | '
                        end
                        desc = desc .. k .. ': ' .. v
                        first = false
                    end
                end
        
                local descMatch = query == "" or desc:lower():find(query)
        
                for _, val in ipairs(entry.keywords) do
                    if query == "" or val:lower():find(query) then
                        keywordsMatch = true
                        break
                    end
                end
        
                if keywordsMatch or descMatch then
                    for _, val in ipairs(entry.keywords) do
                        local textWidth = imgui.CalcTextSize(val).x
                        imgui.SetCursorPosX(Alignments.Middle - textWidth / 2)
                        imgui.TextColored(imgui.ImVec4(0.0, 1.0, 0.0, 0.6), val)
                    end

                    local MinimumText, SecondMinumumText = 95, 96
                    
                    while #desc > MinimumText do
                        imgui.Text(desc:sub(1, MinimumText), -1)
                        desc = '-..' .. desc:sub(SecondMinumumText, #desc)
                    end
        
                    local textWidth = imgui.CalcTextSize(desc).x
                    imgui.SetCursorPosX(Alignments.Middle - textWidth / 2)
                    imgui.Text(desc)
                    
                    local divider = '______________________________________________________________________________'
                    local textWidth = imgui.CalcTextSize(divider).x
                    imgui.SetCursorPosX(Alignments.Middle - textWidth / 2)
                    imgui.TextColored(imgui.ImVec4(1.0, 1.0, 0.0, 1.0), divider)
                    imgui.NewLine()
                end
            end
        end
        
        
    end
    

    imgui.NewLine()
    imgui.NewLine()
    imgui.Text('Discord: cjkamii/Kami#7661')
    imgui.End()
end

function cmdaddloc(Arg)
    if #Arg == 0 then
        sampAddChatMessage('USAGE: (/addloc)ation [Location]', 0xAFAFAF)
        return
    end

    local result1, Ped = getPlayerChar(handle)
    local result2, PlayerID = sampGetPlayerIdByCharHandle(Ped)
    local positionX, positionY, positionZ = getCharCoordinates(Ped)
    local City = getCityFromCoords(positionX,positionY,positionZ)
    local Zone = getNameOfZone(positionX,positionY,positionZ)	

    local Locations = {}

    local fileopen = io.open(locationsPath, "r")
    if fileopen then
           local fileContent = fileopen:read("*a")
        Locations = decodeJson(fileContent)
        fileopen:close()
    else
        sampAddChatMessage('Failed to open Locations.JSON for reading', 0xFFFFFF)
        return
    end

    local newData = {
        keywords = { Arg },
        X = positionX,
        Y = positionY,
        Z = positionZ
    }

    table.insert(Locations, newData)

    local file = io.open(locationsPath, "w")
    if file then
        file:write(encodeJson(Locations))  -- Write entire updated table to the file
        file:close()  -- Close the file
        sampAddChatMessage('[Helper] {FFFFFF}Location Appended', 0xFF9E00)
    else
        sampAddChatMessage('[Helper] {FFFFFF}Location failed to Appended', 0xFF9E00)
    end
end


function main()
    while not isSampAvailable() do wait(100) end
    local f = io.open(dictPath, 'rb')
    if f ~= nil then
        dict = decodeJson(f:read('*a'))
        f:close()
        f = nil
    end
    f = io.open(locationsPath, 'rb')
    if f ~= nil then
        locations = decodeJson(f:read('*a'))
        f:close()
        f = nil
    end
    sampRegisterChatCommand('def', cmdDef)
    sampRegisterChatCommand('loc', cmdLoc)
    sampRegisterChatCommand('hloc', function()
        Settings.Visible = not Settings.Visible
        Settings.Type = 'Location'
		imgui.Process = Settings.Visible
    end)
    sampRegisterChatCommand('hdef', function()
        Settings.Visible = not Settings.Visible
        Settings.Type = 'Definition'
		imgui.Process = Settings.Visible
    end)
    sampRegisterChatCommand('addloc', cmdaddloc)
    sampRegisterChatCommand('n', cmdN)
    sampRegisterChatCommand('hrs', cmdHrs)
    sampRegisterChatCommand('ahr', cmdAhr)
    sampRegisterChatCommand('hkhelp', cmdHkhelp)
    sampRegisterChatCommand('lvl1s', cmdLvl1s)
    while true do wait(100) end
end

function events.onSendCommand(command)
    local cl = command:lower()
    if cl:sub(1, 4) == '/kcp' or cl:sub(1, 15) == '/killcheckpoint' then
        clearCheckpoint()
    end
end