script_name("fixed wanted")
script_author("Yuki_Komori")

require 'lib.moonloader'
local imgui = require 'imgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- ============================================================
--  НАСТРОЙКИ
-- ============================================================
local RECORDINGS_FOLDER = "C:\\Users\\%USERNAME%\\Videos\\Desktop"
local LOG_FILE          = "D:\\Games\\rodina\\moonloader\\wanted_log.html"
local BAT_FILE          = "D:\\Games\\rodina\\moonloader\\open_log.bat"
-- ============================================================

local show_window = imgui.ImBool(false)
local target_id   = 0
local target_nick = ""
local accent      = imgui.ImVec4(0.35, 0.35, 0.38, 1.0)

local function moscow_time()
    local t = os.date("!*t", os.time() + 10800)
    return string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
end

local function moscow_date()
    local t = os.date("!*t", os.time() + 10800)
    return string.format("%02d.%02d.%04d", t.day, t.month, t.year)
end


local HTML_HEAD = ""
local HTML_FOOT = ""

local log_row_count = 0

local function init_log()
    local f = io.open(LOG_FILE, "r")
    if not f then return false end
    local data = f:read("*a")
    f:close()
    for _ in data:gmatch("<tr>") do
        log_row_count = log_row_count + 1
    end
    return true
end

local function write_log(nick, article, law_type, level_or_summa)
    local date = moscow_date()
    local time = moscow_time()
    local rec_folder = RECORDINGS_FOLDER:gsub("%%USERNAME%%", os.getenv("USERNAME") or "User")
    log_row_count = log_row_count + 1
    local badge, measure
    if law_type == "УК" then
        badge   = '<span class="badge-uk">УК</span>'
        measure = '<span class="stars">' .. string.rep("&#9733;", level_or_summa) .. '</span> ' .. level_or_summa
    else
        badge   = '<span class="badge-ap">КоАП</span>'
        measure = level_or_summa .. ' руб.'
    end
    local row = string.format(
        '<tr><td class="num">%d</td><td class="time-cell">%s %s</td><td class="nick">%s</td><td>%s</td><td><span class="art">%s</span></td><td>%s</td><td><a class="rec-link" href="file:///%s">&#128249; открыть</a></td></tr>\n',
        log_row_count, date, time, nick, badge, article, measure,
        rec_folder:gsub("\\", "/")
    )
    local f = io.open(LOG_FILE, "r")
    if not f then return end
    local content = f:read("*a")
    f:close()
    content = content:gsub("</tbody>", row .. "</tbody>", 1)
    local fw = io.open(LOG_FILE, "w")
    if fw then
        fw:write(content)
        fw:close()
    end
    sampAddChatMessage(u8:decode("[LOG] " .. date .. " " .. time .. " | " .. nick .. " | " .. article .. " " .. law_type), 0xFFAA00)
end

local function get_nick(id)
    local ok, nick = pcall(sampGetPlayerNickname, id)
    if ok and nick then return nick end
    return "ID_" .. tostring(id)
end

local function open_log()
    os.execute('"' .. BAT_FILE .. '"')
end

local article_sections = {
    {
        name = "Статья 1. Причинение вреда здоровью человека.",
        items = {
            {article="1.1", desc="Безоружное нападение",  level=3},
            {article="1.2", desc="Вооруженное нападение", level=4},
            {article="1.3", desc="Похищение",             level=5},
            {article="1.4", desc="Убийство",              level=6}
        }
    },
    {
        name = "Статья 2. Оружие и различное снаряжение.",
        items = {
            {article="2.1", desc="Ношение оружия в боевой готовности",  level=3},
            {article="2.2", desc="Незаконное изготовление оружия",       level=3},
            {article="2.3", desc="Незаконное хранение оружия",           level=3},
            {article="2.4", desc="Продажа патронов, оружия",             level=4}
        }
    },
    {
        name = "Статья 3. Наркотики, психотропные вещества.",
        items = {
            {article="3.1", desc="Хранение наркотических веществ",  level=5},
            {article="3.2", desc="Продажа наркотических веществ",   level=6},
            {article="3.3", desc="Приобретение/употребление",        level=1},
            {article="3.4", desc="Сбыт в особо крупном размере",     level=6}
        }
    },
    {
        name = "Статья 4. Бандитизм.",
        items = {
            {article="4.1", desc="Выдача себя за сотрудника",       level=2},
            {article="4.2", desc="Препятствие движению кортежа",    level=2},
            {article="4.3", desc="Нападение на кортеж/конвой",      level=6},
            {article="4.4", desc="Преследование служебного авто",   level=3},
            {article="4.5", desc="Угон транспорта",                  level=3},
            {article="4.6", desc="Попытка угона ТС",                 level=2},
            {article="4.7", desc="Шантаж/вымогательство",           level=4},
            {article="4.8", desc="Ограбление граждан",              level=3}
        }
    },
    {
        name = "Статья 5. Терроризм.",
        items = {
            {article="5.1", desc="Захват гос. учреждений", level=6},
            {article="5.2", desc="Захват заложников",       level=6}
        }
    },
    {
        name = "Статья 6. Коррупция.",
        items = {
            {article="6.1", desc="Дача взятки",                 level=6},
            {article="6.2", desc="Принятие взятки",             level=6},
            {article="6.3", desc="Вымогательство должностным",  level=6},
            {article="6.4", desc="Попытка дачи взятки",         level=4},
            {article="6.5", desc="Попытка получения взятки",    level=6}
        }
    },
    {
        name = "Статья 7. Охраняемые объекты и временные запреты.",
        items = {
            {article="7.1", desc="Проникновение в тюрьму/базу",           level=5},
            {article="7.2", desc="Проникновение в служебное место",        level=2},
            {article="7.3", desc="Проникновение на охраняемую территорию", level=1},
            {article="7.4", desc="Помеха строю/мероприятию",               level=2}
        }
    },
    {
        name = "Статья 8. Не выполнение законных требований.",
        items = {
            {article="8.1", desc="Невыполнение требований", level=1}
        }
    }
}

