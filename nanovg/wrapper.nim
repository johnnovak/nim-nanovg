import os, strformat

## *This is a slightly edited version of the documentation provided in the
## original NanoVG C header file. While it's usable as it is, most of it
## should be revisited and reworded in better English.*
##
## # Drawing
##
## Calls to the NanoVG drawing API should be wrapped in `beginFrame()`
## & `endFrame()`. `beginFrame()` defines the size of the window to render to
## in relation to the currently set viewport (i.e. `glViewport` on GL
## backends). Device pixel ratio allows to control the rendering on Hi-DPI
## devices. For example, GLFW returns two dimensions for an opened window:
## window size and frame buffer size. In that case you would set the window
## size to `windowWidth` &  `windowHeight` and `devicePixelRatio` to
## `frameBufferWidth / windowWidth`.
##
## # Composite operations
##
## The composite operations in NanoVG are modeled after HTML Canvas API, and
## the blend function is based on OpenGL (see corresponding manuals for more
## info). The colors in the blending state have premultiplied alpha.
##
## # Color
##
## Colors in NanoVG are stored as unsigned ints in ABGR format.
##
## # State
##
## NanoVG contains state which represents how paths will be rendered. The
## state contains transforms, fill and stroke styles, text and font styles,
## and scissor clipping.
##
## # Render styles
##
## Fill and stroke render style can be either a solid color or a paint which
## is a gradient or a pattern.  Solid color is simply defined as a color
## value, different kinds of paints can be created using `linearGradient()`,
## `boxGradient()`, `radialGradient()` and `imagePattern()`.
##
## Current render style can be saved and restored using `save()` and
## `restore()`.
##
## # Transforms
##
## Paths, gradients, patterns and the scissor region are transformed by
## a transformation matrix at the time when they are passed to the API.
##
## The current transformation matrix is an affine matrix:
##
## ```
##   [sx kx tx]
##   [ky sy ty]
##   [ 0  0  1]
## ```
##
## Where: `sx` & `sy` define scaling, `kx` & `ky` skewing, and `tx` & `ty`
## translation.
## The last row is assumed to be `0, 0, 1` and is not stored.
##
## Apart from `resetTransform()`, each transformation function first creates
## a specific transformation matrix and pre-multiplies the current
## transformation by it.
##
## Current coordinate system (transformation) can be saved and restored using
## `save()` and `restore()`.
##
## # Images
##
## NanoVG allows the loading of JPG, PNG, PSD, TGA, PIC and GIF files to be
## used for rendering. The image loading is provided by `stb_image`.
##
## # Paints
##
## NanoVG supports four types of paints: linear gradient, box gradient,
## radial gradient and image pattern.  These can be used as paints for
## strokes and fills.
##
## # Scissoring
##
## Scissoring allows you to clip the rendering into a rectangle. This is
## useful for various user interface cases like rendering a text edit box or
## a timeline.
##
## # Paths
##
## Drawing a new shape starts with `beginPath()` which clears all the
## currently defined paths. Then you need to define one or more paths and
## sub-paths which describe the shape. There are functions to draw common
## shapes like rectangles and circles, and lower level step-by-step functions,
## which allow you to define a path curve by curve.
##
## NanoVG uses even-odd fill rule to draw the shapes. Solid shapes should have
## counter-clockwise winding and holes should have counter clockwise order. To
## specify winding of a path you can call `pathWinding()`. This is useful
## especially for the common shapes, which are drawn counter-clockwise.
##
## Finally you can fill the path using current fill style by calling
## `fill()` and stroke it with current stroke style by calling `stroke()`.
##
## The curve segments and sub-paths are transformed by the current transform.
##
## # Text
##
## NanoVG allows you to load TrueType fonts (.TTF) to render text.
##
## The appearance of the text can be defined by setting the current text style
## and by specifying the fill color. Common text and font settings such as
## font size, letter spacing and text align are supported. Font blur allows
## you to create simple text effects such as drop shadows.
##
## At render time the font face can be set based on the font handles or name.
##
## Font measuring functions return values in local space, the calculations are
## carried out in the same resolution as the final rendering. This is done
## because the text glyph positions are snapped to the nearest pixels sharp
## rendering.
##
## The local space means that values are not rotated or scaled as per the
## current transformation. For example if you set font size to 12, which would
## mean that line height is 16, then regardless of the current scaling and
## rotation, the returned line height is always 16. Some measures may vary
## because of the scaling since aforementioned pixel snapping.
##
## While this may sound a little odd, the setup allows you to always render
## the same way regardless of scaling. I.e. following works regardless of
## scaling:
##
## ```
## val txt = "Text me up."
## val b = nvg.textBounds(x, y, txt)
## nvg.beginPath()
## nvg.roundedRect(b.b[0], b.b[1], b.b[2] - b.b[0], b.b[3] - b.b[1])
## nvg.fill()
## ```
##
## Note: currently only solid color fill is supported for text.

