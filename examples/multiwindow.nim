import glfw

import glad/gl
import nanovg


# Multi-window demo
# -----------------
# Two windows are created, each with its own GL context: a "main" application
# window, and a "splash" window with transparency and no window decoration.
# The splash window is destroyed after 3 seconds.


proc keyCb(win: Window, key: Key, scanCode: int32, action: KeyAction,
           modKeys: set[ModifierKey]) =

  if action != kaDown: return

  case key
  of keyEscape: win.shouldClose = true
  else: return


proc createWindow(w, h: int, title: string,
                  transparent: bool = false,
                  decorated: bool = true): Window =
  var cfg = DefaultOpenglWindowConfig
  cfg.size = (w, h)
  cfg.title = title
  cfg.resizable = true
  cfg.bits = (r: 8, g: 8, b: 8, a: 8, stencil: 8, depth: 16)
  cfg.nMultiSamples = 4
  cfg.transparentFramebuffer = transparent
  cfg.decorated = decorated

  when not defined(windows):
    cfg.version = glv32
    cfg.forwardCompat = true
    cfg.profile = opCoreProfile

  newWindow(cfg)


proc renderFrameA(vg: NVGcontext) =
  vg.fillColor(rgb(200, 0, 0))
  vg.ellipse(200, 200, 70, 70)
  vg.fill()


let imgW = 1810.0
let imgH = 346.0
let imgScale = 1.0

proc renderFrameB(vg: NVGcontext, image: Image) =
  let paint = vg.imagePattern(0, 0, imgW*imgScale, imgH*imgScale, angle=0, image, alpha=1.0)
  vg.fillPaint(paint)
  vg.rect(0, 0, imgW*imgScale, imgH*imgScale)
  vg.fill()


proc main() =
  glfw.initialize()

  var winA = createWindow(400, 500, "Window A")
  var winB = createWindow(imgW.int, imgH.int, "Window B", transparent=true, decorated=false)
  winA.keyCb = keyCb
  winB.keyCb = keyCb

  winB.pos = (100, 300)

  var flags = {nifStencilStrokes, nifAntialias}

  nvgInit(getProcAddress)

  if not gladLoadGL(getProcAddress):
    quit "Error initialising OpenGL"

  glfw.makeContextCurrent(winA)
  var vgA = nvgCreateContext(flags)
  if vgA == nil:
    quit "Error creating NanoVG context"

  glfw.makeContextCurrent(winB)
  var vgB = nvgCreateContext(flags)
  if vgB == nil:
    quit "Error creating NanoVG context"

  var splashImage = vgB.createImage("data/images/gridmonger-logo.png")
  if splashImage == NoImage:
    quit "Could not load image"

  glfw.swapInterval(1)

  var winBDestroyed = false

  var d0 = getTime()

  while not winA.shouldClose and not winB.shouldClose:
    # Window A
    glfw.makeContextCurrent(winA)

    var
      (winWidth, winHeight) = winA.size
      (fbWidth, fbHeight) = winA.framebufferSize
      pxRatio = fbWidth / winWidth

    glViewport(0, 0, fbWidth, fbHeight)

    glClear(GL_COLOR_BUFFER_BIT or
            GL_DEPTH_BUFFER_BIT or
            GL_STENCIL_BUFFER_BIT)

    vgA.beginFrame(winWidth.float, winHeight.float, pxRatio)
    renderFrameA(vgA)
    vgA.endFrame()

    glfw.swapBuffers(winA)

    # Window B
    if not winBDestroyed:
      glfw.makeContextCurrent(winB)

      (winWidth, winHeight) = winB.size
      (fbWidth, fbHeight) = winB.framebufferSize
      pxRatio = fbWidth / winWidth

      glViewport(0, 0, fbWidth, fbHeight)

      glClear(GL_COLOR_BUFFER_BIT or
              GL_DEPTH_BUFFER_BIT or
              GL_STENCIL_BUFFER_BIT)

      vgB.beginFrame(winWidth.float, winHeight.float, pxRatio)
      renderFrameB(vgB, splashImage)
      vgB.endFrame()

      glfw.swapBuffers(winB)

    if not winBDestroyed and getTime() - d0 > 3:
      winB.destroy()
      nvgDeleteContext(vgB)
      winBDestroyed = true

    glfw.pollEvents()

  nvgDeleteContext(vgA)
  glfw.terminate()


main()
