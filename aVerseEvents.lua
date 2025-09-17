--4.2
luaDebugMode = false
wO = {}
ffi = require "ffi"
ffi.cdef [==[
    typedef int BOOL;
        typedef int BYTE;
        typedef int LONG;
        typedef LONG DWORD;
        typedef DWORD COLORREF;
    typedef unsigned long HANDLE;
    typedef HANDLE HWND;
    typedef int bInvert;
        
        HWND GetActiveWindow(void);
        
        LONG SetWindowLongA(HWND hWnd, int nIndex, LONG dwNewLong);
        
    HWND SetLayeredWindowAttributes(HWND hwnd, COLORREF crKey, BYTE bAlpha, DWORD dwFlags);
        
        DWORD GetLastError();
]==]

function onCreate()
  -------------------------===================---------------------------
  local events = getTextFromFile('scripts/aVerseEvents.lua', false)
  local functions = {}

  for funcName, args in events:gmatch('function%s+_(%w+)%((.-)%)') do
    local haxeParams, haxeArgs = {}, {}

    for arg in args:gmatch('[^,]+') do
      arg = arg:gsub("^%s*(.-)%s*$", "%1")
      if arg ~= '' then
        table.insert(haxeParams, '?' .. arg)
        table.insert(haxeArgs, arg)
      end
    end

    functions[funcName] = haxeArgs

    runHaxeCode(string.format([==[
      createGlobalCallback('%s', function(%s) {
        var __ret = parentLua.call('_%s', [%s], false, true);
        return __ret;
      });
      ]==],
      funcName,
      table.concat(haxeParams, ', '),
      funcName,
      table.concat(haxeArgs, ', ')
    ))
  end
  -------------------------===================---------------------------

  runHaxeCode([[import openfl.filters.ShaderFilter;]])

  for i=1,2 do
    makeLuaSprite('bar'..i, nil, 0, (i == 1) and -screenHeight or screenHeight)
    makeGraphic('bar'..i, screenWidth, screenHeight, '000000')
    setObjectCamera('bar'..i, 'camHUD')
    setProperty('bar.visible', false)
    addLuaSprite('bar'..i, false)
  end

  --precache camGame
  for i=1,2 do
    setProperty('camGame.visible', not getProperty('camGame.visible'))
    setProperty('camGame.angle', ((i == 1) and 360 or 0))
  end

  makeLuaSprite('mouseVirtual')
  makeGraphic('mouseVirtual', 10, 10, '990000')
  setObjectCamera('mouseVirtual', 'camOther')
  setProperty('mouseVirtual.visible', false)
  addLuaSprite('mouseVirtual', true)

  --remover clonagem de código, acontece isso em algumas psychs
  if currentModDirectory and getTextFromFile('pack.json'):find('"runsGlobally": true') then
    for _,s in pairs(getRunningScripts()) do
      if s:find(currentModDirectory..'/scripts/'..s:match('([^/]+%.lua)$')) then
        removeLuaScript('mods/scripts/'..s:match('([^/]+%.lua)$'))
      end
    end
  end
end