const
  currentDir = splitPath(currentSourcePath).head

const GLVersion* =
  when defined(nvgGL2): "GL2"
  elif defined(nvgGL3): "GL3"
  elif defined(nvgGLES2): "GLES2"
  elif defined(nvgGLES3): "GLES3"
  elif defined(ios) or defined(android): "GLES3"
  else: "GL3"

{.passC: fmt" -I{currentDir}/deps/stb -DNANOVG_{GLVersion}_IMPLEMENTATION",
  compile: "src/nanovg.c".}

when defined(android) or defined(ios):
  # TODO: iOS is not yet tested, includes might be different.
  when defined(nvgGLES2):
    {.emit: fmt"#include <GLES2/gl2.h>".}

  elif defined(nvgGLES3):
    {.emit: fmt"#include <GLES3/gl3.h>".}
else:
  {.compile: "deps/glad.c".}
  {.emit: fmt"""#include "{currentDir}/deps/glad/glad.h" """.}

{.emit: fmt"""
#include "{currentDir}/src/nanovg.h"
#include "{currentDir}/src/nanovg_gl.h"
#include "{currentDir}/src/nanovg_gl_utils.h"
""".}

#{{{ Types ------------------------------------------------------------------

type
  Font* = distinct cint
  Image* = distinct cint

# TODO probably not the greatest idea for error handling... use exceptions
# instead when font loading fails?
# TODO this is probably broken
proc `==`*(x, y: Font): bool {.borrow.}
proc `==`*(x, y: Image): bool {.borrow.}

var NoFont* = Font(-1)
var NoImage* = Image(0)

type
  NVGContextObj* {.byCopy.} = object
  NVGContext* = ptr NVGContextObj

  Color* {.byCopy.} = object
    r*: cfloat
    g*: cfloat
    b*: cfloat
    a*: cfloat

  Paint* {.byCopy.} = object
    xform*:      array[6, cfloat]
    extent*:     array[2, cfloat]
    radius*:     cfloat
    feather*:    cfloat
    innerColor*: Color
    outerColor*: Color
    image*:      Image

  PathWinding* = enum
    pwCCW = (1, "CCW")
    pwCW  = (2, "CW")

  Solidity* = enum
    sSolid = (1, "Solid")
    sHole  = (2, "Hole")

  LineCapJoin* = enum
    lcjButt   = (0, "Butt")
    lcjRound  = (1, "Round")
    lcjSquare = (2, "Square")
    lcjBevel  = (3, "Bevel")
    lcjMiter  = (4, "Miter")

  HorizontalAlign* = enum
    haLeft     = (1 shl 0, "Left")
    ## Default, align text horizontally to left.

    haCenter   = (1 shl 1, "Center")
    ## Align text horizontally to center.

    haRight    = (1 shl 2, "Right")
    ## Align text horizontally to right.


  VerticalAlign* = enum
    vaTop      = (1 shl 3, "Top")
    ## Align text vertically to top.

    vaMiddle   = (1 shl 4, "Middle")
    ## Align text vertically to middle.

    vaBottom   = (1 shl 5, "Bottom")
    ## Align text vertically to bottom.

    vaBaseline = (1 shl 6, "Baseline")
    ## Default, align text vertically to baseline.


  BlendFactor* = enum
    bfZero                     = (0, "Zero")
    bfOne                      = (1, "One")
    bfSourceColor              = (2, "SourceColor")
    bfOneMinusSourceColor      = (3, "OneMinusSourceColor")
    bfDestinationColor         = (4, "DestinationColor")
    bfOneMinusDestinationColor = (5, "OneMinusDestinationColor")
    bfSourceAlpha              = (6, "SourceAlpha")
    bfOneMinusSourceAlpha      = (7, "OneMinusSourceAlpha")
    bfDestinationAlpha         = (8, "DestinationAlpha")
    bfOneMinusDestinationAlpha = (9, "OneMinusDestinationAlpha")
    bfSourceAlphaSaturate      = (10, "SourceAlphaSaturate")

  CompositeOperation* = enum
    coSourceOver      = (0, "SourceOver")
    coSourceIn        = (1, "SourceIn")
    coSourceOut       = (2, "SourceOut")
    coAtop            = (3, "Atop")
    coDestinationOver = (4, "DestinationOver")
    coDestinationIn   = (5, "DestinationIn")
    coDestinationOut  = (6, "DestinationOut")
    coDestinationAtop = (7, "DestinationAtop")
    coLighter         = (8, "Lighter")
    coCopy            = (9, "Copy")
    coXor             = (10, "Xor")

  ImageFlags* = enum
    ifGenerateMipmaps = (0, "GenerateMipmaps")
    ## Generate mipmaps during creation of the image.

    ifRepeatX         = (1, "RepeatX")
    ## Repeat image in X direction.

    ifRepeatY         = (2, "RepeatY")
    ## Repeat image in Y direction.

    ifFlipY           = (3, "FlipY")
    ## Flips (inverses) image in Y direction when rendered.

    ifPremultiplied   = (4, "Premultiplied")
    ## Image data has premultiplied alpha.

    ifNearest         = (5, "Nearest")
    ## Image interpolation is Nearest instead Linear


  CompositeOperationState* {.bycopy.} = object
    srcRGB*:   cint
    dstRGB*:   cint
    srcAlpha*: cint
    dstAlpha*: cint

  GlyphPosition* {.bycopy.} = object
    str*:  cstring
    ## Position of the glyph in the input string.

    x*:    cfloat
    ##  The x-coordinate of the logical glyph position.

    minX*: cfloat
    maxX*: cfloat
    ##  The bounds of the glyph shape.

  TransformMatrix* = object
    m*: array[6, cfloat]

  Bounds* {.bycopy.} = object
    x1*, y1*, x2*, y2*: cfloat

  TextRow* {.bycopy.} = object
    startPtr*: cstring
    ## Pointer to the input text where the row starts.

    endPtr*: cstring
    ## Pointer to the input text where the row ends (one past the last
    ## character).

    nextPtr*:  cstring
    ## Pointer to the beginning of the next row.

    width*: cfloat
    ## Logical width of the row.

    minX*:  cfloat
    maxX*:  cfloat
    ## Actual bounds of the row. Logical with and bounds can differ because of
    ## kerning and some parts over extending.


  NvgInitFlag* {.size: cint.sizeof.} = enum
    nifAntialias      = (0, "Antialias")
    ## Flag indicating if geometry based anti-aliasing is used
    ## (may not be needed when using MSAA).

    nifStencilStrokes = (1, "StencilStrokes")
    ## Flag indicating if strokes should be drawn using stencil buffer.
    ## The rendering will be a little slower, but path overlaps (i.e.
    ## self-intersecting or sharp turns) will be drawn just once.

    nifDebug          = (2, "Debug")
    ## Flag indicating that additional debug checks are done.

