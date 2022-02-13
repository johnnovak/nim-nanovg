import glfw

import glad/gl
import nanovg


glfw.initialize()

var cfg = DefaultOpenglWindowConfig
cfg.size = (w: 400, h: 400)
cfg.title = "NanoVG Simple GL3"
cfg.resizable = true
cfg.bits = (r: 8, g: 8, b: 8, a: 8, stencil: 8, depth: 16)

when not defined(windows):
  cfg.version = glv32
  cfg.forwardCompat = true
  cfg.profile = opCoreProfile

var win = newWindow(cfg)

glfw.makeContextCurrent(win)

nvgInit(getProcAddress)
var vg = nvgCreateContext()

if not gladLoadGL(getProcAddress):
  quit "Error initialising OpenGL"

glfw.swapInterval(1)

while not win.shouldClose:
  glfw.swapBuffers(win)
  glfw.pollEvents()

nvgDeleteContext(vg)
glfw.terminate()

