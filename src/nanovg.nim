when defined(nvgGL2):
  const GLVersion* = "GL2"
  {.passC: "-DNANOVG_GL2_IMPLEMENTATION", compile: "nanovg_gl_stub.c".}
#  {.passL: "../lib/nanovg_gl2_stub.o"}

elif defined(nvgGL3):
  const GLVersion* = "GL3"
  {.passC: "-DNANOVG_GL3_IMPLEMENTATION", compile: "nanovg_gl_stub.c".}
#  {.passL: "../lib/nanovg_gl3_stub.o"}

elif defined(nvgGLES2):
  const GLVersion* = "GLES2"
  {.passC: "-DNANOVG_GLES2_IMPLEMENTATION", compile: "nanovg_gl_stub.c".}
#  {.passL: "../lib/nanovg_gles2_stub.o"}

elif defined(nvgGLES3):
  const GLVersion* = "GLES3"
  {.passC: "-DNANOVG_GLES3_IMPLEMENTATION", compile: "nanovg_gl_stub.c".}
#  {.passL: "../lib/nanovg_gles3_stub.o"}

else:
  {.error:
   "define nvgGL2, nvgGL3, nvgGLES2, or nvgGLES3 (pass -d:... to compile)".}

#{.passL: "../lib/glad.o"}
{.passL: "D:/Work/Code/nanovg-nim/lib/nanovg.o"}

{.compile: "deps/glad.c".}
#{.compile: "src/nanovg.c".}

type
  NVGContextObj = object
  NVGContext* = ptr NVGContextObj

  Color* {.byCopy.} = object
    r*: cfloat
    g*: cfloat
    b*: cfloat
    a*: cfloat

  Paint* {.byCopy.} = object
    xform*: array[6, cfloat]
    extent*: array[2, cfloat]
    radius*: cfloat
    feather*: cfloat
    innerColor*: Color
    outerColor*: Color
    image*: cint

# TODO
const
  NVG_CCW*: cint = 1    # Winding for solid shapes
  NVG_CW*: cint  = 2    # Winding for holes

  NVG_SOLID*: cint = 1  # CCW
  NVG_HOLE*: cint  = 2  # CW

  NVG_BUTT*: cint   = 0
  NVG_ROUND*: cint  = 1
  NVG_SQUARE*: cint = 2
  NVG_BEVEL*: cint  = 3
  NVG_MITER*: cint  = 4

  # Horizontal align
  NVG_ALIGN_LEFT*: cint     = 1 shl 0  # Default, align text horizontally to
                                       # left.
  NVG_ALIGN_CENTER*: cint   = 1 shl 1  # Align text horizontally to center.
  NVG_ALIGN_RIGHT*: cint    = 1 shl 2  # Align text horizontally to right.

  # Vertical align
  NVG_ALIGN_TOP*: cint      = 1 shl 3  # Align text vertically to top.
  NVG_ALIGN_MIDDLE*: cint   = 1 shl 4  # Align text vertically to middle.
  NVG_ALIGN_BOTTOM*: cint   = 1 shl 5  # Align text vertically to bottom.
  NVG_ALIGN_BASELINE*: cint = 1 shl 6  # Default, align text vertically to
                                       # baseline.

# TODO
const
  # Generate mipmaps during creation of the image.
  NVG_IMAGE_GENERATE_MIPMAPS*: cint = 1 shl 0

  # Repeat image in X direction.
  NVG_IMAGE_REPEATX*: cint          = 1 shl 1

  # Repeat image in Y direction.
  NVG_IMAGE_REPEATY*: cint          = 1 shl 2

  # Flips (inverses) image in Y direction when rendered.
  NVG_IMAGE_FLIPY*: cint            = 1 shl 3

  # Image data has premultiplied alpha.
  NVG_IMAGE_PREMULTIPLIED*: cint    = 1 shl 4


# TODO
type
  NVGglyphPosition* = object
    str*: cstring       # Position of the glyph in the input string.
    x*: cfloat          # The x-coordinate of the logical glyph position.
    minx*: cfloat
    maxx*: cfloat       # The bounds of the glyph shape.

  NVGtextRow* = object
    start*: cstring     # Pointer to the input text where the row starts.
    `end`*: cstring     # Pointer to the input text where the row ends
                        # (one past the last character).
    next*: cstring      # Pointer to the beginning of the next row.
    width*: cfloat      # Logical width of the row.
    minx*: cfloat
    maxx*: cfloat       # Actual bounds of the row. Logical with and
                        # bounds can differ because of kerning and some
                        # parts over extending.