#}}}

using ctx: NVGContext

#{{{ Context ----------------------------------------------------------------

# Creates NanoVG contexts for different OpenGL (ES) versions.
# Flags should be combination of the create flags above.

when GLVersion == "GL2":
  proc nvgCreateContext*(flags: set[NvgInitFlag]): NVGContext
      {.cdecl, importc: "nvgCreateGL2".}

  proc nvgDeleteContext*(ctx: NVGContext) {.cdecl, importc: "nvgDeleteGL2".}

elif GLVersion == "GL3":
  proc nvgCreateContext*(flags: set[NvgInitFlag]): NVGContext
      {.cdecl, importc: "nvgCreateGL3".}

  proc nvgDeleteContext*(ctx: NVGContext) {.cdecl, importc: "nvgDeleteGL3".}

elif GLVersion == "GLES2":
  proc nvgCreateContext*(flags: set[NvgInitFlag]): NVGContext
      {.cdecl, importc: "nvgCreateGLES2".}

  proc nvgDeleteContext*(ctx: NVGContext) {.cdecl, importc: "nvgDeleteGLES2".}

elif GLVersion == "GLES3":
  proc nvgCreateContext*(flags: set[NvgInitFlag]): NVGContext
      {.cdecl, importc: "nvgCreateGLES3".}

  proc nvgDeleteContext*(ctx: NVGContext) {.cdecl, importc: "nvgDeleteGLES3".}

#}}}
#{{{ Drawing ----------------------------------------------------------------

proc beginFrame*(ctx; windowWidth: cfloat, windowHeight: cfloat,
                 devicePixelRatio: cfloat) {.cdecl, importc: "nvgBeginFrame".}
  ## Begin drawing a new frame.

proc cancelFrame*(ctx: NVGContext) {.cdecl, importc: "nvgCancelFrame".}
  ## Cancel drawing the current frame.

proc endFrame*(ctx: NVGContext) {.cdecl, importc: "nvgEndFrame".}
  ## End drawing flushing remaining render state.

#}}}
#{{{ Composite operations ---------------------------------------------------

proc globalCompositeOperation*(ctx; op: CompositeOperation)
    {.cdecl, importc: "nvgGlobalCompositeOperation".}
  ## Set the composite operation.

proc globalCompositeBlendFunc*(ctx; srcFactor: set[BlendFactor],
                               destFactor: set[BlendFactor])
    {.cdecl, importc: "nvgGlobalCompositeBlendFunc".}
  ## Set the composite operation with custom pixel arithmetic.

proc globalCompositeBlendFuncSeparate*(ctx: NVGContext,
                                       srcRGB: cint, dstRGB: cint,
                                       srcAlpha: cint, dstAlpha: cint)
    {.cdecl, importc: "nvgGlobalCompositeBlendFuncSeparate".}
  ## Set the composite operation with custom pixel arithmetic for RGB and
  ## alpha components separately.

