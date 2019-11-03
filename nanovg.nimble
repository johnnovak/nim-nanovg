# Package

version       = "0.1.0"
author        = "John Novak <john@johnnovak.net>"
description   = "Nim wrapper for the NanoVG graphics library"
license       = "WTFPL"

skipDirs = @["doc", "examples", "img"]


# Dependencies

requires "nim >= 1.0.2"

task examples, "Compiles the examples":
  exec "nim c -D:glfwStaticLib -D:demoMSAA -D:nvgGL2 examples/example_gl2.nim"
  exec "nim c -D:glfwStaticLib -D:demoMSAA -D:nvgGL2 examples/simple_gl2.nim"
  exec "nim c -D:glfwStaticLib -D:demoMSAA -D:nvgGL3 examples/example_gl3.nim"
  exec "nim c -D:glfwStaticLib -D:demoMSAA -D:nvgGL3 examples/simple_gl3.nim"

task docgen, "Generate HTML documentation":
  exec "nim doc -D:nvgGL3 -o:doc/nanovg.html nanovg"
  exec "nim doc -D:nvgGL3 -o:doc/wrapper.html nanovg/wrapper"
