import strformat

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
  of keyS: screenshot = true  # TODO
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
    cfg.version = glv32
    cfg.forwardCompat = true
    cfg.profile = opCoreProfile

  when defined(demoMSAA):
    cfg.nMultiSamples = 4

  newWindow(cfg)


proc main() =
  glfw.initialize()

  var win = createWindow()
  win.keyCb = keyCb

  glfw.makeContextCurrent(win)

  var flags = {nifStencilStrokes, nifDebug}
  when not defined(demoMSAA): flags = flags + {nifAntialias}

  nvgInit(getProcAddress)
  var vg = nvgCreateContext(flags)

  if not gladLoadGL(getProcAddress):
    quit "Error initialising OpenGL"

  var data: DemoData
  if not loadDemoData(vg, data):
    quit "Could not load demo data"

  var fps      = initGraph(grsFramesPerSec, "Frame Time")
  var cpuGraph = initGraph(grsMilliseconds, "CPU Time")
  var gpuGraph = initGraph(grsMilliseconds, "GPU Time")

  var gpuTimer: GPUtimer
  setTime(0)
  var prevt = getTime()

  while not win.shouldClose:
    var
      t = getTime()
      dt = t - prevt
      gpuTimes: array[3, float]

    prevt = t

    if vsync:
      glfw.swapInterval(1)
    else:
      glfw.swapInterval(0)

    startGPUTimer(gpuTimer)

    var
      (mx, my) = win.cursorPos()
      (winWidth, winHeight) = win.size
      (fbWidth, fbHeight) = win.framebufferSize

      # Calculate pixel ration for hi-dpi devices.
      pxRatio = fbWidth / winWidth

    # Update and render
    glViewport(0, 0, fbWidth, fbHeight)

    if premult:
      glClearColor(0, 0, 0, 0)
    else:
      glClearColor(0.3, 0.3, 0.32, 1.0)

    glClear(GL_COLOR_BUFFER_BIT or
            GL_DEPTH_BUFFER_BIT or
            GL_STENCIL_BUFFER_BIT)

    vg.beginFrame(winWidth.float, winHeight.float, pxRatio)

    renderDemo(vg, mx, my, winWidth.float, winHeight.float, t, blowup, data)

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

    if screenshot:
      screenshot = false
    #  saveScreenShot(fbWidth, fbHeight, premult, "dump.png")   // TODO

    glfw.swapBuffers(win)
    glfw.pollEvents()


  freeDemoData(vg, data)

  nvgDeleteContext(vg)

  let
    frameTime = getGraphAverage(fps)      * 1000
    cpuTime   = getGraphAverage(cpuGraph) * 1000
    gpuTime   = getGraphAverage(gpuGraph) * 1000

  echo fmt"Average Frame Time: {frameTime:6.2f} ms"
  echo fmt"          CPU Time: {cpuTime:6.2f} ms"
  echo fmt"          GPU Time: {gpuTime:6.2f} ms"

  glfw.terminate()


main()