#}}}
#{{{ Color utils ------------------------------------------------------------

proc rgb*(r: byte, g: byte, b: byte): Color{.cdecl, importc: "nvgRGB".}
  ## Return a color value from red, green, blue values. Alpha will be set to
  ## 255 (1.0f).

proc rgb*(r: cfloat, g: cfloat, b: cfloat): Color {.cdecl, importc: "nvgRGBf".}
  ## Return a color value from red, green, blue values. Alpha will be set to
  ## 1.0f.

proc rgba*(r: byte, g: byte, b: byte, a: byte): Color
    {.cdecl, importc: "nvgRGBA".}
  ## Returns a color value from red, green, blue and alpha values.

proc rgba*(r: cfloat, g: cfloat, b: cfloat, a: cfloat): Color
    {.cdecl, importc: "nvgRGBAf".}
  ## Returns a color value from red, green, blue and alpha values.

proc lerp*(c1: Color, c2: Color, f: cfloat): Color
    {.cdecl, importc: "nvgLerpRGBA"}
  ## Linearly interpolates from color c0 to c1, and returns resulting color
  ## value.

proc withAlpha*(c: Color, a: byte): Color {.cdecl, importc: "nvgTransRGBA".}
  ## Sets transparency of a color value.

proc withAlpha*(c: Color, a: cfloat): Color {.cdecl, importc: "nvgTransRGBAf".}
  ## Sets transparency of a color value.

proc hsl*(h: cfloat, s: cfloat, l: cfloat): Color {.cdecl, importc: "nvgHSL".}
  ## Returns color value specified by hue, saturation and lightness.
  ## HSL values are all in range [0..1], alpha will be set to 255.

proc hsla*(h: cfloat, s: cfloat, l: cfloat,
           a: byte): Color {.cdecl, importc: "nvgHSLA".}
  ## Returns color value specified by hue, saturation and lightness and alpha.
  ## HSL values are all in range [0..1], alpha in range [0..255]

#}}}
#{{{ State handling ---------------------------------------------------------

proc save*(ctx: NVGContext) {.cdecl, importc: "nvgSave".}
  ## Pushes and saves the current render state into a state stack.
  ## A matching nvgRestore() must be used to restore the state.

proc restore*(ctx: NVGContext) {.cdecl, importc: "nvgRestore".}
  ## Pops and restores current render state.

proc reset*(ctx: NVGContext) {.cdecl, importc: "nvgReset".}
  ## Resets current render state to default values. Does not affect the render
  ## state stack.

#}}}
#{{{ Render styles ----------------------------------------------------------

proc shapeAntiAlias*(ctx; enabled: cint)
    {.cdecl, importc: "nvgShapeAntiAlias".}
  ## Sets whether to draw antialias for nvgStroke() and nvgFill().

proc strokeColor*(ctx; color: Color)
    {.cdecl, importc: "nvgStrokeColor".}
  ## Sets current stroke style to a solid color.

proc strokePaint*(ctx; paint: Paint)
    {.cdecl, importc: "nvgStrokePaint".}
  ## Sets current stroke style to a paint, which can be a one of the gradients
  ## or a pattern.

proc fillColor*(ctx; color: Color)
    {.cdecl, importc: "nvgFillColor".}
  ## Sets current fill style to a solid color.

proc fillPaint*(ctx; paint: Paint)
    {.cdecl, importc: "nvgFillPaint".}
  ## Sets current fill style to a paint, which can be a one of the gradients or
  ## a pattern.

proc miterLimit*(ctx; limit: cfloat)
  {.cdecl, importc: "nvgMiterLimit".}
  ## Sets the miter limit of the stroke style.
  ## Miter limit controls when a sharp corner is beveled.

proc strokeWidth*(ctx; size: cfloat)
    {.cdecl, importc: "nvgStrokeWidth".}
  ## Sets the stroke width of the stroke style.

proc lineCap*(ctx; cap: LineCapJoin)
    {.cdecl, importc: "nvgLineCap".}
  ## Sets how the end of the line (cap) is drawn.

proc lineJoin*(ctx; join: LineCapJoin)
    {.cdecl, importc: "nvgLineJoin".}
  ## Sets how sharp path corners are drawn.

proc globalAlpha*(ctx; alpha: cfloat)
    {.cdecl, importc: "nvgGlobalAlpha".}
  ## Sets the transparency applied to all rendered shapes.  Already
  ## transparent paths will get proportionally more transparent as well.

#}}}
#{{{ Transforms -------------------------------------------------------------

proc resetTransform*(ctx: NVGContext) {.cdecl, importc: "nvgResetTransform".}
  ## Resets current transform to a identity matrix.

proc transform*(ctx: NVGContext,
                a: cfloat, b: cfloat, c: cfloat, d: cfloat, e: cfloat,
                f: cfloat) {.cdecl, importc: "nvgTransform".}
  ## Premultiplies current coordinate system by specified matrix.
  ##
  ## The parameters are interpreted as matrix as follows:
  ##
  ## ```
  ##   [a c e]
  ##   [b d f]
  ##   [0 0 1]
  ## ```