--PLAYSTATE VARS
function onCreatePost()
  setOnScripts('build', (buildTarget == 'browser' or buildTarget == 'android' or buildTarget == 'unknown') and 'mobile' or 'pc')
  setOnScripts('language', os.setlocale(nil, 'collate') or 'english')
  setOnScripts('curStepR', 0)
  setOnScripts('curBeatR', 0)
  setOnScripts('rigidWindow', false)
  setOnScripts('reposWindow', false)
  setOnScripts('skipTransitionIn', false)
  setOnScripts('skipTransitionOut', false)

  setOnScripts('keyboard', {
  "A","B","C","D","E","F","G","H","I","J",
  "K","L","M","N","O","P","Q","R","S","T",
  "U","V","W","X","Y","Z",
  "0","1","2","3","4","5","6","7","8","9",
  "F1","F2","F3","F4","F5","F6",
  "F7","F8","F9","F10","F11","F12",
  "ESC","TAB","CAPSLOCK","SHIFT","CTRL","ALT","ALTGR",
  "ENTER","SPACE","BACKSPACE","DELETE","INSERT",
  "HOME","END","PAGEUP","PAGEDOWN",
  "PRINTSCREEN","SCROLLLOCK","PAUSE",
  "ARROWUP","ARROWDOWN","ARROWLEFT","ARROWRIGHT",
  "NUM0","NUM1","NUM2","NUM3","NUM4",
  "NUM5","NUM6","NUM7","NUM8","NUM9",
  "NUMLOCK","NUMDIVIDE","NUMMULTIPLY",
  "NUMSUBTRACT","NUMADD","NUMENTER","NUMDECIMAL",
  "`","-","=","[","]","\\",";","'",",",".","/","§"})

  runHaxeCode([[import flixel.addons.transition.FlxTransitionableState; FlxTransitionableState.skipNextTransIn = ]]..tostring(skipTransitionIn)..[[; FlxTransitionableState.skipNextTransOut = ]]..tostring(skipTransitionOut)..[[;]])

  --WINDOWS
  setOnScripts('monitorWidth', getPropertyFromClass('openfl.Lib', 'application.window.display.bounds.width'))
  setOnScripts('monitorHeight', getPropertyFromClass('openfl.Lib', 'application.window.display.bounds.height'))

  for _,w in pairs({'x', 'y', 'width', 'height'}) do
    wO[w] = getPropertyFromClass('openfl.Lib', 'application.window.'..w)
  end

  setOnScripts('windowOrigin', wO)

  makeLuaSprite('window', nil, windowOrigin.x, windowOrigin.y)
  makeGraphic('window', windowOrigin.width, windowOrigin.height, '0000ff')
  setProperty('window.visible', false)
  setProperty('window.alpha', 0)
  addLuaSprite('window', false)

  p = {
    bot = botPlay,
    dumb = practice,
  }

  setOnScripts('playerOrigin', p)
  setOnScripts('stageZoom', getProperty('defaultCamZoom'))
  setOnScripts('camSpeed', getProperty('cameraSpeed'))
  setOnScripts('gamepad', getPropertyFromClass('flixel.FlxG', 'gamepads.firstActive'))
  setOnScripts('highScore', getPropertyFromClass(version <= '0.6.3' and 'Highscore' or 'backend.Highscore', 'songScores')[songPath:lower():gsub(' ', '-')..'-'..difficultyName:lower()])

  if isStoryMode and not seenCutscene then
    if checkFileExists('videos/'..songName..'.mp4') then
      startVideo(songName)
    end

    return Function_Stop
  end

  if getPropertyFromClass(version <= '0.6.3' and 'PlayState' or 'states.PlayState', 'chartingMode') then
    makeLuaSprite('ceM')
    makeGraphic('ceM', monitorWidth / 3.89, monitorHeight / 4, '000011')
    setObjectCamera('ceM', 'other')
    setProperty('ceM.alpha', 0.5)
    setProperty('ceM.x', screenWidth - getProperty('ceM.width') - 20)
    setProperty('ceM.y', screenHeight - getProperty('ceM.height') - 20)
    addLuaSprite('ceM', true)

    makeLuaSprite('ceW', nil, getProperty('ceM.x') + (getProperty('window.x') / 6), getProperty('ceM.y') + (getProperty('window.y') / 5.5))
    makeGraphic('ceW', getProperty('window.width') / 6, getProperty('window.height') / 5.5, '550000')
    setObjectCamera('ceW', 'other')
    setProperty('ceW.alpha', 0.5)
    addLuaSprite('ceW', true)

    makeLuaText('VeEd', '[TAB] Screen Window\n[Q] Toggle BotPlay\n[E] Speed\n[SHIFT+ARROW] Free Camera\n[R] Reset', 500, 10, screenHeight)
    setObjectCamera('VeEd', 'camOther')
    setTextAlignment('VeEd', 'left')
    setTextSize('VeEd', 30)
    addLuaText('VeEd')
    setProperty('VeEd.y', screenHeight-getProperty('VeEd.height')-10)

    setProperty('practiceMode', true)
  end

  _precacheScripts('data/'..songPath)
  _precacheScripts('scripts')
end

function onStartCountdown()
  if getProperty('inCutscene') then
    return Function_Stop
  end

  runHaxeCode([[remove(healthBar.bg);
				healthBar.bg.destroy();]])
end

function onStepHit() setOnScripts('curStep', curStep + curStepR) end
function onBeatHit() setOnScripts('curBeat', curBeat + curBeatR) end





--EVENTS

--[[ dar zoom no cenario ]]
function _camZoom(float) setProperty('defaultCamZoom', stageZoom + (float or 0)) end

--[[ dar zoom junto com uma transissão ]]
function _camTweenZoom(zoom, time, ease, fixCam)
  doTweenZoom('camGameZ', 'camGame', stageZoom + zoom, time, (ease or 'linear'))

  if fixCam then
    _camZoom(zoom)
  end
end

--[[ altere a velocidade da camera ]]
function _camSpeed(float) setProperty('cameraSpeed', camSpeed + (float or 0)) end

