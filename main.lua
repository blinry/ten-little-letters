require "slam"
scaleinator = require("scaleinator")
scale = scaleinator.create()

-- convert HSL to RGB (input and output range: 0 - 255)
function HSL(h, s, l, a)
    if s<=0 then return l,l,l,a end
    h, s, l = h/256*6, s/255, l/255
    local c = (1-math.abs(2*l-1))*s
    local x = (1-math.abs(h%2-1))*c
    local m,r,g,b = (l-.5*c), 0,0,0
    if h < 1     then r,g,b = c,x,0
    elseif h < 2 then r,g,b = x,c,0
    elseif h < 3 then r,g,b = 0,c,x
    elseif h < 4 then r,g,b = 0,x,c
    elseif h < 5 then r,g,b = x,0,c
    else              r,g,b = c,0,x
    end

    return (r+m)*255,(g+m)*255,(b+m)*255,a
end

-- take the values from tbl from first to last, with stepsize step
function table.slice(tbl, first, last, step)
    local sliced = {}

    for i = first or 1, last or #tbl, step or 1 do
        sliced[#sliced+1] = tbl[i]
    end

    return sliced
end

-- linear interpolation between a and b, with t between 0 and 1
function lerp(a, b, t)
    return a + t*(b-a)
end

-- return a value between 0 and 1, depending on where value is between min and
-- max, clamping if it's outside.
function range(value, min, max)
    if value < min then
        return 0
    elseif value > max then
        return 1
    else
        return (value-min)/(max-min)
    end
end

function love.load()
    images = {}
    for i,filename in pairs(love.filesystem.getDirectoryItems("images")) do
        images[filename:sub(1,-5)] = love.graphics.newImage("images/"..filename)
    end

    sounds = {}
    for i,filename in pairs(love.filesystem.getDirectoryItems("sounds")) do
        sounds[filename:sub(1,-5)] = love.audio.newSource("sounds/"..filename, "static")
    end

    music = {}
    for i,filename in pairs(love.filesystem.getDirectoryItems("music")) do
        music[filename:sub(1,-5)] = love.audio.newSource("music/"..filename)
        music[filename:sub(1,-5)]:setLooping(true)
    end

    fonts = {}
    for i,filename in pairs(love.filesystem.getDirectoryItems("fonts")) do
        fonts[filename:sub(1,-5)] = {}
        fonts[filename:sub(1,-5)][1000] = love.graphics.newFont("fonts/"..filename, 1000)
        fonts[filename:sub(1,-5)][50] = love.graphics.newFont("fonts/"..filename, 50)
    end

    love.graphics.setFont(fonts.montserrat[1000])
    love.graphics.setBackgroundColor(255, 255, 255)

    math.randomseed(os.time())

    canvas = love.graphics.newCanvas(1000, 1000)

    letters = ""
    energy = 100
    mode = "title"

    --characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    allCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    characters = allCharacters
    newChar()
    hint = "Click around,\nthen type your guess.\n\nCollect ten letters to win.\n\nWatch your energy bar."

    psystem = love.graphics.newParticleSystem(images.hit, 128)
    psystem:setParticleLifetime(1, 2) -- Particles live at least 2s and at most 5s.
    psystem:setEmissionRate(0)
    psystem:setSizeVariation(1)
    psystem:setOffset(12, 88)
    psystem:setLinearAcceleration(0, -20, 20, 0) -- Random movement in all directions.
    psystem:setColors(255, 255, 255, 255, 255, 255, 255, 0) -- Fade to transparency.

    scale:newMode("1:1", 1, 1) -- Create a mode with 16:9 aspect ratio. The first created mode is automatically set.
    scale:update(love.graphics.getWidth(), love.graphics.getHeight())
end

function love.resize(w, h)
    scale:update(w, h)
end

function newChar()
    show = false

    local pos = math.random(1, #characters)
    char = string.sub(characters, pos, pos)
    clicks = {}

    canvas:renderTo(function()
        love.graphics.clear(0, 0, 0, 0)
        love.graphics.setColor(255, 255, 255)
        love.graphics.setFont(fonts.montserrat[1000])
        love.graphics.printf(char, 0, -100, 1000, "center")
    end)
end

function gameOver()
    mode = "gameover"
    show = false
    hints = {
        "The English word 'alphabet' is derived from the first two greek letters, alpha and beta.",
        "The sentence 'The quick brown fox jumps over the lazy dog' is a pangram – it contains all letters of the alphabet.",
        "A shorter pangram (containing all letters of the alphabet): 'Sphinx of black quartz, judge my vow'."
    }
    hint = "Game Over!\nClick to start a new game.\n\n"..hints[math.random(1, #hints)]
end

function love.update(dt)
    psystem:update(dt)
end

function love.keypressed(key)
    if key == "escape" then
        if mode == "game" or mode == "win" then
            mode = "title"
        elseif mode == "title" then
            love.event.quit()
        end
    end
end

function love.textinput(c)
    if key == "escape" then
        love.window.setFullscreen(false)
        love.timer.sleep(0.1)
        love.event.quit()
    else
        if not show then
            show = true
            if c == char or c:upper() == char then
                energy = math.min(100, energy + 50)
                letters = letters..char
                characters = characters:gsub(char, "")
                if #letters == 10 then
                    mode = "win"
                    show = false
                    if hardcore then
                        hint = "Wow, congratulations!\n\nDefinitely let me know that you made it this far!"
                    else
                        hint = "You did it!\nThanks for playing! <3\n\nI just enabled the 'hardcore mode', where you will also get numbers as well as some special characters! Good luck! :)"
                    end
                    hardcore = true
                    allCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+-#!?%$&"
                end
            else
                if energy >= 10 then
                    energy = energy - 10
                else
                    energy = 0
                    gameOver()
                end
            end
        end
    end
end

function transformMouse(x, y)
    bw, bh = scale:getBox()
    tx, ty = scale:getTranslation()
    return (x - tx) * 1400 / bw, (y - ty) * 1400 / bh
end

function love.mousepressed(x, y, button, touch)
    x, y = transformMouse(x, y)
    x = x-200
    y = y-200

    if mode == "title" then
        if button == 1 then
            mode = "game"
        end
    elseif mode == "gameover" or mode == "win" then
        if button == 1 then
            hint = nil
            mode = "game"
            characters = allCharacters
            newChar()
            energy = 100
            letters = ""
        end
    else
        if button == 1 then
            if show then
                newChar()
            else
                if energy > 0 then
                    data = canvas:newImageData()
                    if x >= 0 and x <= 999 and y >= 0 and y <= 999 then
                        if hint then
                            hint = nil
                        end

                        r,g,b,a = data:getPixel(x, y)
                        energy = energy - 1
                        if a == 255 then
                            --sounds.hit:setPitch(1+0.2*(math.random()-0.5))
                            love.audio.play(sounds.hit)
                            psystem:setPosition(x+200, y+200)
                            psystem:emit(1)
                        else
                            love.audio.play(sounds.miss)
                        end
                        table.insert(clicks, {x, y, a == 255})
                    end
                else
                    gameOver()
                end
            end
        end
    end
end

function love.draw()
    love.graphics.push()
    bw, bh = scale:getBox()
    tx, ty = scale:getTranslation()
    love.graphics.translate(tx, ty)
    love.graphics.scale(bw/1400, bh/1400)

    if mode == "title" then
        love.graphics.draw(images.title, 200, 200, 0, 0.5, 0.5)
    else
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill",200,200,1000,1000)

        if show then
            love.graphics.setColor(255, 255, 255, 255)
            love.graphics.draw(canvas, 200, 200)
            for key, click in pairs(clicks) do
                hit = click[3]
                if hit then
                    love.graphics.setColor(0, 0, 0)
                else
                    love.graphics.setColor(255, 255, 255)
                end
                love.graphics.circle("fill", click[1]+200, click[2]+200, 10)
                love.graphics.setColor(255, 255, 255)
            end
        end

        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill",200,200+1000+50,energy*10,50)

        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(fonts.montserrat[50])
        --love.graphics.print("Collect "..(10-#letters).." more characters to win: "..letters, 200, 100)
        if hardcore then
            love.graphics.print("Ten Little Characters: "..letters, 200, 100)
        else
            love.graphics.print("Ten Little Letters: "..letters, 200, 100)
        end

        love.graphics.setColor(255, 255, 255)
        love.graphics.draw(psystem)

        if hint then
            love.graphics.setFont(fonts.montserrat[50])
            love.graphics.printf(hint, 200+100, 200+320, 800, "center")
        end
    end

    love.graphics.pop()
end