proc translate*(ctx; tx: cfloat, ty: cfloat)
    {.cdecl, importc: "nvgTranslate".}
  ## Translates current coordinate system.

proc rotate*(ctx; angle: cfloat) {.cdecl, importc: "nvgRotate".}
  ## Rotates current coordinate system. Angle is specified in radians.

proc skewX*(ctx; angle: cfloat) {.cdecl, importc: "nvgSkewX".}
  ## Skews the current coordinate system along X axis. Angle is specified in
  ## radians.

proc skewY*(ctx; angle: cfloat) {.cdecl, importc: "nvgSkewY".}
  ## Skews the current coordinate system along Y axis. Angle is specified in
  ## radians.

proc scale*(ctx; sx: cfloat, sy: cfloat)
  {.cdecl, importc: "nvgScale".}
  ## Scales the current coordinate system.

proc nvgCurrentTransform*(ctx; xform: ptr cfloat)
  {.cdecl, importc: "nvgCurrentTransform".}
  ## Stores the top part (a-f) of the current transformation matrix in to the
  ## specified buffer.
  ##
  ## ```
  ##    [a c e]
  ##    [b d f]
  ##    [0 0 1]
  ## ```
  ##
  ## There should be space for 6 floats in the return buffer for the values a-f.

proc nvgIdentity*(dst: ptr cfloat)
    {.cdecl, importc: "nvgTransformIdentity".}
  ## Sets the transform to identity matrix.

proc nvgTranslate*(dst: ptr cfloat, tx: cfloat, ty: cfloat)
    {.cdecl, importc: "nvgTransformTranslate".}
  ## Sets the transform to translation matrix matrix.

proc nvgScale*(dst: ptr cfloat, sx: cfloat, sy: cfloat)
    {.cdecl, importc: "nvgTransformScale".}
  ## Sets the transform to scale matrix.

proc nvgRotate*(dst: ptr cfloat, angle: cfloat)
    {.cdecl, importc: "nvgTransformRotate".}
  ## Sets the transform to rotate matrix. Angle is specified in radians.

proc nvgSkewX*(dst: ptr cfloat, angle: cfloat)
    {.cdecl, importc: "nvgTransformSkewX".}
  ## Sets the transform to skew-x matrix. Angle is specified in radians.

proc nvgSkewY*(dst: ptr cfloat, angle: cfloat)
    {.cdecl, importc: "nvgTransformSkewY".}
  ## Sets the transform to skew-y matrix. Angle is specified in radians.

proc nvgMultiply*(dst: ptr cfloat, src: ptr cfloat)
    {.cdecl, importc: "nvgTransformMultiply".}
  ## Sets the transform to the result of multiplication of two transforms, of
  ## A = A * B.

proc nvgPremultiply*(dst: ptr cfloat, src: ptr cfloat)
    {.cdecl, importc: "nvgTransformPremultiply".}
  ## Sets the transform to the result of multiplication of two transforms, of
  ## A = B * A.

proc nvgInverse*(dst: ptr cfloat, src: ptr cfloat): cint
    {.cdecl, importc: "nvgTransformInverse".}
  ## Sets the destination to inverse of specified transform.
  ## Returns 1 if the inverse could be calculated, else 0.

proc nvgTransformPoint*(destX: ptr cfloat, destY: ptr cfloat,
                        xform: ptr cfloat, srcX: cfloat,
                        srcY: cfloat) {.cdecl, importc: "nvgTransformPoint".}
  ## Transform a point by given transform.

proc degToRad*(deg: cfloat): cfloat {.cdecl, importc: "nvgDegToRad".}
  ## Convert degrees to radians.

proc radToDeg*(rad: cfloat): cfloat {.cdecl, importc: "nvgRadToDeg".}
  ## Converts radians to degrees.

#}}}
#{{{ Images -----------------------------------------------------------------

proc createImage*(ctx; filename: cstring,
                  imageFlags: set[ImageFlags] = {}): Image
    {.cdecl, importc: "nvgCreateImage".}
  ## Creates image by loading it from the disk from specified file name.
  ## Returns handle to the image.

proc createImageMem*(ctx; imageFlags: set[ImageFlags] = {},
                     data: ptr byte, ndata: cint): Image
    {.cdecl, importc: "nvgCreateImageMem".}
  ## Creates image by loading it from the specified chunk of memory.
  ## Returns handle to the image.

proc createImageRGBA*(ctx; w: cint, h: cint,
                      imageFlags: set[ImageFlags] = {},
                      data: ptr byte): Image
    {.cdecl, importc: "nvgCreateImageRGBA".}
  ## Creates image from specified image data.
  ## Returns handle to the image.