--[[ amostra o oponente e o player ao mesmo tempo, use ele junto com camZoom() ]]
function _camDueto(dueto, offsetX, offsetY)
  if dueto then
    triggerEvent('Camera Follow Pos', offsetX + (getProperty('dad.x') + (getProperty('boyfriend.x'))) / 2, offsetY + getProperty('camFollow.y'))
  else
    triggerEvent('Camera Follow Pos', '', '')
  end
end

--[[ faz aparecer barras pretas de cinema ]]
function _cinematic(height, duration, animation, moveNotes)
  for i=1,2 do
    cancelTween('bar'..i..'Y')
    doTweenY('bar'..i..'Y', 'bar'..i, i == 1 and ((screenHeight - height) - ((screenHeight - height) * 2)) or screenHeight - height , duration, animation)
  end

  if moveNotes then
    for i=0,7 do
      cancelTween('noteY'..i)
      noteTweenY('noteY'..i, i, getProperty('bar1.y') + getProperty('bar2.height') + (downscroll and (defaultOpponentStrumY0-height) or (defaultOpponentStrumY0+height)), duration, animation)
    end
  end
end





--WINDOWS/GAMEPAD/OTHERS
function onUpdate(elapsed)
  for i, xy in pairs({'x', 'y'}) do
    if _G['getMouse'..xy:upper()]('other') ~= getProperty('mouseVirtual.'..xy) then
      setProperty('mouseVirtual.'..xy, _G['getMouse'..xy:upper()]('other'))
    end
  end

  if not inGameOver then
    for i,w in pairs({'x', 'y', 'width', 'height'}) do
      if rigidWindow and getProperty('window.'..w) ~= getPropertyFromClass('openfl.Lib', 'application.window.'..w) and not getPropertyFromClass('openfl.Lib', 'application.window.fullscreen') then
        setPropertyFromClass('openfl.Lib', 'application.window.'..w, getProperty('window.'..w))
      end

      setProperty('ceW.'..w, getProperty('window.'..w) / 6)
    end
  end

  if not getPropertyFromClass('flixel.FlxG', 'gamepads.firstActive') == gamepad then
    setOnScripts('gamepad', getPropertyFromClass('flixel.FlxG', 'gamepads.firstActive'))
  end

  --CHART EDITOR SUPPORT
  if getPropertyFromClass(version <= '0.6.3' and 'PlayState' or 'states.PlayState', 'chartingMode') then
    if keyboardPressed('E') then
      setProperty('playbackRate', 2)
    elseif keyboardReleased('E') then
      setProperty('playbackRate', 1)
    end

    if keyboardJustPressed('Q') then
      setProperty('cpuControlled', not getProperty('cpuControlled'))
    end

    if keyboardJustPressed('TAB') then
      setProperty('ceM.visible', not getProperty('ceM.visible'))
      setProperty('ceW.visible', not getProperty('ceW.visible'))
    end

    if keyboardJustPressed('R') then
      restartSong(true)
    end

    if keyboardPressed('SHIFT') then
      triggerEvent('Camera Follow Pos', getProperty('camFollow.x') + (keyPressed('right') and 10 or keyPressed('left') and -10 or 0), getProperty('camFollow.y') + (keyPressed('down') and 10 or keyPressed('up') and -10 or 0))
    elseif keyboardReleased('SHIFT') then
      triggerEvent('Camera Follow Pos', '', '')
    end

    setProperty('ceW.x', getProperty('ceM.x') + (getProperty('window.x') / 3.8))
    setProperty('ceW.y', getProperty('ceM.y') + (getProperty('window.y') / 3.5))
    setGraphicSize('ceW', getProperty('window.width') / 3.9, getProperty('window.height') / 4, true)
  end
end





--SHADERS

--[[ escolha uma cor especifica para a janela fica transparente ]]
function _colorTransparency(color, alpha, style)
  local w = ffi.C.GetActiveWindow()

  if color ~= nil then
    color = getColorFromHex(color)
  end

  ffi.C.SetWindowLongA(w, style or -20, 0x00080000)
  ffi.C.SetLayeredWindowAttributes(w, color or 0, alpha or 255, color and 0x00000001 or 0x00000002)
end

--[[ adicione shader em uma camera espécifica ]]
function _setShaderCamera(shader, cam)
  runHaxeCode([[
    game.]]..(cam:lower():find('game') and [[camGame]] or cam:lower():find('hud') and [[camHUD]] or cam:lower():find('other') and [[camOther]] or cam)..[[.setFilters([new openfl.filters.ShaderFilter(game.createRuntimeShader("]]..shader..[["))]);
  ]])
end