const
  # Flag indicating if geometry based anti-aliasing is used
  # (may not be needed when using MSAA).
  NVG_ANTIALIAS*: cint       = 1 shl 0

  # Flag indicating if strokes should be drawn using stencil buffer.
  # The rendering will be a little slower, but path overlaps (i.e.
  # self-intersecting or sharp turns) will be drawn just once.
  NVG_STENCIL_STROKES*: cint = 1 shl 1

  # Flag indicating that additional debug checks are done.
  NVG_DEBUG*: cint           = 1 shl 2


# Creates NanoVG contexts for different OpenGL (ES) versions.
# Flags should be combination of the create flags above.

when defined(nvgGL2):
  proc nvgCreateContext(flags: cint): NVGContext {.importc: "nvgCreateGL2".}
  proc nvgDeleteContext(ctx: NVGContext) {.importc: "nvgDeleteGL2".}

when defined(nvgGL3):
  proc nvgCreateContext(flags: cint): NVGContext {.importc: "nvgCreateGL3".}
  proc nvgDeleteContext(ctx: NVGContext) {.importc: "nvgDeleteGL3".}

when defined(nvgGLES2):
  proc nvgCreateContext(flags: cint): NVGContext {.importc: "nvgCreateGLES2".}
  proc nvgDeleteContext(ctx: NVGContext) {.importc: "nvgDeleteGLES2".}

when defined(nvgGLES3):
  proc nvgCreateContext(flags: cint): NVGContext {.importc: "nvgCreateGLES3".}
  proc nvgDeleteContext(ctx: NVGContext) {.importc: "nvgDeleteGLES3".}

# These are additional flags on top of NVGimageFlags.
# TODO
type
  NVGimageFlagsGL = enum
    NVG_IMAGE_NODELETE = 1 shl 16 # Do not delete GL texture handle.


# Begin drawing a new frame
# =========================
# Calls to nanovg drawing API should be wrapped in nvgBeginFrame()
# & nvgEndFrame() nvgBeginFrame() defines the size of the window to render to
# in relation currently set viewport (i.e. glViewport on GL backends). Device
# pixel ration allows to control the rendering on Hi-DPI devices.
#
# For example, GLFW returns two dimension for an opened window: window size
# and frame buffer size. In that case you would set windowWidth/Height to the
# window size devicePixelRatio to: frameBufferWidth / windowWidth.

proc nvgBeginFrame(ctx: NVGContext, windowWidth: cint, windowHeight: cint,
                   devicePixelRatio: cfloat) {.cdecl, importc.}

# Cancels drawing the current frame.
proc cancelFrame*(ctx: NVGContext) {.cdecl, importc: "nvgCancelFrame".}

# Ends drawing flushing remaining render state.
proc endFrame*(ctx: NVGContext) {.cdecl, importc: "nvgEndFrame".}


# Color utils
# ===========
# Colors in NanoVG are stored as unsigned ints in ABGR format.

# Returns a color value from red, green, blue values. Alpha will be set to 255
# (1.0f).
proc nvgRGB(r,g,b: uint8): Color {.cdecl, importc.}

# Returns a color value from red, green, blue values. Alpha will be set to
# 1.0f.
proc nvgRGBf(r,g,b: float): Color {.cdecl, importc.}

# Returns a color value from red, green, blue and alpha values.
proc nvgRGBA(r,g,b,a: uint8): Color {.cdecl, importc.}

# Returns a color value from red, green, blue and alpha values.
proc nvgRGBA(r: cfloat, g: cfloat, b: cfloat, a: cfloat): Color {.cdecl,
    importc.}

# Linearly interpolates from color c0 to c1, and returns resulting color value.
proc nvgLerpRGBA(c0: Color, c1: Color, u: cfloat): Color {.cdecl,
    importc.}

# Sets transparency of a color value.
proc nvgTransRGBA(c0: Color, a: cuchar): Color {.cdecl, importc.}

# Sets transparency of a color value.
proc nvgTransRGBAf(c0: Color, a: cfloat): Color {.cdecl, importc.}

# Returns color value specified by hue, saturation and lightness.
# HSL values are all in range [0..1], alpha will be set to 255.
proc nvgHSL(h: cfloat, s: cfloat, l: cfloat): Color {.cdecl, importc.}

# Returns color value specified by hue, saturation and lightness and alpha.
# HSL values are all in range [0..1], alpha in range [0..255]
proc nvgHSLA(h: cfloat, s: cfloat, l: cfloat, a: cuchar): Color {.cdecl,
    importc.}


# State handling
# ==============
# NanoVG contains state which represents how paths will be rendered.
# The state contains transform, fill and stroke styles, text and font styles,
# and scissor clipping.

