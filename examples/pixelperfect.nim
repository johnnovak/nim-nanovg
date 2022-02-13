import glfw

import glad/gl
import nanovg


# Pixel-perfect pixel, line & rectangle drawing experiments
#

proc keyCb(win: Window, key: Key, scanCode: int32, action: KeyAction,
           modKeys: set[ModifierKey]) =

  if action != kaDown: return

  case key
  of keyEscape: win.shouldClose = true
  else: return


proc createWindow(): Window =
  var cfg = DefaultOpenglWindowConfig
  cfg.size = (w: 400, h: 300)
  cfg.title = "Pixel perfect drawing demo"
  cfg.resizable = true
  cfg.bits = (r: 8, g: 8, b: 8, a: 8, stencil: 8, depth: 16)
  cfg.debugContext = true

  when not defined(windows):
    cfg.version = glv32
    cfg.forwardCompat = true
    cfg.profile = opCoreProfile

  when defined(demoMSAA):
    cfg.nMultiSamples = 4

  newWindow(cfg)


proc drawLabel(vg: NVGcontext, text: string, x, y, w, h: float) =
  vg.fontSize(18.0)
  vg.fontFace("sans")
  vg.fillColor(white(128))

  vg.textAlign(haLeft, vaMiddle)
  discard vg.text(x, y+h*0.5, text)


proc rectStroke(vg: NVGcontext) =
  var
    x = 0.0
    y = 0.0

  vg.strokeColor(rgb(255, 255, 255))

  ###############################################
  # Coordinates need to be offset by 0.5 because they are interpreted to be
  # "on the grid", not "at the middle of the pixels"
  var sw = 1.0
  var so = sw*0.5
  vg.strokeWidth(sw)

  # Draws nothing because w & h are zero
  vg.beginPath()
  vg.rect(x+so, y+so, 0, 0)
  vg.stroke()

  # Draws a 2x2 white rect (so effectively width & height are increased by
  # 1 pixel)
  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 1, 1)
  vg.stroke()

  # Draws a 3x3 white rect
  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 2, 2)
  vg.stroke()

  # Draws a 4x4 white rect
  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 3, 3)
  vg.stroke()

  # ----------------------------------
  # Always adding strokeWidth/2 to x & y ensures the shape doesn't start
  # "before" those coordinates
  sw = 2.0
  so = sw*0.5
  vg.strokeWidth(sw)

  x = 0
  y += 10

  # Draws nothing
  vg.beginPath()
  vg.rect(x+so, y+so, 0, 0)
  vg.stroke()

  # Draws a 3x3 rect
  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 1, 1)
  vg.stroke()

  # Draws a 4x4 rect (because the strokeWidth is 2)
  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 2, 2)
  vg.stroke()

  # Draws an 5x5 rect (because the strokeWidth is 2)
  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 3, 3)
  vg.stroke()

  # ----------------------------------
  sw = 3.0
  so = sw*0.5
  vg.strokeWidth(sw)

  x = 0
  y += 10

  vg.beginPath()
  vg.rect(x+so, y+so, 0, 0)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 1, 1)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 2, 2)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 3, 3)
  vg.stroke()

  ###############################################
  # The stroke width can be subtracted from w & h to fit the rect within the
  # specified width & height, but this only works if both w & h are greater
  # than the stroke width.
  sw = 1.0
  so = sw*0.5
  vg.strokeWidth(sw)

  vg.fillColor(rgb(255, 255, 0))

  y = 0
  x = 100
  vg.beginPath()
  vg.rect(x+so, y+so, 0-sw, 0-sw)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 1-sw, 1-sw)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 2-sw, 2-sw)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 3-sw, 3-sw)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 4-sw, 4-sw)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 5-sw, 5-sw)
  vg.stroke()

  # ----------------------------------
  sw = 2.0
  so = sw*0.5
  vg.strokeWidth(sw)

  x = 100
  y += 10

  vg.beginPath()
  vg.rect(x+so, y+so, 0-sw, 0-sw)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 1-sw, 1-sw)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 2-sw, 2-sw)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 3-sw, 3-sw)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 4-sw, 4-sw)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 5-sw, 5-sw)
  vg.stroke()

  # ----------------------------------
  sw = 3.0
  so = sw*0.5
  vg.strokeWidth(sw)

  x = 100
  y += 10

  vg.beginPath()
  vg.rect(x+so, y+so, 0-sw, 0-sw)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 1-sw, 1-sw)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 2-sw, 2-sw)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 3-sw, 3-sw)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 4-sw, 4-sw)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 5-sw, 5-sw)
  vg.stroke()