proc updateImage*(ctx; image: Image, data: ptr byte)
    {.cdecl, importc: "nvgUpdateImage".}
  ## Updates image data specified by image handle.

proc imageSize*(ctx; image: Image,
                w: ptr cint, h: ptr cint) {.cdecl, importc: "nvgImageSize".}
  ## Returns the dimensions of an image.

proc deleteImage*(ctx; image: Image) {.cdecl, importc: "nvgDeleteImage".}
  ## Deletes an image.

#}}}
#{{{ Paints -----------------------------------------------------------------

proc linearGradient*(ctx; sx, sy, ex, ey: cfloat; inCol, outCol: Color): Paint
    {.cdecl, importc: "nvgLinearGradient" .}
  ## Creates and returns a linear gradient. Parameters (sx,sy)-(ex,ey) specify
  ## the start and end coordinates of the linear gradient, icol specifies the
  ## start color and ocol the end color.
  ##
  ## The gradient is transformed by the current transform when it is passed to
  ## `fillPaint()` or `strokePaint()`.

proc boxGradient*(ctx; x, y, w, h, r, f: cfloat; inCol, outCol: Color): Paint
    {.cdecl, importc: "nvgBoxGradient".}
  ## Creates and returns a box gradient. Box gradient is a feathered rounded
  ## rectangle, it is useful for rendering drop shadows or highlights for
  ## boxes. Parameters `x` and `y` define the top-left corner of the
  ## rectangle, `w` and `h` the size of the rectangle, `r` the corner radius,
  ## and `f` the feather. Feather controls the blurriness of the border of the
  ## rectangle. `inCol` specifies the inner color and `outCol` the outer color
  ## of the gradient.
  ##
  ## The gradient is transformed by the current transform when it is passed to
  ## `fillPaint()` or `strokePaint()`.

proc radialGradient*(ctx; cx, cy, inr, outr: cfloat;
                     inCol, outCol: Color): Paint
    {.cdecl, importc: "nvgRadialGradient".}
  ## Creates and returns a radial gradient. Parameters (cx,cy) specify the
  ## center, inr and outr specify the inner and outer radius of the gradient,
  ## icol specifies the start color and ocol the end color.
  ##
  ## The gradient is transformed by the current transform when it is passed to
  ## `fillPaint()` or `strokePaint()`.

proc imagePattern*(ctx; ox, oy, ex, ey, angle: cfloat; image: Image;
                   alpha: cfloat): Paint {.cdecl, importc: "nvgImagePattern".}
  ## Creates and returns an image pattern. Parameters (ox,oy) specify the
  ## left-top location of the image pattern, (ex,ey) the size of one image,
  ## angle rotation around the top-left corner, image is handle to the image to
  ## render.
  ##
  ## The image is transformed by the current transform when it is passed to
  ## `fillPaint()` or `strokePaint()`.

#}}}
#{{{ Scissoring -------------------------------------------------------------

proc scissor*(ctx; x: cfloat, y: cfloat,
              w: cfloat, h: cfloat) {.cdecl, importc: "nvgScissor".}
  ## Sets the current scissor rectangle.
  ## The scissor rectangle is transformed by the current transform.

proc intersectScissor*(ctx; x: cfloat, y: cfloat, w: cfloat,
                       h: cfloat) {.cdecl, importc: "nvgIntersectScissor".}
  ## Intersects current scissor rectangle with the specified rectangle.  The
  ## scissor rectangle is transformed by the current transform.  Note: in case
  ## the rotation of previous scissor rect differs from the current one, the
  ## intersection will be done between the specified rectangle and the previous
  ## scissor rectangle transformed in the current transform space. The
  ## resulting shape is always rectangle.

proc resetScissor*(ctx: NVGContext) {.cdecl, importc: "nvgResetScissor".}
  ## Resets and disables scissoring.

#}}}
#{{{ Paths ------------------------------------------------------------------

proc beginPath*(ctx: NVGContext) {.cdecl, importc: "nvgBeginPath".}
  ## Clears the current path and sub-paths.

proc moveTo*(ctx: NVGContext,
             x: cfloat, y: cfloat) {.cdecl, importc: "nvgMoveTo".}
  ## Starts new sub-path with specified point as first point.

proc lineTo*(ctx: NVGContext,
             x: cfloat, y: cfloat) {.cdecl, importc: "nvgLineTo".}
  ## Adds line segment from the last point in the path to the specified point.

proc bezierTo*(ctx; c1x: cfloat, c1y: cfloat,
               c2x: cfloat, c2y: cfloat,
               x: cfloat, y: cfloat) {.cdecl, importc: "nvgBezierTo".}
  ## Adds cubic bezier segment from last point in the path via two control
  ## points to the specified point.

proc quadTo*(ctx; cx: cfloat, cy: cfloat,
             x: cfloat, y: cfloat) {.cdecl, importc: "nvgQuadTo".}
  ## Adds quadratic bezier segment from last point in the path via a control
  ## point to the specified point.