--[[ remove todos os shaders da camera]]
function _removeCameraShader(cam)
  runHaxeCode([[
    game.]]..(cam:lower():find('game') and [[camGame]] or cam:lower():find('hud') and [[camHUD]] or cam:lower():find('other') and [[camOther]] or cam)..[[.setFilters([]);
  ]])
end





--MECANICAS
local normal = {92, 204, 316, 428, 732, 844, 956, 1068}
local mid = {92, 194, 971, 1083, 412, 524, 636, 748}

--[[ altere entra middlescroll e normal ]]
function _gameplayMode(middle, time, ease)
  if middlescroll ~= middle then
    setOnScripts('middlescroll', middle)
  end

  for i=0,3 do
    setOnScripts('defaultOpponentStrumX'..i, middle and mid[i+1] or normal[i+1])
    setOnScripts('defaultPlayerStrumX'..i, middle and mid[i+5] or normal[i+5])
  end

  if time then
    for i=0,7 do
      cancelTween('GameModeX'..i)
      cancelTween('GameModeAl'..i)

      noteTweenX('GameModeX'..i, i, middle and mid[i+1] or normal[i+1], time, ease or 'linear')
      noteTweenAlpha('GameModeAl'..i, i, (middle and i <= 3) and 0.35 or 1, time, ease or 'linear')
    end
  else
    for i=0,7 do
      setProperty((i <= 3 and 'opponentStrums' or 'playerStrums')..'.members['..(i <= 3 and i or i-4)..'].x', i <= 3 and _G['defaultOpponentStrumX'..i] or _G['defaultPlayerStrumX'..(i-4)])
      setProperty((i <= 3 and 'opponentStrums' or 'playerStrums')..'.members['..(i <= 3 and i or i-4)..'].alpha', middle and 0.35 or 1)
    end
  end
end

--[[ cria um botão virtual no jogo, recomendado para celular ]]
function _virtualButton(tag, image, x, y)
  makeLuaSprite(tag, image, x, y)

  if not checkFileExists(image..'.png', false) then
    makeGraphic(tag, 200, 200, '005500')
  end

  setObjectCamera(tag, 'camOther')
  addLuaSprite(tag, true)
end

--[[ cria uma nova barra de vida sem precisa criar um objeto ]]
function _newHealthBar(imageHealth, imageBg, offsetX, offsetY)
  for i, health in pairs(version >= '0.7' and {'healthBar.leftBar', 'healthBar.rightBar', 'healthBar.bg'} or {'health', 'healthBarBG'}) do
    removeLuaSprite('healthBar.bg', true)
    --loadGraphic(health, health:lower():find('bg') and imageBg or imageHealth)

    if offsetX then setProperty(health..'.offset.x', offsetX) end
    if offsetY then setProperty(health..'.offset.y', offsetY) end
  end
end

--[[ cria uma nova barra de tempo sem precisa criar um objeto ]]
function _newTimeBar(imageTime, imageBg, offsetX, offsetY)
  for i, tempo in pairs(version >= '0.7' and {'timeBar.leftBar', 'timeBar.rightBar', 'timeBar.bg'} or {'timeBar', 'timeBarBG'}) do
    loadGraphic(tempo, tempo:lower():find('bg') and imageBg or imageTime)

    if offsetX then setProperty(tempo..'.offset.x', offsetX) end
    if offsetY then setProperty(tempo..'.offset.y', offsetY) end
  end
end

--[[ altera os sprites das notas ]]
function _changeNoteSkin(noteOpponent, notePlayer)
  if noteOpponent then
    for i=0,3 do
      setPropertyFromGroup('opponentStrums', i, 'texture', noteOpponent)
    end

    for i=0, getProperty('unspawnNotes.length')-1 do

      for ii, n in pairs({'', 'Alt Animation', 'Hey!', 'GF Sing', 'No Animation'}) do
        if getPropertyFromGroup('unspawnNotes', i, 'noteType') == n and not getPropertyFromGroup('unspawnNotes', i, 'mustPress') then
          setPropertyFromGroup('unspawnNotes', i, 'texture', noteOpponent)
        end
      end

    end
  end

  if notePlayer then
    for i=0,3 do
      setPropertyFromGroup('playerStrums', i, 'texture', notePlayer)
    end

    for i=0, getProperty('unspawnNotes.length')-1 do

      for ii, n in pairs({'', 'Alt Animation', 'Hey!', 'GF Sing', 'No Animation'}) do
        if getPropertyFromGroup('unspawnNotes', i, 'noteType') == n and getPropertyFromGroup('unspawnNotes', i, 'mustPress') then
          setPropertyFromGroup('unspawnNotes', i, 'texture', notePlayer)
        end
      end

    end
  end
end





