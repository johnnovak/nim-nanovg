import glfw
from glfw/wrapper import getProcAddress
import nanovg


glfw.init()

var win = newGlWin(
  dim = (w: 400, h: 300),
  title = "Simple",
  resizable = true,
  bits = (8, 8, 8, 8, 8, 16),
  version = glv20
)

glfw.makeContextCurrent(win)

var vg = nvgInit(getProcAddress)
if vg == nil:
  quit "Error creating NanoVG context"

glfw.swapInterval(1)

while not win.shouldClose:
  glfw.swapBufs(win)
  glfw.pollEvents()

#  nvgDeleteGL2(vg)
glfw.terminate()

