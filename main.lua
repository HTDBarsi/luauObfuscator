local filename = arg[1]
function readfile(name)
    local handle = io.open(name,"r"); local data = handle:read("*a"); handle:close(); return data;
end
function writefile(name,data)
    local handle = io.open(name,"w"); handle:write(data); handle:close();
end

local fakes = {}
local fakes2 = {}

local code = readfile(filename).."\n"
code = code:gsub("([^\\])\\'", function(s) return (s or "").."\\39" end):gsub('([^\\])\\"', function(s) return (s or "").."\\34" end):gsub("%-%-%[%[.-%]%]","")
local lines = {}
for v in code:gmatch("(.-)\n") do 
    table.insert(lines,({v:gsub("^[ ]*%-%-.+","")})[1])--({v:gsub("%-%-[^\n\r].-\n"," \n")})[1]:sub(1,-2))
end
code = table.concat(lines,"\n")
writefile("temp.lua",code)
--code = code:gsub("%-%-%[%[.-%]%]",""):gsub("%-%-.-\n","")
function fetchStrings(str)
    local currentContext = nil;
    -- using string concats are more resource-heavy
    local currentText = {};
    local strings = {}
    local i = 0
    local contextIndex = 0
    while (i ~= #str) do 
        local char = str:sub(i,i)
        i = i + 1
        -- not this parT?
        if char:find("['\"]") and not str:sub(i,i+2):find("[^\\]\\['\"]") then 
            if currentContext == nil then
                currentContext = char
                currentText = {char}
                contextIndex = i
            elseif currentContext == char then
                table.insert(currentText,char)
                table.insert(strings,table.concat(currentText))
                currentContext = nil
            elseif char == "\n" then
                i = contextIndex+1
                currentContext = nil
                currentText = {}
            else
                table.insert(currentText,char)
            end
        elseif str:sub(i,i+4):find("[^%-][^%-]%[%[") then
            local s = i+3
            repeat i = i + 1 until str:sub(i-1,i) == "]]"
            currentContext = nil
            currentText = {}
            table.insert(fakes2,{str:sub(s,i),"HTD\1STRING"..#fakes2+1})
            code = code:gsub(c(str:sub(s,i)),"HTD\1STRING"..#fakes2)
            --print("ignored",str:sub(s,i))
        else
            table.insert(currentText,char)
        end
    end
    return strings
end

local memes = {}
for str in readfile("memes.txt"):gmatch("(.-)\n") do
    table.insert(memes,str)
end

function obfuscateString(s,literal)
    if not literal then
        s = s:gsub("\\x%x%x", function(s) 
            return load("return '"..s.."'")() 
        end):gsub("\\%d%d?%d?", function(s) 
            return load("return '"..s.."'")() 
        end):gsub("\\u{%x%x%x%x}", function(s)
            return load("return '"..s.."'")()
        end):gsub("\\[abfnrtv]",function(s)
            return load("return '"..s.."'")()
        end):gsub("\\\\", "\\"):gsub("\\n","\n"):gsub("\\'","\'"):gsub('\\"','\"'):gsub("\\z","\z")
    end
    s = s:gsub(".", function(char)
        return char:byte()/5 ..","
    end)
    local id = math.random(1000,99999)
    return ('((function()local _'..id..' = "";'.. (math.random(1,10) == 5 and "I['_']([["..memes[math.random(1,#memes)].."]])" or "") ..' for i,v in I["lIlIl"]({'..s..'})do _'..id..' = _'..id..'..I.I[I.ll](I.IlIl[I.IllI](v*5)) end return _'..id..' end)())')
end

function c(s)
    return s:gsub("[%[%]%+%-%*%.%?%%%(%)%^%$]", function(s) return "%"..s end)
end

for i,v in pairs(fetchStrings(code)) do
    --print(1,i,"["..v.."]")
    table.insert(fakes,{v,"HTDNSTRING"..#fakes+1})
    local pos = code:find(c(v))
    code = code:sub(1,pos-1).. "HTDNSTRING"..#fakes ..code:sub(pos+#v)
end

code = code:gsub("%-%-.-\n"," "):gsub("%-%-%[%[.-%]%]"," "):gsub("\n"," "):gsub("%s+"," ")

for i = #fakes,1,-1 do 
    --print(fakes[i],fakes[i][1],fakes[i][2])
    code = code:gsub(fakes[i][2],function() return obfuscateString(fakes[i][1]:sub(2,-2),false) end)
end
for i = #fakes2,1,-1 do 
    code = code:gsub(fakes2[i][2],function() return obfuscateString(fakes2[i][1]:sub(3,-3),true) end)
end

local name = "_"..math.random(10000,99999)
local beginning = string.format('--Obfuscated with shitfuscator v1.1\nlocal I={["_"] = function() end,["lIlIl"] = getfenv(1).pairs, ["IlIl"]=math,["IllI"]="round",["Il"]=tonumber,["lI"]=bit32,["l"]="rshift",["I"]=string,["ll"]="char",["II"]="byte",["Ill"]=tostring,["IIl"]=""};function %s(%s,_)return (%s-#I.Ill(_))+_;end;\n',name,name.."1",name.."1")
writefile("./output/"..arg[1]:gsub(".-[\\/]",""),beginning..code)