local ak_sections = {
    [1] = {
        {article="1.1", desc="Распитие спиртных напитков",    summa=20000},
        {article="1.2", desc="Курение в общественных местах", summa=15000},
        {article="1.3", desc="Нахождение в непристойном виде",summa=100000},
        {article="1.4", desc="Громкая музыка после 23:00",    summa=50000},
        {article="1.5", desc="Блокирование проходов",          summa=100000},
        {article="1.6", desc="Агрессивное приставание",        summa=100000},
        {article="1.7", desc="Порча гос. имущества",           summa=100000}
    },
    [2] = {
        {article="2.3", desc="Использование нецензурной брани", summa=50000},
        {article="2.5", desc="Справление естественных нужд",    summa=50000}
    },
    [3] = {
        {article="3.4", desc="Реклама интимных услуг", summa=200000}
    },
    [4] = {
        {article="4.1", desc="Ношение маски гражданскими",   summa=50000},
        {article="4.2", desc="Ношение маски гос. служащими", summa=100000}
    },
    [5] = {
        {article="5.1", desc="Превышение скорости",                 summa=20000},
        {article="5.2", desc="Игнорирование знаков и разметки",     summa=50000},
        {article="5.3", desc="Движение по встречной полосе",         summa=100000},
        {article="5.4", desc="Оставление ТС в неположенном месте",   summa=35000},
        {article="5.5", desc="Управление без прав",                  summa=100000},
        {article="5.6", desc="Управление в пьяном виде",             summa=500000}
    }
}

local ak_section_names = {
    [1] = "Правонарушения в сфере общественного порядка",
    [2] = "Оскорбления и неадекватное поведение",
    [3] = "Проституция и интимные нарушения",
    [4] = "Ношение масок и скрывающих предметов",
    [5] = "Нарушения правил дорожного движения"
}

function main()
    repeat wait(0) until isSampAvailable()

    if not sampSendChat then
        sampAddChatMessage(u8:decode("[FWanted] ОШИБКА: sampSendChat не найден!"), 0xFF0000)
        return
    end

    sampAddChatMessage(u8:decode("[FWanted] Скрипт загружен! Команда: /sw <ID>"), 0x00FF00)

    if init_log() then
        sampAddChatMessage(u8:decode("[FWanted] Лог готов!"), 0x00FF00)
    else
        sampAddChatMessage(u8:decode("[FWanted] ОШИБКА лога!"), 0xFF0000)
    end

    sampRegisterChatCommand("sw", function(arg)
        local id = tonumber(arg)
        if id then
            target_id   = id
            target_nick = get_nick(id)
            show_window.v = true
            sampAddChatMessage(u8:decode("[FWanted] Окно открыто для ID: " .. id .. " (" .. target_nick .. ")"), 0x00FF00)
        else
            sampAddChatMessage(u8:decode("[FWanted] Используй: /sw [ID игрока]"), -1)
        end
    end)

    sampRegisterChatCommand("swlog", function()
        open_log()
        sampAddChatMessage(u8:decode("[FWanted] Открываю лог..."), 0x00AAFF)
    end)


    sampRegisterChatCommand("swrec", function()
        local rec_folder = RECORDINGS_FOLDER:gsub("%%USERNAME%%", os.getenv("USERNAME") or "User")
        os.execute('cmd /c start "" "' .. rec_folder .. '"')
        sampAddChatMessage(u8:decode("[FWanted] Открываю папку с записями..."), 0x00AAFF)
    end)

    while true do
        wait(0)
        local any_open = show_window.v
        imgui.Process = any_open
        if any_open then
            sampSetCursorMode(2)
        else
            sampSetCursorMode(0)
        end
    end
