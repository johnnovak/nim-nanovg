import math
import strutils

import glad/gl
import glfw
import glfw/wrapper as glfwWrapper

import nanovg
import demo
import perf


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
  var cpuGraph = initGraph(GRAPH_RENDER_MS, "CPU Time");
  var gpuGraph = initGraph(GRAPH_RENDER_MS, "GPU Time");

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

  glfw.swapInterval(0)

  var gpuTimer: GPUtimer
  setTime(0)
  var prevt = getTime()

  while not win.shouldClose:
    var
      t = getTime()
      dt = t - prevt
      prevt = t
      gpuTimes: array[3, float]

    startGPUTimer(gpuTimer)

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

    vg.beginFrame(winWidth, winHeight, pxRatio)

    renderDemo(vg, mx, my, float(winWidth), float(winHeight), t, blowup, data)

    renderGraph(vg, 5, 5, fps)
    renderGraph(vg, 5+200+5, 5, cpuGraph)
    if gpuTimer.supported:
      renderGraph(vg, 5+200+5+200+5, 5, gpuGraph)

    vg.endFrame()

    # Measure the CPU time taken excluding swap buffers (as the swap may wait
    # for GPU)
    var cpuTime = getTime() - t

    updateGraph(fps, dt)
    updateGraph(cpuGraph, cpuTime)

    # We may get multiple results.
    var n = stopGPUTimer(gpuTimer)
    for i in 0..<n:
      updateGraph(gpuGraph, gpuTimes[i])

    #if screenshot:
    #  screenshot = false
    #  saveScreenShot(fbWidth, fbHeight, premult, "dump.png")

    glfw.swapBufs(win)
    glfw.pollEvents()

  freeDemoData(vg, data)

  nvgDelete(vg)

  let
    frameTime = (getGraphAverage(fps) * 1000.0).formatFloat(ffDecimal, 2)
    cpuTime = (getGraphAverage(cpuGraph) * 1000.0).formatFloat(ffDecimal, 2)
    gpuTime = (getGraphAverage(gpuGraph) * 1000.0).formatFloat(ffDecimal, 2)

  echo "Average Frame Time: " & frameTime & " ms"
  echo "          CPU Time: " & cpuTime & " ms"
  echo "          GPU Time: " & gpuTime & " ms"

  glfw.terminate()


main()