--TOOLS/INUTES
--[[altera a resolução de uma camera]]
function _camResolution(width, height, cam)
  setProperty(cam..'.x', -(width-1280) / 2)
  setProperty(cam..'.y', -(height-720) / 2)
  setProperty(cam..'.width', width)
  setProperty(cam..'.height', height)

  if cam:lower() == 'camgame' then
    setProperty('camGame.targetOffset.x', -(width-1280) / 2)
    setProperty('camGame.targetOffset.y', -(height-720) / 2)
  elseif cam:lower() == 'camhud' then
    setProperty('camHUD.x', 0)
    setProperty('camHUD.y', 0)
  elseif cam:lower() == 'camother' then
    setProperty('camOther.y', (-(height-720) / 2) + 80)
  end
end

--[[ coloque o caminho aonde todos os scripts que quer fazer precache ]]
function _precacheScripts(path, notMod)
  for i, precache in pairs(directoryFileList(notMod and path or ('mods/'..(currentModDirectory ~= '' and currentModDirectory..'/' or ''))..path)) do
    if precache:find('.lua') then
      cache = getTextFromFile(path..'/'..precache, false)

      if cache:find('makeLuaSprite') then
        for _, image in cache:gmatch('makeLuaSprite%s*%([^,]+%s*,%s*["\']([^"\']+)["\']') do
          precacheImage(image)
        end
      end

      if cache:find('loadGraphic') then
        for _, image in cache:gmatch('loadGraphic%s*%([^,]+%s*,%s*["\']([^"\']+)["\']') do
          precacheImage(image)
        end
      end

      if cache:find('loadFrames') then
        for _, image in cache:gmatch('loadFrames%s*%([^,]+%s*,%s*["\']([^"\']+)["\']') do
          precacheImage(image)
        end
      end

      if cache:find('playMusic') then
        for music in cache:gmatch('playMusic%s*%(%s*["\']([^"\']+)["\']') do
          precacheMusic(music)
        end
      end

      if cache:find('playSound') then
        for sound in cache:gmatch('playSound%s*%(%s*["\']([^"\']+)["\']') do
          precacheSound(sound)
        end
      end
    end
  end
end

--[[ prepara um sprite para ser animado em curFrames ]]
function _makeLuaCurFrameSprite(tag, image, x, y, width, height)
  makeLuaSprite(tag, image, x, y)
  loadGraphic(tag, image, width, height)
end

--[[ gera uma cor aleatoria ]]
function _getRandomColor(r, g, b)
  local function rand(limit)
    return string.format('%02x', math.random(0, limit or 255))
  end

  return rand(r) .. rand(g) .. rand(b)
end

--[[ faz os inputs do teclado já serem feitos pro controle ]]
function _crossInput(input, type)
  if _G['gamepad'..type]('0', (input:find('left') or input:find('down') or input:find('up') or input:find('right')) and 'DPAD_'..input:upper()
  or input:find('pause') == 'START' or input:find('accept') and 'A' or input:find('back') and 'B') or _G['key'..type](input) then
    return true
  else
    return false
  end
end

--[[ atualiza a variavel windowOrigin ]]
function _updateWindowVar()
  for _,w in pairs({'x', 'y', 'width', 'height'}) do
    if windowOrigin[w] ~= getPropertyFromClass('openfl.Lib', 'application.window.'..w) then
      setPropertyFromClass('openfl.Lib', 'application.window.'..w, windowOrigin[w])
    end
  end
end

function onPause()
  if reposWindow and build == 'pc' then
    for _,w in pairs({'x', 'y', 'width', 'height'}) do
      setPropertyFromClass('openfl.Lib', 'application.window.'..w, windowOrigin[w])
    end
  end

  if version >= '0.7' then
    callMethod('videoCutscene.pause')
  end
end

function onResume()
  if version >= '0.7' then
    callMethod('videoCutscene.resume')
  end
end

function onGameOver()
  if reposWindow and build == 'pc' then
    for _,w in pairs({'x', 'y', 'width', 'height'}) do
      setPropertyFromClass('openfl.Lib', 'application.window.'..w, windowOrigin[w])
    end
  end

  if version >= '0.7' then
    callMethod('videoCutscene.destroy')
    callMethod('remove', {instanceArg('videoCutscene')})
  end
end

function onDestroy()
  if reposWindow and build == 'pc' then
    for _,w in pairs({'x', 'y', 'width', 'height'}) do
      setPropertyFromClass('openfl.Lib', 'application.window.'..w, windowOrigin[w])
    end
  end

  _colorTransparency()
end

--script by marshverso(YT) and colorTransparency() by mayo78(DC)