# Pushes and saves the current render state into a state stack.
# A matching nvgRestore() must be used to restore the state.
proc save*(ctx: NVGContext) {.cdecl, importc: "nvgSave".}

# Pops and restores current render state.
proc restore*(ctx: NVGContext) {.cdecl, importc: "nvgRestore".}

# Resets current render state to default values. Does not affect the render
# state stack.
proc reset*(ctx: NVGContext) {.cdecl, importc: "nvgReset".}


# Render styles
# =============
# Fill and stroke render style can be either a solid color or a paint which is
# a gradient or a pattern.  Solid color is simply defined as a color value,
# different kinds of paints can be created using nvgLinearGradient(),
# nvgBoxGradient(), nvgRadialGradient() and nvgImagePattern().
#
# Current render style can be saved and restored using nvgSave() and
# nvgRestore().

# Sets current stroke style to a solid color.
proc strokeColor*(ctx: NVGContext, color: Color) {.cdecl,
    importc: "nvgStrokeColor".}

# Sets current stroke style to a paint, which can be a one of the gradients or
# a pattern.
proc strokePaint*(ctx: NVGContext, paint: Paint)  {.cdecl,
    importc: "nvgStrokePaint".}

# Sets current fill style to a solid color.
proc fillColor*(ctx: NVGContext, color: Color) {.cdecl,
    importc: "nvgFillColor".}

# Sets current fill style to a paint, which can be a one of the gradients or
# a pattern.
proc fillPaint*(ctx: NVGContext, paint: Paint) {.cdecl,
    importc: "nvgFillPaint".}

# Sets the miter limit of the stroke style.
# Miter limit controls when a sharp corner is beveled.
proc miterLimit*(ctx: NVGContext, limit: cfloat)  {.cdecl,
    importc: "nvgMiterLimit".}

# Sets the stroke width of the stroke style.
proc strokeWidth*(ctx: NVGContext, size: cfloat) {.cdecl,
    importc: "nvgStrokeWidth".}

# Sets how the end of the line (cap) is drawn,
# Can be one of: NVG_BUTT (default), NVG_ROUND, NVG_SQUARE.
proc lineCap*(ctx: NVGContext, cap: cint) {.cdecl, importc: "nvgLineCap".}

# Sets how sharp path corners are drawn.
# Can be one of NVG_MITER (default), NVG_ROUND, NVG_BEVEL.
proc lineJoin*(ctx: NVGContext, join: cint) {.cdecl, importc: "nvgLineJoin".}

# Sets the transparency applied to all rendered shapes.
# Already transparent paths will get proportionally more transparent as well.
proc globalAlpha*(ctx: NVGContext, alpha: cfloat) {.cdecl,
    importc: "nvgGlobalAlpha".}


# Transforms
# ==========
# The paths, gradients, patterns and scissor region are transformed by an
# transformation matrix at the time when they are passed to the API.
#
# The current transformation matrix is a affine matrix:
#   [sx kx tx]
#   [ky sy ty]
#   [ 0  0  1]
#
# Where: sx,sy define scaling, kx,ky skewing, and tx,ty translation.
# The last row is assumed to be 0,0,1 and is not stored.
#
# Apart from nvgResetTransform(), each transformation function first creates
# specific transformation matrix and pre-multiplies the current transformation
# by it.
#
# Current coordinate system (transformation) can be saved and restored using
# nvgSave() and nvgRestore().

# Resets current transform to a identity matrix.
proc resetTransform*(ctx: NVGContext) {.cdecl, importc: "nvgResetTransform".}

# Premultiplies current coordinate system by specified matrix.
# The parameters are interpreted as matrix as follows:
#
#   [a c e]
#   [b d f]
#   [0 0 1]
#
proc transform*(ctx: NVGContext, a: cfloat, b: cfloat, c: cfloat,
                d: cfloat, e: cfloat, f: cfloat) {.cdecl,
                importc: "nvgTransform".}

# Translates current coordinate system.
proc translate*(ctx: NVGContext, x: cfloat, y: cfloat) {.cdecl,
    importc: "nvgTranslate".}

# Rotates current coordinate system. Angle is specified in radians.
proc rotate*(ctx: NVGContext, angle: cfloat) {.cdecl, importc: "nvgRotate".}

# Skews the current coordinate system along X axis. Angle is specified in
# radians.
proc skewX*(ctx: NVGContext, angle: cfloat) {.cdecl, importc: "nvgSkewX".}

# Skews the current coordinate system along Y axis. Angle is specified in
# radians.
proc skewY*(ctx: NVGContext, angle: cfloat) {.cdecl, importc: "nvgSkewY".}