proc arcTo*(ctx; x1: cfloat, y1: cfloat, x2: cfloat, y2: cfloat,
            radius: cfloat) {.cdecl, importc: "nvgArcTo".}
  ## Adds an arc segment at the corner defined by the last path point, and two
  ## specified points.

proc closePath*(ctx: NVGContext) {.cdecl, importc: "nvgClosePath".}
  ## Closes current sub-path with a line segment.

proc pathWinding*(ctx; dir: PathWinding | Solidity)
    {.cdecl, importc: "nvgPathWinding".}
  ## Sets the current sub-path winding, see NVGwinding and NVGsolidity.

proc arc*(ctx; cx: cfloat, cy: cfloat, r: cfloat,
          a0: cfloat, a1: cfloat,
          dir: PathWinding | Solidity) {.cdecl, importc: "nvgArc".}
  ## Creates new circle arc shaped sub-path. The arc center is at `cx`,`cy`,
  ## the arc radius is `r`, and the arc is drawn from angle `a0` to `a1`, and
  ## swept in direction `dir`. Angles are specified in radians.

proc rect*(ctx; x: cfloat, y: cfloat,
           w: cfloat, h: cfloat) {.cdecl, importc: "nvgRect".}
  ## Creates new rectangle shaped sub-path.

proc roundedRect*(ctx; x: cfloat, y: cfloat, w: cfloat,
                  h: cfloat, r: cfloat) {.cdecl, importc: "nvgRoundedRect".}
  ## Creates new rounded rectangle shaped sub-path.

proc roundedRect*(ctx; x: cfloat, y: cfloat,
                  w: cfloat, h: cfloat, radTopLeft: cfloat,
                  radTopRight: cfloat, radBottomRight: cfloat,
                  radBottomLeft: cfloat)
    {.cdecl, importc: "nvgRoundedRectVarying".}
  ## Creates new rounded rectangle shaped sub-path with varying radii for each
  ## corner.

proc ellipse*(ctx; cx: cfloat, cy: cfloat,
              rx: cfloat, ry: cfloat) {.cdecl, importc: "nvgEllipse".}
  ## Creates new ellipse shaped sub-path.

proc circle*(ctx; cx: cfloat, cy: cfloat,
             r: cfloat) {.cdecl, importc: "nvgCircle".}
  ## Creates new circle shaped sub-path.

proc fill*(ctx: NVGContext) {.cdecl, importc: "nvgFill".}
  ## Fills the current path with current fill style.

proc stroke*(ctx: NVGContext) {.cdecl, importc: "nvgStroke".}
  ## Fills the current path with current stroke style.

#}}}
#{{{ Text -------------------------------------------------------------------

proc createFont*(ctx; name: cstring,
                 filename: cstring): Font {.cdecl, importc: "nvgCreateFont".}
  ## Creates font by loading it from the disk from specified file name.
  ## Returns handle to the font.

proc createFontAtIndex*(ctx; name: cstring, filename: cstring,
                        fontIndex: cint): Font
  {.cdecl, importc: "nvgCreateFontAtIndex".}
  ## fontIndex specifies which font face to load from a .ttf/.ttc file.

proc createFontMem*(ctx; name: cstring,
                    data: ptr byte, ndata: cint,
                    freeData: cint): Font {.cdecl, importc: "nvgCreateFontMem".}
  ## Creates font by loading it from the specified memory chunk.
  ## Returns handle to the font.

proc createFontMemAtIndex*(ctx; name: cstring,
                           data: ptr byte, ndata: cint,
                           freeData: cint, fontIndex: cint): Font
    {.cdecl, importc: "nvgCreateFontMem".}
  ## fontIndex specifies which font face to load from a .ttf/.ttc file.

proc findFont*(ctx; name: cstring): Font
    {.cdecl, importc: "nvgFindFont".}
  ## Finds a loaded font of specified name, and returns handle to it, or -1 if
  ## the font is not found.

proc addFallbackFont*(ctx; baseFont: Font, fallbackFont: Font): cint
    {.cdecl, importc: "nvgAddFallbackFontId".}
  ## Adds a fallback font by handle.

proc addFallbackFont*(ctx; baseFontName: cstring,
                      fallbackFontName: cstring): cint
    {.cdecl, importc: "nvgAddFallbackFont".}
  ## Adds a fallback font by name.

proc resetFallbackFonts*(ctx; baseFont: Font)
    {.cdecl, importc: "nvgResetFallbackFontsId".}
  # Resets fallback fonts by handle.

proc resetFallbackFonts*(ctx; baseFontName: cstring)
    {.cdecl, importc: "nvgResetFallbackFonts".}
  # Resets fallback fonts by name.

proc fontSize*(ctx; size: cfloat) {.cdecl, importc: "nvgFontSize".}
  ## Sets the font size of current text style.

proc fontBlur*(ctx; blur: cfloat) {.cdecl, importc: "nvgFontBlur".}
  ## Sets the blur of current text style.

