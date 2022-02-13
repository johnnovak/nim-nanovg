# nim-nanovg

*Nim wrapper for the C [NanoVG](https://github.com/memononen/nanovg)
antialiased vector graphics rendering library for OpenGL*

## Installation

**nim-nanovg** can be installed via Nimble:

    nimble install nanovg

## Usage

Have a look at `demo.nim` in the [examples](/examples) directory. You can
build the examples by executing one of the following command:

    nimble examplesGL2
    nimble examplesGL2Debug
    nimble examplesGL3
    nimble examplesGL3Debug

The examples require [nim-glfw](https://github.com/ephja/nim-glfw).

## Documentation

The [API documentation](/doc) is in-progress; currently, it's a slightly
edited version of the original NanoVG source comments.

You can also check out the [NanoVG README](https://github.com/memononen/nanovg)
for further info.

## Notes

Attempting to compile the library on **Mac OS X 10.14.5 Mojave** / **XCode
11.3.1** with the GL2 backend results in compilation errors. I can't be
bothered fixing this as GL3 works fine.