# Scales the current coordinate system.
proc scale*(ctx: NVGContext, x: cfloat, y: cfloat) {.cdecl,
    importc: "nvgScale".}

# Stores the top part (a-f) of the current transformation matrix in to the
# specified buffer.
#
#   [a c e]
#   [b d f]
#   [0 0 1]
#
# There should be space for 6 floats in the return buffer for the values a-f.
proc currentTransform*(ctx: NVGContext, xform: ptr cfloat) {.cdecl,
    importc: "nvgCurrentTransform".}

# The following functions can be used to make calculations on 2x3
# transformation matrices. A 2x3 matrix is represented as float[6].

# Sets the transform to identity matrix.
# TODO
proc transformIdentity*(dst: ptr cfloat) {.cdecl,
    importc: "nvgTransformIdentity".}

# Sets the transform to translation matrix matrix.
# TODO
proc transformTranslate*(dst: ptr cfloat, tx: cfloat, ty: cfloat) {.cdecl,
    importc: "nvgTransformTranslate".}

# Sets the transform to scale matrix.
# TODO
proc transformScale*(dst: ptr cfloat, sx: cfloat, sy: cfloat) {.cdecl,
    importc: "nvgTransformScale".}

# Sets the transform to rotate matrix. Angle is specified in radians.
# TODO
proc transformRotate*(dst: ptr cfloat, a: cfloat) {.cdecl,
    importc: "nvgTransformRotate".}

# Sets the transform to skew-x matrix. Angle is specified in radians.
# TODO
proc transformSkewX*(dst: ptr cfloat, a: cfloat) {.cdecl,
    importc: "nvgTransformSkewX".}

# Sets the transform to skew-y matrix. Angle is specified in radians.
# TODO
proc transformSkewY*(dst: ptr cfloat, a: cfloat) {.cdecl,
    importc: "nvgTransformSkewY".}

# Sets the transform to the result of multiplication of two transforms,
# of A = A*B.
# TODO
proc transformMultiply*(dst: ptr cfloat, src: ptr cfloat) {.cdecl,
    importc: "nvgTransformMultiply".}

# Sets the transform to the result of multiplication of two transforms,
# of A = B*A.
# TODO
proc transformPremultiply*(dst: ptr cfloat, src: ptr cfloat) {.cdecl,
    importc: "nvgTransformPremultiply".}

# Sets the destination to inverse of specified transform.
# Returns 1 if the inverse could be calculated, else 0.
# TODO
proc transformInverse*(dst: ptr cfloat, src: ptr cfloat): cint {.cdecl,
    importc: "nvgTransformInverse".}

# Transform a point by given transform.
# TODO
proc transformPoint*(dstx: ptr cfloat, dsty: ptr cfloat, xform: ptr cfloat,
                     srcx: cfloat, srcy: cfloat) {.cdecl,
                         importc: "nvgTransformPoint".}


# Images
# ======
# NanoVG allows you to load jpg, png, psd, tga, pic and gif files to be used
# for rendering.  In addition you can upload your own image. The image loading
# is provided by stb_image.  The parameter imageFlags is combination of flags
# defined in NVGimageFlags.

# Creates image by loading it from the disk from specified file name.
# Returns handle to the image.
proc createImage*(ctx: NVGContext, filename: cstring,
                  imageFlags: cint): cint {.cdecl, importc: "nvgCreateImage".}

# Creates image by loading it from the specified chunk of memory.
# Returns handle to the image.
# TODO
proc createImageMem*(ctx: NVGContext, imageFlags: cint, data: ptr cuchar,
                     ndata: cint): cint {.cdecl, importc: "nvgCreateImageMem".}

# Creates image from specified image data.
# Returns handle to the image.
# TODO
proc createImageRGBA*(ctx: NVGContext, w: cint, h: cint,
                      imageFlags: cint,data: ptr cuchar): cint {.cdecl,
                          importc: "nvgCreateImageRGBA".}

# Updates image data specified by image handle.
# TODO
proc updateImage*(ctx: NVGContext, image: cint,
                  data: ptr cuchar) {.cdecl, importc: "nvgUpdateImage".}

# Returns the dimensions of a created image.
proc nvgImageSize*(ctx: NVGContext, image: cint,
                   w: ptr cint, h: ptr cint) {.cdecl, importc.}

# Deletes created image.
proc deleteImage*(ctx: NVGContext,image: cint) {.cdecl,
    importc: "nvgDeleteImage".}


# Paints
# ======
# NanoVG supports four types of paints: linear gradient, box gradient, radial
# gradient and image pattern.  These can be used as paints for strokes and
# fills.