proc textLetterSpacing*(ctx; spacing: cfloat)
    {.cdecl, importc: "nvgTextLetterSpacing".}
  ## Sets the letter spacing of current text style.

proc textLineHeight*(ctx: NVGContext,
                     lineHeight: cfloat) {.cdecl, importc: "nvgTextLineHeight".}
  ## Sets the proportional line height of current text style. The line height
  ## is specified as multiple of font size.

proc textAlign*(ctx; align: cint) {.cdecl, importc: "nvgTextAlign".}
  ## Sets the text align of current text style, see NVGalign for options.

proc fontFace*(ctx; font: Font) {.cdecl, importc: "nvgFontFaceId".}
  ## Sets the font face based on specified id of current text style.

proc fontFace*(ctx: NVGContext,
               fontName: cstring) {.cdecl, importc: "nvgFontFace".}
  ## Sets the font face based on specified name of current text style.

proc text*(ctx; x: cfloat, y: cfloat, string: cstring,
           `end`: cstring): cfloat {.cdecl, importc: "nvgText".}
  ## Draws text string at specified location. If end is specified only the
  ## sub-string up to the end is drawn.

proc textBox*(ctx; x: cfloat, y: cfloat,
              breakRowWidth: cfloat,
              string: cstring, `end`: cstring) {.cdecl, importc: "nvgTextBox".}
  ## Draws multi-line text string at specified location wrapped at the
  ## specified width. If end is specified only the sub-string up to the end is
  ## drawn.
  ##
  ## White space is stripped at the beginning of the rows, the text is split
  ## at word boundaries or when new-line characters are encountered.
  ##
  ## Words longer than the max width are slit at nearest character (i.e. no
  ## hyphenation).

proc textBounds*(ctx; x: cfloat, y: cfloat,
                 string: cstring, `end`: cstring,
                 bounds: ptr cfloat): cfloat {.cdecl, importc: "nvgTextBounds".}
  ## Measures the specified text string. Parameter bounds should be a pointer
  ## to float[4], if the bounding box of the text should be returned. The
  ## bounds value are [xmin,ymin, xmax,ymax]
  ##
  ## Returns the horizontal advance of the measured text (i.e. where the next
  ## character should drawn).
  ##
  ## Measured values are returned in local coordinate space.

proc textBoxBounds*(ctx; x: cfloat, y: cfloat,
                    breakRowWidth: cfloat, string: cstring, `end`: cstring,
                    bounds: ptr cfloat) {.cdecl, importc: "nvgTextBoxBounds".}
  ## Measures the specified multi-text string. Parameter bounds should be
  ## a pointer to float[4], if the bounding box of the text should be returned.
  ## The bounds value are [xmin,ymin, xmax,ymax]
  ##
  ## Measured values are returned in local coordinate space.

proc textGlyphPositions*(ctx; x: cfloat, y: cfloat,
                         string: cstring, `end`: cstring,
                         positions: ptr GlyphPosition, maxPositions: cint): cint
  {.cdecl, importc: "nvgTextGlyphPositions".}
  ## Calculates the glyph x positions of the specified text. If end is
  ## specified only the sub-string will be used.
  ##
  ## Measured values are returned in local coordinate space.

proc textMetrics*(ctx; ascender: ptr cfloat, descender: ptr cfloat,
                  lineh: ptr cfloat) {.cdecl, importc: "nvgTextMetrics".}
  ## Returns the vertical metrics based on the current text style.
  ## Measured values are returned in local coordinate space.

proc textBreakLines*(ctx; string: cstring, `end`: cstring,
                     breakRowWidth: cfloat, rows: ptr TextRow,
                     maxRows: cint): cint
    {.cdecl, importc: "nvgTextBreakLines".}
  ## Breaks the specified text into lines. If end is specified only the
  ## sub-string will be used.
  ##
  ## White space is stripped at the beginning of the rows, the text is split at
  ## word boundaries or when new-line characters are encountered. Words longer
  ## than the max width are slit at nearest character (i.e. no hyphenation).

#}}}
#{{{ Framebuffer ------------------------------------------------------------

type
  GLuint = uint32

  NVGLUFramebufferObj {.bycopy.} = object
    ctx*:    NVGcontext
    fbo:     GLuint
    rbo:     GLuint
    texture: GLuint
    image*:  Image

  NVGLUFramebuffer* = ptr NVGLUFramebufferObj


proc nvgluBindFramebuffer*(fb: NVGLUFramebuffer) {.cdecl, importc.}

proc nvgluCreateFramebuffer*(ctx; w: cint, h: cint,
                             imageFlags: cint): NVGLUFramebuffer
    {.cdecl, importc.}

proc nvgluDeleteFramebuffer*(fb: NVGLUFramebuffer) {.cdecl, importc.}

# }}}

# vim: et:ts=2:sw=2:fdm=marker
