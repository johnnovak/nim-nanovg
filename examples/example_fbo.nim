import math
import strformat

import glfw

import glad/gl
import nanovg
import perf


proc renderPattern(vg: NVGContext, fb: NVGLUFramebuffer, t, pxRatio: float) =
  if fb == nil: return

  let
    (fboWidth, fboHeight) = vg.imageSize(fb.image)
    winWidth = floor(fboWidth.float / pxRatio)
    winHeight = floor(fboHeight.float / pxRatio)

  # Draw some stuff to an FBO as a test
  nvgluBindFramebuffer(fb)

  glViewport(0, 0, fboWidth.GLsizei, fboHeight.GLsizei)
  glClearColor(0, 0, 0, 0)
  glClear(GL_COLOR_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)

  vg.beginFrame(winWidth, winHeight, pxRatio)

  let
    s = 20.0
    sr = (cos(t)+1) * 0.5
    r = s*0.6 * (0.2 + 0.8*sr)
    pw = ceil(winWidth/s).int
    ph = ceil(winHeight/s).int

  vg.beginPath()

  for y in  0..<ph:
    for x in 0..<pw:
      let cx = (x.float + 0.5) * s
      let cy = (y.float + 0.5) * s
      vg.circle(cx, cy, r)

  vg.fillColor(rgba(220, 160, 0, 200))
  vg.fill()

  vg.endFrame()
  nvgluBindFramebuffer(nil)


proc loadFonts(vg: NVGcontext): bool =
  var font = vg.createFont("sans", "data/Roboto-Regular.ttf")
  if font == NoFont:
    echo "Could not load regular font."
    return false

  font = vg.createFont("sans-bold", "data/Roboto-Bold.ttf")
  if font == NoFont:
    echo "Could not load bold font."
    return false

  return true


proc keyCb(win: Window, key: Key, scanCode: int32, action: KeyAction,
           modKeys: set[ModifierKey]) =

  if action != kaDown: return
  case key
  of keyEscape: win.shouldClose = true
  else: return


proc createWindow(): Window =
  var cfg = DefaultOpenglWindowConfig
  cfg.size = (w: 1000, h: 600)
  cfg.title = "NanoVG FBO Demo"
  cfg.resizable = true
  cfg.bits = (r: 8, g: 8, b: 8, a: 8, stencil: 8, depth: 16)
  cfg.debugContext = true

  when not defined(windows):
    cfg.version = glv32
    cfg.forwardCompat = true
    cfg.profile = opCoreProfile

  newWindow(cfg)


proc main() =
  glfw.initialize()

  var win = createWindow()
  win.keyCb = keyCb

  glfw.makeContextCurrent(win)

  nvgInit(getProcAddress)
  var vg = nvgCreateContext({nifStencilStrokes, nifDebug, nifAntialias})

  if not gladLoadGL(getProcAddress):
    quit "Error initialising OpenGL"

  let
    (winWidth, _) = win.size
    (fbWidth, _) = win.framebufferSize
    pxRatio = fbWidth / winWidth

  var fb = vg.nvgluCreateFramebuffer(
    width  = 100 * pxRatio.int,
    height = 100 * pxRatio.int,
    {ifRepeatX, ifRepeatY}
  )

  if fb == nil:
    quit "Could not create FBO"

  if not loadFonts(vg):
    quit "Could not load fonts"

  glfw.swapInterval(0)

  var fps      = initGraph(grsFramesPerSec, "Frame Time")
  var cpuGraph = initGraph(grsMilliseconds, "CPU Time")
  var gpuGraph = initGraph(grsMilliseconds, "GPU Time")

  var gpuTimer: GpuTimer
  setTime(0)
  var prevt = getTime()

  while not win.shouldClose:
    var
      t = getTime()
      dt = t - prevt
      gpuTimes: array[3, float]

    prevt = t

    startGpuTimer(gpuTimer)

    var
      (winWidth, winHeight) = win.size
      (fbWidth, fbHeight) = win.framebufferSize

      # Calculate pixel ration for hi-dpi devices.
      pxRatio = fbWidth / winWidth

    renderPattern(vg, fb, t, pxRatio)

    # Update and render
    glViewport(0, 0, fbWidth, fbHeight)
    glClearColor(0.3, 0.3, 0.32, 1.0)

    glClear(GL_COLOR_BUFFER_BIT or
            GL_DEPTH_BUFFER_BIT or
            GL_STENCIL_BUFFER_BIT)

    vg.beginFrame(winWidth.float, winHeight.float, pxRatio)

    # Use the FBO as image pattern.
    if fb != nil:
      var img = vg.imagePattern(0, 0, 100, 100, 0, fb.image, 1.0)
      vg.save()

      for i in 0..<20:
        vg.beginPath()
        vg.rect(10 + i.float * 30, 10, 10, winHeight.float - 20)
        vg.fillColor(hsla(i.float/19, 0.5, 0.5, 255))
        vg.fill()

      vg.beginPath()
      vg.roundedRect(
        x = 140 + sin(t*1.3) * 100,
        y = 140 + cos(t*1.71244) * 100,
        w = 250, h = 250, r = 20
      )
      vg.fillPaint(img)
      vg.fill()
      vg.strokeColor(rgba(220, 160, 0, 255))
      vg.strokeWidth(3.0)
      vg.stroke()

      vg.restore()

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

    glfw.swapBuffers(win)
    glfw.pollEvents()


  nvgluDeleteFramebuffer(fb)

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