# Creates and returns a linear gradient. Parameters (sx,sy)-(ex,ey) specify
# the start and end coordinates of the linear gradient, icol specifies the
# start color and ocol the end color.  The gradient is transformed by the
# current transform when it is passed to nvgFillPaint() or nvgStrokePaint().

proc nvgLinearGradient(ctx: NVGContext, sx: cfloat, sy: cfloat,
                       ex: cfloat, ey: cfloat,
                       icol: Color, ocol: Color): Paint {.cdecl, importc.}

# Creates and returns a box gradient. Box gradient is a feathered rounded
# rectangle, it is useful for rendering drop shadows or highlights for boxes.
# Parameters (x,y) define the top-left corner of the rectangle, (w,h) define
# the size of the rectangle, r defines the corner radius, and f feather.
# Feather defines how blurry the border of the rectangle is. Parameter icol
# specifies the inner color and ocol the outer color of the gradient.  The
# gradient is transformed by the current transform when it is passed to
# nvgFillPaint() or nvgStrokePaint().

proc nvgBoxGradient*(ctx: NVGContext, x: cfloat, y: cfloat,
                     w: cfloat, h: cfloat, r: cfloat, f: cfloat,
                     icol: Color, ocol: Color): Paint {.cdecl,
                         importc.}

# Creates and returns a radial gradient. Parameters (cx,cy) specify the
# center, inr and outr specify the inner and outer radius of the gradient,
# icol specifies the start color and ocol the end color.  The gradient is
# transformed by the current transform when it is passed to nvgFillPaint() or
# nvgStrokePaint().

proc radialGradient*(ctx: NVGContext, cx: cfloat, cy: cfloat,
                    inr: cfloat, outr: cfloat,
                    icol: Color, ocol: Color): Paint {.cdecl,
                        importc.}

# Creates and returns an image patter. Parameters (ox,oy) specify the left-top
# location of the image pattern, (ex,ey) the size of one image, angle rotation
# around the top-left corner, image is handle to the image to render.  The
# gradient is transformed by the current transform when it is passed to
# nvgFillPaint() or nvgStrokePaint().

proc imagePattern*(ctx: NVGContext, ox: cfloat, oy: cfloat,
                   ex: cfloat, ey: cfloat, angle: cfloat, image: cint,
                   alpha: cfloat): Paint {.cdecl,
                       importc: "nvgImagePattern".}


# Scissoring
# ==========
# Scissoring allows you to clip the rendering into a rectangle. This is useful
# for various user interface cases like rendering a text edit or a timeline.

# Sets the current scissor rectangle.
# The scissor rectangle is transformed by the current transform.
proc scissor*(ctx: NVGContext, x: cfloat, y: cfloat,
              w: cfloat, h: cfloat) {.cdecl, importc: "nvgScissor".}

# Intersects current scissor rectangle with the specified rectangle.
# The scissor rectangle is transformed by the current transform.
# Note: in case the rotation of previous scissor rect differs from
# the current one, the intersection will be done between the specified
# rectangle and the previous scissor rectangle transformed in the current
# transform space. The resulting shape is always rectangle.

proc intersectScissor*(ctx: NVGContext, x: cfloat, y: cfloat,
                       w: cfloat, h: cfloat) {.cdecl,
                           importc: "nvgIntersectScissor".}

# Reset and disables scissoring.
proc resetScissor*(ctx: NVGContext) {.cdecl, importc: "nvgResetScissor".}


# Paths
# =====
# Drawing a new shape starts with nvgBeginPath(), it clears all the currently
# defined paths.  Then you define one or more paths and sub-paths which
# describe the shape. The are functions to draw common shapes like rectangles
# and circles, and lower level step-by-step functions, which allow to define
# a path curve by curve.
#
# NanoVG uses even-odd fill rule to draw the shapes. Solid shapes should have
# counter clockwise winding and holes should have counter clockwise order. To
# specify winding of a path you can call nvgPathWinding(). This is useful
# especially for the common shapes, which are drawn CCW.
#
# Finally you can fill the path using current fill style by calling nvgFill(),
# and stroke it with current stroke style by calling nvgStroke().
#
# The curve segments and sub-paths are transformed by the current transform.

# Clears the current path and sub-paths.
proc beginPath*(ctx: NVGContext) {.cdecl, importc: "nvgBeginPath".}

# Starts new sub-path with specified point as first point.
proc moveTo*(ctx: NVGContext, x: cfloat, y: cfloat) {.cdecl,
    importc: "nvgMoveTo".}

# Adds line segment from the last point in the path to the specified point.
proc lineTo*(ctx: NVGContext, x: cfloat, y: cfloat) {.cdecl,
    importc: "nvgLineTo".}