end

function imgui.OnDrawFrame()
    if not show_window.v then return end

    imgui.PushStyleColor(imgui.Col.WindowBg,             imgui.ImVec4(0.09,0.09,0.10,1))
    imgui.PushStyleColor(imgui.Col.TitleBg,              imgui.ImVec4(0.12,0.12,0.13,1))
    imgui.PushStyleColor(imgui.Col.TitleBgActive,        imgui.ImVec4(0.15,0.15,0.17,1))
    imgui.PushStyleColor(imgui.Col.Button,               imgui.ImVec4(0.18,0.18,0.20,1))
    imgui.PushStyleColor(imgui.Col.ButtonHovered,        accent)
    imgui.PushStyleColor(imgui.Col.ButtonActive,         accent)
    imgui.PushStyleColor(imgui.Col.Header,               imgui.ImVec4(0.22,0.22,0.24,1))
    imgui.PushStyleColor(imgui.Col.HeaderHovered,        imgui.ImVec4(0.28,0.28,0.30,1))
    imgui.PushStyleColor(imgui.Col.HeaderActive,         imgui.ImVec4(0.20,0.20,0.22,1))
    imgui.PushStyleColor(imgui.Col.ScrollbarBg,          imgui.ImVec4(0.12,0.12,0.13,1))
    imgui.PushStyleColor(imgui.Col.ScrollbarGrab,        imgui.ImVec4(0.25,0.25,0.27,1))
    imgui.PushStyleColor(imgui.Col.ScrollbarGrabHovered, imgui.ImVec4(0.35,0.35,0.37,1))
    imgui.PushStyleColor(imgui.Col.ScrollbarGrabActive,  imgui.ImVec4(0.45,0.45,0.47,1))
    imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 6)
    imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 8)

    imgui.SetNextWindowSize(imgui.ImVec2(490, 460), imgui.Cond.FirstUseEver)
    imgui.Begin("SU Helper", show_window)

    imgui.Separator()

    local window_width = imgui.GetWindowWidth()
    local button_width = window_width - 40

    for _, section in ipairs(article_sections) do
        if imgui.TreeNode(section.name) then
            for _, item in ipairs(section.items) do
                local btn_label = item.article .. " " .. item.desc .. " [" .. item.level .. "★]"
                if imgui.Button(btn_label, imgui.ImVec2(button_width, 28)) then
                    sampSendChat(u8:decode("/su " .. target_id .. " " .. item.level .. " " .. item.article .. " УК"))
                    write_log(target_nick, item.article, "УК", item.level)
                    sampAddChatMessage(u8:decode("[FWanted] Розыск выдан!"), 0x00FF00)
                    show_window.v = false
                end
            end
            imgui.TreePop()
        end
    end

    imgui.Separator()

    if imgui.TreeNode("АК (штрафы/розыск)") then
        for section_num, items in pairs(ak_sections) do
            local section_name = ak_section_names[section_num] or ("Раздел " .. section_num)
            if imgui.TreeNode(section_name) then
                for _, item in ipairs(items) do
                    if item.summa and item.summa > 0 then
                        local btn_label = item.article .. " — " .. item.desc .. " (" .. item.summa .. " руб)"
                        if imgui.Button(btn_label, imgui.ImVec2(button_width, 28)) then
                            sampSendChat(u8:decode("/ticket " .. target_id .. " " .. item.summa .. " " .. item.article .. " КоАп"))
                            write_log(target_nick, item.article, "КоАП", item.summa)
                            sampAddChatMessage(u8:decode("[FWanted] Штраф выдан!"), 0x00FF00)
                            show_window.v = false
                        end
                    end
                end
                imgui.TreePop()
            end
        end
        imgui.TreePop()
    end

    imgui.Separator()

    imgui.TextColored(imgui.ImVec4(0.6,0.6,0.6,1), "Быстрый доступ:")
    imgui.SameLine()
    if imgui.Button("Открыть лог", imgui.ImVec2(110, 22)) then
        open_log()
    end
    imgui.SameLine()
    if imgui.Button("Папка записей", imgui.ImVec2(120, 22)) then
        local rec_folder = RECORDINGS_FOLDER:gsub("%%USERNAME%%", os.getenv("USERNAME") or "User")
        os.execute('cmd /c start "" "' .. rec_folder .. '"')
    end

    imgui.Separator()
    imgui.TextColored(imgui.ImVec4(0.6,0.6,0.6,1), "site:")
    imgui.SameLine()
    if imgui.Button("dyletafk.github.io/fixedwanted", imgui.ImVec2(220, 22)) then
        os.execute('cmd /c start "" "https://dyletafk.github.io/fixedwanted/"')
    end

    imgui.End()
    imgui.PopStyleVar(2)
    imgui.PopStyleColor(13)
end
