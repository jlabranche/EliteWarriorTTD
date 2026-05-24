local lastCheckTime = 0;
local checkInterval = 0.2;
EliteWarrior = EliteWarrior or {}
EliteWarriorTTDDB = EliteWarriorTTDDB or {}

local defaultPosition = {
    point = "BOTTOMLEFT",
    relativePoint = "BOTTOMLEFT",
    x = math.floor(GetScreenWidth() * 0.475),
    y = math.floor(GetScreenHeight() * 0.21)
}

local function GetTTDPosition()
    return EliteWarriorTTDDB.position or defaultPosition
end

local ttdAnchor = CreateFrame("Frame", "EliteWarriorTTDAnchor", UIParent)
ttdAnchor:SetWidth(220)
ttdAnchor:SetHeight(120)
ttdAnchor:SetMovable(true)
ttdAnchor:EnableMouse(true)
ttdAnchor:RegisterForDrag("LeftButton")
ttdAnchor:SetClampedToScreen(true)

local pos = GetTTDPosition()
ttdAnchor:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)

ttdAnchor:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

ttdAnchor:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()

    local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
    EliteWarriorTTDDB.position = {
        point = point,
        relativePoint = relativePoint,
        x = xOfs,
        y = yOfs
    }
end)

EliteWarrior.TTD = CreateFrame("Frame", nil, UIParent);


local inCombat = false;

local textTimeTillDeath = UIParent:CreateFontString(nil,"OVERLAY","GameTooltipText")
textTimeTillDeath:SetFont("Fonts\\FRIZQT__.TTF", 99, "OUTLINE, MONOCHROME")
local textTimeTillDeathText = UIParent:CreateFontString(nil,"OVERLAY","GameTooltipText")
textTimeTillDeathText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE, MONOCHROME")

-- Globals Section
local timeSinceLastUpdate = 0;
local combatStart = GetTime();

local function TTD_Show()
    if (inCombat) then
        textTimeTillDeath:ClearAllPoints()
        textTimeTillDeath:SetPoint("BOTTOMLEFT", ttdAnchor, "BOTTOMLEFT", 0, 0)

        textTimeTillDeathText:ClearAllPoints()
        textTimeTillDeathText:SetPoint("BOTTOMLEFT", ttdAnchor, "BOTTOMLEFT", 0, 28)

        textTimeTillDeathText:SetText("Time Till Death:")
    end
end

local function TTD_Hide()
    textTimeTillDeath:SetText("-.--");
end

-- TTD stands for Time Till Death
local function TTDLogic()
    if UnitIsEnemy("player","target") or UnitReaction("player","target") == 4 then
        local EHealthPercent = UnitHealth("target")/UnitHealthMax("target")*100;
        if EHealthPercent == 100 then
            if targetName ~= 'Spore' and targetName ~= 'Fallout Slime' and targetName ~= 'Plagued Champion' then
                -- may not want to restart combat if you tab to one of these monsters
                combatStart = GetTime();
            end
        end;
        if EHealthPercent then
            local maxHP     = UnitHealthMax("target");
            local targetName = UnitName("target");
            if targetName == 'Vaelastrasz the Corrupt' then
                maxHP = UnitHealthMax("target")*0.3;
            end;
            local curHP     = UnitHealth("target");
            local missingHP = maxHP - curHP;
            local seconds   = timeSinceLastUpdate - combatStart; -- current length of the fight
            remainingSeconds = (maxHP/(missingHP/seconds)-seconds)*0.90; -- Should prob make it count the number of warriors in the raid
            if (remainingSeconds ~= remainingSeconds) then
                textTimeTillDeath:SetText("-.--")
            else
                if (remainingSeconds) then
                    textTimeTillDeath:SetText(string.format("%.2f",remainingSeconds));
                end
            end
        end
    end
end

function onUpdate(sinceLastUpdate)
    timeSinceLastUpdate = GetTime();
    if GetTime()-lastCheckTime >= checkInterval then
        if (lastCheckTime == 0) then
            lastCheckTime = GetTime();
        end
        TTDLogic();

        lastCheckTime = 0;
    end
end
EliteWarrior.TTD:SetScript("OnUpdate", function(self) if inCombat then onUpdate(timeSinceLastUpdate); end; end);

EliteWarrior.TTD:SetScript("OnShow", function(self)
    timeSinceLastUpdate = 0
end)


EliteWarrior.TTD:SetScript("OnEvent", function()
    if event == "PLAYER_REGEN_DISABLED" then
        combatStart = GetTime();
        inCombat = true;
        TTD_Show();
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false;
        combatStart = GetTime();
        TTD_Hide();
        combatStart = GetTime();
        textTimeTillDeathText:SetText("");
    elseif event == "PLAYER_DEAD" then
        inCombat = false;
    end
end);

SLASH_ELITEWARRIORTTD1 = "/ttd"

SlashCmdList["ELITEWARRIORTTD"] = function(msg)
    if msg == "lock" then
        ttdAnchor:EnableMouse(false)
        print("EliteWarriorTTD locked. Click-through enabled.")
    elseif msg == "unlock" then
        ttdAnchor:EnableMouse(true)
        print("EliteWarriorTTD unlocked. Drag the timer text to move it.")
    elseif msg == "reset" then
        EliteWarriorTTDDB.position = nil
        ttdAnchor:ClearAllPoints()
        ttdAnchor:SetPoint(defaultPosition.point, UIParent, defaultPosition.relativePoint, defaultPosition.x, defaultPosition.y)
        print("EliteWarriorTTD position reset")
    else
        print("/ttd unlock")
        print("/ttd lock")
        print("/ttd reset")
    end
end

EliteWarrior.TTD:RegisterEvent("PLAYER_REGEN_ENABLED");
EliteWarrior.TTD:RegisterEvent("PLAYER_REGEN_DISABLED");
EliteWarrior.TTD:RegisterEvent("PLAYER_DEAD");