# Adds cubic bezier segment from last point in the path via two control points
# to the specified point.
proc bezierTo*(ctx: NVGContext, c1x: cfloat, c1y: cfloat,
               c2x: cfloat, c2y: cfloat, x: cfloat, y: cfloat) {.cdecl,
                   importc: "nvgBezierTo".}

# Adds quadratic bezier segment from last point in the path via a control
# point to the specified point.
proc quadTo*(ctx: NVGContext, cx: cfloat, cy: cfloat,
             x: cfloat, y: cfloat) {.cdecl, importc: "nvgQuadTo".}

# Adds an arc segment at the corner defined by the last path point, and two
# specified points.
proc arcTo*(ctx: NVGContext, x1: cfloat, y1: cfloat,
            x2: cfloat, y2: cfloat, radius: cfloat) {.cdecl,
                importc: "nvgArcTo".}

# Closes current sub-path with a line segment.
proc closePath*(ctx: NVGContext) {.cdecl, importc: "nvgClosePath".}

# Sets the current sub-path winding, see NVGwinding and NVGsolidity.
proc nvgPathWinding(ctx: NVGContext, dir: cint) {.cdecl, importc.}

# Creates new circle arc shaped sub-path. The arc center is at cx,cy, the arc
# radius is r, and the arc is drawn from angle a0 to a1, and swept in
# direction dir (NVG_CCW, or NVG_CW).
# Angles are specified in radians.
proc nvgArc*(ctx: NVGContext, cx: cfloat, cy: cfloat, r: cfloat,
             a0: cfloat, a1: cfloat, dir: cint) {.cdecl, importc.}

# Creates new rectangle shaped sub-path.
proc nvgRect(ctx: NVGContext, x: cfloat, y: cfloat,
             w: cfloat, h: cfloat) {.cdecl, importc.}

# Creates new rounded rectangle shaped sub-path.
proc nvgRoundedRect*(ctx: NVGContext, x: cfloat, y: cfloat, w: cfloat,
                     h: cfloat, r: cfloat) {.cdecl, importc.}

# Creates new ellipse shaped sub-path.
proc ellipse*(ctx: NVGContext, cx: cfloat, cy: cfloat,
              rx: cfloat, ry: cfloat) {.cdecl, importc: "nvgEllipse".}

# Creates new circle shaped sub-path.
proc circle*(ctx: NVGContext, cx: cfloat, cy: cfloat,
             r: cfloat) {.cdecl, importc: "nvgCircle".}

# Fills the current path with current fill style.
proc fill*(ctx: NVGContext) {.cdecl, importc: "nvgFill".}

# Fills the current path with current stroke style.
proc stroke*(ctx: NVGContext) {.cdecl, importc: "nvgStroke".}


# Text
# ====
# NanoVG allows you to load .ttf files and use the font to render text.
#
# The appearance of the text can be defined by setting the current text style
# and by specifying the fill color. Common text and font settings such as font
# size, letter spacing and text align are supported. Font blur allows you to
# create simple text effects such as drop shadows.
#
# At render time the font face can be set based on the font handles or name.
#
# Font measure functions return values in local space, the calculations are
# carried in the same resolution as the final rendering. This is done because
# the text glyph positions are snapped to the nearest pixels sharp rendering.
#
# The local space means that values are not rotated or scale as per the
# current transformation. For example if you set font size to 12, which would
# mean that line height is 16, then regardless of the current scaling and
# rotation, the returned line height is always 16. Some measures may vary
# because of the scaling since aforementioned pixel snapping.
#
# While this may sound a little odd, the setup allows you to always render the
# same way regardless of scaling. I.e. following works regardless of scaling:
#
#   const char* txt = "Text me up.",
#   nvgTextBounds(vg, x,y, txt, NULL, bounds),
#   nvgBeginPath(vg),
#   nvgRoundedRect(vg, bounds[0],bounds[1],
#                      bounds[2]-bounds[0],
#                      bounds[3]-bounds[1]),
#   nvgFill(vg),
#
# Note: currently only solid color fill is supported for text.

# Creates font by loading it from the disk from specified file name.
# Returns handle to the font.
proc createFont*(ctx: NVGContext, name: cstring,
                 filename: cstring): cint {.cdecl, importc: "nvgCreateFont".}

# Creates image by loading it from the specified memory chunk.
# Returns handle to the font.
# TODO
proc createFontMem*(ctx: NVGContext, name: cstring, data: ptr cuchar,
                    ndata: cint, freeData: cint): cint {.cdecl,
                        importc: "nvgCreateFontMem".}

# Finds a loaded font of specified name, and returns handle to it, or -1 if
# the font is not found.
proc findFont*(ctx: NVGContext, name: cstring): cint {.cdecl,
    importc: "nvgFindFont".}