proc rectFill(vg: NVGcontext) =
  # To draw filled shapes, it's best to set strokeWidth to 1 and don't
  # offset the starting coords.
  var sw = 1.0
  vg.strokeWidth(sw)

  var
    x = 0.0
    y = 50.0

  # Draws nothing
  vg.beginPath()
  vg.rect(x, y, 0, 0)
  vg.fill()

  # Draws a 1x1 rect (good for drawing single pixels)
  x += 10
  vg.beginPath()
  vg.rect(x, y, 1, 1)
  vg.fill()

  # Draws a 2x2 rect
  x += 10
  vg.beginPath()
  vg.rect(x, y, 2, 2)
  vg.fill()

  # Draws a 3x3 rect
  x += 10
  vg.beginPath()
  vg.rect(x, y, 3, 3)
  vg.fill()

  # ----------------------------------
  # The stroke width based offset trick works with fill too, but there's not
  # much point to it. It's best to stick with sw=1 and no offsets.
  sw = 2.0
  var so = sw*0.5
  vg.strokeWidth(sw)

  x = 100
  y = 50

  # Draws nothing
  vg.beginPath()
  vg.rect(x+so, y+so, 0, 0)
  vg.fill()

  # Draws a 1x1 rect
  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 1, 1)
  vg.fill()

  # Draws a 2x2 rect
  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 2, 2)
  vg.fill()

  # Draws a 3x3 rect
  x += 10
  vg.beginPath()
  vg.rect(x+so, y+so, 3, 3)
  vg.fill()

  vg.fillColor(rgb(255, 255, 0))


proc lines(vg: NVGcontext) =
  var
    x = 1.0
    y = 80.0
    sw = 1.0
    so = sw*0.5

  vg.strokeWidth(1.0)
  vg.lineCap(lcjSquare)

  # Nothing is drawn is the destination point is the same as the start point
  vg.beginPath()
  vg.moveTo(x-1+so,     y+so)
  vg.lineTo(x-1+so,     y+so)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.moveTo(x-1+so,     y+so)
  vg.lineTo(x-1+so + 1, y+so)
  vg.stroke()

  x += 10
  vg.beginPath()
  vg.moveTo(x-1+so,     y+so)
  vg.lineTo(x-1+so + 2, y+so)
  vg.stroke()


proc renderFrame(vg: NVGcontext) =
  vg.save()

  rectStroke(vg)
  rectFill(vg)
  lines(vg)

  vg.restore()


proc loadFonts*(vg: NVGcontext): bool =
  if vg == nil: return false

  let fontNormal = vg.createFont("sans", "data/Roboto-Regular.ttf")
  if fontNormal == NoFont:
    echo "Could not load regular font."
    return false

  let fontBold = vg.createFont("sans-bold", "data/Roboto-Bold.ttf")
  if fontBold == NoFont:
    echo "Could not load bold font."
    return false

  return true


proc main() =
  glfw.initialize()

  var win = createWindow()
  win.keyCb = keyCb

  glfw.makeContextCurrent(win)

  nvgInit(getProcAddress)

  var flags = {nifStencilStrokes, nifDebug}
  when not defined(demoMSAA): flags = flags + {nifAntialias}
  var vg = nvgCreateContext(flags)

  if not gladLoadGL(getProcAddress):
    quit "Error initialising OpenGL"

  if not loadFonts(vg):
    quit "Could not load fonts"

  glfw.swapInterval(1)

  while not win.shouldClose:
    var
      (winWidth, winHeight) = win.size
      (fbWidth, fbHeight) = win.framebufferSize

      # Calculate pixel ration for hi-dpi devices.
      pxRatio = fbWidth / winWidth

    # Update and render
    glViewport(0, 0, fbWidth, fbHeight)

    glClearColor(0.3, 0.3, 0.32, 1.0)

    glClear(GL_COLOR_BUFFER_BIT or
            GL_DEPTH_BUFFER_BIT or
            GL_STENCIL_BUFFER_BIT)

    vg.beginFrame(winWidth.float, winHeight.float, pxRatio)

    renderFrame(vg)

    vg.endFrame()

    glfw.swapBuffers(win)
    glfw.pollEvents()

  glfw.terminate()


main()
