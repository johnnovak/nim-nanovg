# Package

version       = "0.4.0"
author        = "John Novak <john@johnnovak.net>"
description   = "Nim wrapper for the NanoVG vector graphics library for OpenGL"
license       = "MIT"

skipDirs = @["doc", "examples"]


# Dependencies

requires "nim >= 2.0.6"

task examplesGL2Debug, "Compiles the examples":
  exec "nim c -d:debug -D:glfwStaticLib -D:demoMSAA -D:nvgGL2 examples/example_gl2.nim"
  exec "nim c -d:debug -D:glfwStaticLib -D:demoMSAA -D:nvgGL2 examples/multiwindow.nim"
  exec "nim c -d:debug -D:glfwStaticLib -D:demoMSAA -D:nvgGL2 examples/pixelperfect.nim"
  exec "nim c -d:debug -D:glfwStaticLib -D:demoMSAA -D:nvgGL2 examples/simple_gl2.nim"

task examplesGL3Debug, "Compiles the examples":
  exec "nim c -d:debug -D:glfwStaticLib -D:demoMSAA -D:nvgGL3 examples/example_gl3.nim"
  exec "nim c -d:debug -D:glfwStaticLib -D:demoMSAA -D:nvgGL3 examples/multiwindow.nim"
  exec "nim c -d:debug -D:glfwStaticLib -D:demoMSAA -D:nvgGL3 examples/pixelperfect.nim"
  exec "nim c -d:debug -D:glfwStaticLib -D:demoMSAA -D:nvgGL3 examples/simple_gl3.nim"
  exec "nim c -d:debug -D:glfwStaticLib -D:nvgGL3 examples/example_fbo.nim"

task examplesGL2, "Compiles the examples":
  exec "nim c -d:release -D:glfwStaticLib -D:demoMSAA -D:nvgGL2 examples/example_gl2.nim"
  exec "nim c -d:release -D:glfwStaticLib -D:demoMSAA -D:nvgGL2 examples/multiwindow.nim"
  exec "nim c -d:release -D:glfwStaticLib -D:demoMSAA -D:nvgGL2 examples/pixelperfect.nim"
  exec "nim c -d:release -D:glfwStaticLib -D:demoMSAA -D:nvgGL2 examples/simple_gl2.nim"

task examplesGL3, "Compiles the examples":
  exec "nim c -d:release -D:glfwStaticLib -D:demoMSAA -D:nvgGL3 examples/example_gl3.nim"
  exec "nim c -d:release -D:glfwStaticLib -D:demoMSAA -D:nvgGL3 examples/multiwindow.nim"
  exec "nim c -d:release -D:glfwStaticLib -D:demoMSAA -D:nvgGL3 examples/pixelperfect.nim"
  exec "nim c -d:release -D:glfwStaticLib -D:demoMSAA -D:nvgGL3 examples/simple_gl3.nim"
  exec "nim c -d:release -D:glfwStaticLib -D:nvgGL3 examples/example_fbo.nim"

task docgen, "Generate HTML documentation":
  exec "nim doc -D:nvgGL3 -o:doc/nanovg.html nanovg"
  exec "nim doc -D:nvgGL3 -o:doc/wrapper.html nanovg/wrapper"