# Sets the font size of current text style.
proc fontSize*(ctx: NVGContext, size: cfloat) {.cdecl,
    importc: "nvgFontSize".}

# Sets the blur of current text style.
proc fontBlur*(ctx: NVGContext, blur: cfloat) {.cdecl,
    importc: "nvgFontBlur".}

# Sets the letter spacing of current text style.
proc textLetterSpacing*(ctx: NVGContext, spacing: cfloat) {.cdecl,
    importc: "nvgTextLetterSpacing".}

# Sets the proportional line height of current text style. The line height is
# specified as multiple of font size.
proc textLineHeight*(ctx: NVGContext,
                     lineHeight: cfloat) {.cdecl, importc: "nvgTextLineHeight".}

# Sets the text align of current text style, see NVGalign for options.
proc nvgTextAlign*(ctx: NVGContext, align: cint) {.cdecl, importc.}

# Sets the font face based on specified id of current text style.
proc fontFaceId*(ctx: NVGContext, font: cint) {.cdecl,
    importc: "nvgFontFaceId".}

# Sets the font face based on specified name of current text style.
proc fontFace*(ctx: NVGContext,
               font: cstring) {.cdecl, importc: "nvgFontFace".}

# Draws text string at specified location. If end is specified only the
# sub-string up to the end is drawn.
proc nvgText(ctx: NVGContext, x: cfloat, y: cfloat, string: cstring,
             `end`: cstring): cfloat {.cdecl, importc.}

# Draws multi-line text string at specified location wrapped at the specified
# width. If end is specified only the sub-string up to the end is drawn.
# White space is stripped at the beginning of the rows, the text is split at
# word boundaries or when new-line characters are encountered.  Words longer
# than the max width are slit at nearest character (i.e. no hyphenation).

proc nvgTextBox*(ctx: NVGContext, x: cfloat, y: cfloat,
                 breakRowWidth: cfloat,
                 string: cstring, `end`: cstring) {.cdecl, importc.}

# Measures the specified text string. Parameter bounds should be a pointer to
# float[4], if the bounding box of the text should be returned. The bounds
# value are [xmin, ymin, xmax, ymax]. Returns the horizontal advance of the
# measured text (i.e. where the next character should drawn).  Measured values
# are returned in local coordinate space.

# TODO
proc textBounds*(ctx: NVGContext, x: cfloat, y: cfloat,
                 string: cstring, `end`: cstring,
                 bounds: ptr cfloat): cfloat {.cdecl, importc: "nvgTextBounds".}

# Measures the specified multi-text string. Parameter bounds should be
# a pointer to float[4], if the bounding box of the text should be returned.
# The bounds value are [xmin,ymin, xmax,ymax] Measured values are returned in
# local coordinate space.

# TODO
proc textBoxBounds*(ctx: NVGContext, x: cfloat, y: cfloat,
                    breakRowWidth: cfloat, string: cstring, `end`: cstring,
                    bounds: ptr cfloat) {.cdecl, importc: "nvgTextBoxBounds".}

# Calculates the glyph x positions of the specified text. If end is specified
# only the sub-string will be used.  Measured values are returned in local
# coordinate space.

# TODO
proc textGlyphPositions*(ctx: NVGContext, x: cfloat, y: cfloat,
                         string: cstring, `end`: cstring,
                         positions: ptr NVGglyphPosition,
                         maxPositions: cint): cint {.cdecl,
                             importc: "nvgTextGlyphPositions".}

# TODO
# Returns the vertical metrics based on the current text style.  Measured
# values are returned in local coordinate space.
proc textMetrics*(ctx: NVGContext, ascender: ptr cfloat,
                  descender: ptr cfloat,
                  lineh: ptr cfloat) {.cdecl, importc: "nvgTextMetrics".}

# Breaks the specified text into lines. If end is specified only the
# sub-string will be used. White space is stripped at the beginning of the
# rows, the text is split at word boundaries or when new-line characters are
# encountered. Words longer than the max width are slit at nearest character
# (i.e. no hyphenation).

# TODO
proc textBreakLines*(ctx: NVGContext, string: cstring, `end`: cstring,
                     breakRowWidth: cfloat, rows: ptr NVGtextRow,
                     maxRows: cint): cint {.cdecl,
                         importc: "nvgTextBreakLines".}


##############################################################################

var gladInitialized = false

proc gladLoadGLLoader*(a: pointer): cint {.importc.}

