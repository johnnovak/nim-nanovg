import math

import glad/gl
import glfw
import glfw/wrapper as glfwWrapper

import nanovg
import demo, perf


var
  blowup = false
  screenshot = false
  premult = false


proc keyCb(win: Win, key: Key, scanCode: int, action: KeyAction,
           modKeys: ModifierKeySet) =

  if action != kaDown: return

  case key
  of keyEscape: win.shouldClose = true
  of keySpace: blowup = not blowup
  of keyS: screenshot = true
  of keyP: premult = not premult
  else: return


proc main() =
  glfw.init()

  var fps = initGraph(GRAPH_RENDER_FPS, "Frame Time")

  var win = newGlWin(
    dim = (w: 1000, h: 600),
    title = "",
    resizable = true,
    bits = (8, 8, 8, 8, 8, 16),
    version = glv20
    #ifdef DEMO_MSAA
    # glfwWindowHint(GLFW_SAMPLES, 4)
    # #endif
    #
  )

  win.keyCb = keyCb
  glfw.makeContextCurrent(win)

  var vg = nvgInit(getProcAddress)
  if vg == nil:
    quit "Error creating NanoVG context"

  if not gladLoadGL(getProcAddress):
    quit "Error initialising OpenGL"

  var data: DemoData

  if not loadDemoData(vg, data):
    quit "Could not load demo data"

  #glfw.swapInterval(1)
  glfw.swapInterval(1)

  setTime(0)
  var prevt = getTime()

  while not win.shouldClose:
    var
      t = getTime()
      dt = t - prevt
      prevt = t

    updateGraph(fps, dt)

    var
      (mx, my) = win.cursorPos()
      (winWidth, winHeight) = win.size
      (fbWidth, fbHeight) = win.framebufSize
      pxRatio = float(fbWidth) / float(winWidth)

    # Update and render
    glViewport(GLint(0), GLint(0), GLsizei(fbWidth), GLsizei(fbHeight))

    if premult:
      glClearColor(0, 0, 0, 0)
    else:
      glClearColor(0.3, 0.3, 0.32, 1.0)

    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or
            GL_STENCIL_BUFFER_BIT)

    vg.beginFrame(cint(winWidth), cint(winHeight), pxRatio)

    renderDemo(vg, mx, my, float(winWidth), float(winHeight), t, blowup, data)
    renderGraph(vg, 5, 5, fps)

    vg.endFrame()

    #if screenshot:
    #  screenshot = false
    #  saveScreenShot(fbWidth, fbHeight, premult, "dump.png")

    glfw.swapBufs(win)
    glfw.pollEvents()

  freeDemoData(vg, data)
  nvgDeleteGL2(vg)
  glfw.terminate()


main()
