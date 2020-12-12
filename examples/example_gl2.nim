import glad/gl
import glfw

import nanovg
import demo, perf


var
  blowup = false
  screenshot = false
  premult = false
  vsync = false


proc keyCb(win: Window, key: Key, scanCode: int32, action: KeyAction,
           modKeys: set[ModifierKey]) =

  if action != kaDown: return

  case key
  of keyEscape: win.shouldClose = true
  of keySpace: blowup = not blowup
  of keyS: screenshot = true
  of keyP: premult = not premult
  of keyV: vsync = not vsync
  else: return


proc createWindow(): Window =
  var cfg = DefaultOpenglWindowConfig
  cfg.size = (w: 1000, h: 600)
  cfg.title = "NanoVG GL3 Demo"
  cfg.resizable = true
  cfg.bits = (r: 8, g: 8, b: 8, a: 8, stencil: 8, depth: 16)
  cfg.debugContext = true

  when not defined(windows):
    cfg.version = glv20
    cfg.forwardCompat = true
    cfg.profile = opCoreProfile

  when defined(demoMSAA):
    cfg.nMultiSamples = 4

  newWindow(cfg)


proc main() =
  glfw.initialize()

  var fps = initGraph(grsFramesPerSec, "Frame Time")

  var win = createWindow()
  win.keyCb = keyCb
  glfw.makeContextCurrent(win)

  nvgInit(getProcAddress)
  var vg = nvgCreateContext({})

  if not gladLoadGL(getProcAddress):
    quit "Error initialising OpenGL"

  var data: DemoData

  if not loadDemoData(vg, data):
    quit "Could not load demo data"

  setTime(0)
  var prevt = getTime()

  while not win.shouldClose:
    var
      t = getTime()
      dt = t - prevt

    prevt = t

    if vsync:
      glfw.swapInterval(1)
    else:
      glfw.swapInterval(0)

    updateGraph(fps, dt)

    var
      (mx, my) = win.cursorPos()
      (winWidth, winHeight) = win.size
      (fbWidth, fbHeight) = win.framebufferSize
      pxRatio = float(fbWidth) / float(winWidth)

    # Update and render
    glViewport(GLint(0), GLint(0), GLsizei(fbWidth), GLsizei(fbHeight))

    if premult:
      glClearColor(0, 0, 0, 0)
    else:
      glClearColor(0.3, 0.3, 0.32, 1.0)

    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or
            GL_STENCIL_BUFFER_BIT)

    vg.beginFrame(winWidth.float, winHeight.float, pxRatio)

    renderDemo(vg, mx, my, float(winWidth), float(winHeight), t, blowup, data)
    renderGraph(vg, 5, 5, fps)

    vg.endFrame()

    #if screenshot:
    #  screenshot = false
    #  saveScreenShot(fbWidth, fbHeight, premult, "dump.png")

    glfw.swapBuffers(win)
    glfw.pollEvents()

  freeDemoData(vg, data)
  nvgDeleteContext(vg)
  glfw.terminate()


main()