proc nvgInit*(getProcAddress: pointer): NVGContext =
  if not gladInitialized:
    if gladLoadGLLoader(getProcAddress) > 0:
      gladInitialized = true
    else:
      echo "Error initialising GLAD C lib"
      return nil

  # TODO flags
  var vg = nvgCreateContext(NVG_ANTIALIAS or NVG_STENCIL_STROKES or NVG_DEBUG)
  if vg == nil:
    echo "Error initialising NanoVG"
    return nil

  result = vg

proc nvgDelete*(ctx: NVGContext) =
  nvgDeleteContext(ctx)

template beginFrame*(ctx: NVGContext, w: int, h: int, pixelRatio: float) =
  nvgBeginFrame(ctx, w.cint, h.cint, pixelRatio.cfloat)


type
  PathWinding* = enum
    pwCCW = NVG_CCW
    pwCW = NVG_CW

template pathWinding*(ctx: NVGContext, dir: PathWinding) =
  nvgPathWinding(ctx, dir.cint)

template arc*(ctx: NVGContext, cx: float, cy: float, r: float,
              a0: float, a1: float, dir: PathWinding) =
  nvgArc(ctx, cx.cfloat, cy.cfloat, r.cfloat, a0.cfloat, a1.cfloat, dir.cint)

type
  HorizAlign* = enum
    haLeft = NVG_ALIGN_LEFT
    haCenter = NVG_ALIGN_CENTER
    haRight = NVG_ALIGN_RIGHT

  VertAlign* = enum
    vaTop = NVG_ALIGN_TOP
    vaMiddle = NVG_ALIGN_MIDDLE
    vaBottom = NVG_ALIGN_BOTTOM
    vaBaseline = NVG_ALIGN_BASELINE

template textAlign*(ctx: NVGContext, halign: HorizAlign = haLeft,
                    valign: VertAlign = vaBaseline) =
  nvgTextAlign(ctx, halign.cint or valign.cint)

proc imageSize*(ctx: NVGContext, image: int): tuple[w, h: int] =
  var w, h: cint
  nvgImageSize(ctx, image.cint, w.addr, h.addr)
  result = (w.int, h.int)

template rect*(ctx: NVGContext, x, y, w, h: float) =
  nvgRect(ctx, x.cfloat, y.cfloat, w.cfloat, h.cfloat)

template roundedRect*(ctx: NVGContext, x, y, w, h, r: float) =
  nvgRoundedRect(ctx, x.cfloat, y.cfloat, w.cfloat, h.cfloat, r.cfloat)

template linearGradient*(ctx: NVGContext, sx, sy, ex, ey: float,
                         icol: Color, ocol: Color): Paint =
  nvgLinearGradient(ctx, sx.cfloat, sy.cfloat, ex.cfloat, ey.cfloat, icol, ocol)

template boxGradient*(ctx: NVGContext, x, y, w, h, r, f: float,
                      icol, ocol: Color): Paint =
  nvgBoxGradient(ctx, x.cfloat, y.cfloat, w.cfloat, h.cfloat,
                 r.cfloat, f.cfloat, icol, ocol)

template radialGradient*(ctx: NVGContext, cx, cy, inr, outr: float,
                         icol, ocol: Color): Paint =
  nvgRadialGradient(ctx, cx.cfloat, cy.cfloat, inr.cfloat, outr.cfloat,
                    icol, ocol)

#STACKTRACE!
#template text*(ctx: NVGContext, x, y: float, string: string): float =
proc text*(ctx: NVGContext, x, y: float, string: string): float =
  nvgText(ctx, x.cfloat, y.cfloat, string, nil)


template color*(r,g,b: uint8): Color =
  nvgRGB(r, g, b)

template color*(r,g,b,a: uint8): Color =
  nvgRGBA(r, g, b, a)

template color*(r,g,b: float): Color =
  nvgRGB(r.cfloat, g.cfloat, b.cfloat)

template color*(r,g,b,a: float): Color =
  nvgRGBA(r.cfloat, g.cfloat, b.cfloat, a.cfloat)

template gray*(g: uint8): Color =
  nvgRGB(g, g, g)

template gray*(g: uint8, a: uint8): Color =
  nvgRGBA(g, g, g, a)

template withAlpha*(c: Color, a: uint8): Color =
  nvgTransRGBA(c, a.cuchar)

template withAlpha*(c: Color, a: float): Color =
  nvgTransRGBAf(c, a.cfloat)

template textBox*(ctx: NVGContext, x, y, breakRowWidth: float, string: string) =
  nvgTextBox(ctx, x.cfloat, y.cfloat, breakRowWidth.cfloat, string, nil)

template mix*(c1: Color, c2: Color, r: float): Color =
  nvgLerpRGBA(c1, c2, r.cfloat)

