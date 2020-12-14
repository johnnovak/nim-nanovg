import strformat

import nanovg/wrapper

# Types
export wrapper.Font
export wrapper.Image
export wrapper.NoFont
export wrapper.NoImage
export wrapper.`==`

export wrapper.NVGContext
export wrapper.NVGInitFlag

export wrapper.BlendFactor
export wrapper.Bounds
export wrapper.Color
export wrapper.CompositeOperation
export wrapper.CompositeOperationState
export wrapper.GlyphPosition
export wrapper.HorizontalAlign
export wrapper.ImageFlags
export wrapper.LineCapJoin
export wrapper.Paint
export wrapper.PathWinding
export wrapper.Solidity
export wrapper.TransformMatrix
export wrapper.VerticalAlign

export wrapper.NVGLUFramebuffer

# Global
export wrapper.nvgDeleteContext

export wrapper.beginFrame
export wrapper.cancelFrame
export wrapper.endFrame

export wrapper.globalCompositeOperation
export wrapper.globalCompositeBlendFunc
export wrapper.globalCompositeBlendFuncSeparate

# Color utils
export wrapper.rgb
export wrapper.rgba
export wrapper.lerp
export wrapper.withAlpha
export wrapper.hsl
export wrapper.hsla

# State Handling
export wrapper.save
export wrapper.restore
export wrapper.reset

# Render styles
export wrapper.strokeColor
export wrapper.strokePaint
export wrapper.fillColor
export wrapper.fillPaint
export wrapper.strokeWidth
export wrapper.lineCap
export wrapper.lineJoin
export wrapper.globalAlpha

# Transforms
export wrapper.resetTransform
export wrapper.transform
export wrapper.translate
export wrapper.rotate
export wrapper.skewX
export wrapper.skewY
export wrapper.scale

# Images
export wrapper.updateImage
export wrapper.deleteImage

# Paints
export wrapper.linearGradient
export wrapper.boxGradient
export wrapper.radialGradient
export wrapper.imagePattern

# Scissoring
export wrapper.scissor
export wrapper.intersectScissor
export wrapper.resetScissor

# Paths
export wrapper.beginPath
export wrapper.moveTo
export wrapper.lineTo
export wrapper.bezierTo
export wrapper.quadTo
export wrapper.arcTo
export wrapper.closePath
export wrapper.pathWinding
export wrapper.arc
export wrapper.rect
export wrapper.roundedRect
export wrapper.ellipse
export wrapper.circle
export wrapper.fill
export wrapper.stroke

# Text
export wrapper.findFont
export wrapper.addFallbackFont
export wrapper.resetFallbackFonts
export wrapper.fontSize
export wrapper.fontBlur
export wrapper.textLetterSpacing
export wrapper.textLineHeight
export wrapper.fontFace
export wrapper.text
export wrapper.textBox

# Framebuffer
export wrapper.nvgluBindFramebuffer
export wrapper.nvgluDeleteFramebuffer


type
  NVGError* = object of CatchableError
    message*: string

using ctx: NVGContext

# {{{ General functions

var g_gladInitialized = false

proc gladLoadGLLoader*(a: pointer): int {.importc.}

proc nvgInit*(getProcAddress: pointer) =
  if not g_gladInitialized:
    if gladLoadGLLoader(getProcAddress) > 0:
      g_gladInitialized = true

  if not g_gladInitialized:
    raise newException(NVGError, "Failed to initialise NanoVG")


proc nvgCreateContext*(flags: set[NVGInitFlag]): NVGContext =
  result = wrapper.nvgCreateContext(flags)
  if result == nil:
    raise newException(NVGError, "Failed to create NanoVG context")


template shapeAntiAlias*(ctx; enabled: bool) =
  shapeAntiAlias(ctx, enabled.cint)


proc nvgluCreateFramebuffer*(ctx; width: int, height: int,
                             imageFlags: set[ImageFlags]): NVGLUFramebuffer =

  nvgluCreateFramebuffer(ctx, width.cint, height.cint, cast[cint](imageFlags))

# }}}
# {{{ Transform functions

proc currentTransform*(ctx): TransformMatrix =
  nvgCurrentTransform(ctx, result.m[0].addr)

proc identity*(dst: var TransformMatrix) =
  nvgIdentity(dst.m[0].addr)

proc translate*(dst: var TransformMatrix, tx: float, ty: float) =
  nvgTranslate(dst.m[0].addr, tx.cfloat, ty.cfloat)

proc scale*(dst: var TransformMatrix, sx: float, sy: float) =
  nvgScale(dst.m[0].addr, sx.cfloat, sy.cfloat)

proc rotate*(dst: var TransformMatrix, angle: float) =
  nvgRotate(dst.m[0].addr, angle.cfloat)

proc skewX*(dst: var TransformMatrix, angle: float) =
  nvgSkewX(dst.m[0].addr, angle.cfloat)

proc skewY*(dst: var TransformMatrix, angle: float) =
  nvgSkewY(dst.m[0].addr, angle.cfloat)

proc multiply*(dst: var TransformMatrix, src: TransformMatrix) =
  nvgMultiply(dst.m[0].addr, src.m[0].unsafeAddr)

proc premultiply*(dst: var TransformMatrix, src: TransformMatrix) =
  nvgPremultiply(dst.m[0].addr, src.m[0].unsafeAddr)

proc inverse*(src: TransformMatrix): (bool, TransformMatrix) =
  var dst: TransformMatrix
  let res = nvgInverse(dst.m[0].addr, src.m[0].unsafeAddr)
  result = (res == 1, dst)

proc transformPoint*(xform: TransformMatrix,
                     x: float, y: float): (float, float) =
  var destX, destY: cfloat
  nvgTransformPoint(destX.addr, destY.addr, xform.m[0].unsafeAddr,
                    x.cfloat, y.cfloat)
  result = (destX.float, destY.float)

# }}}
#  {{{ Font functions

proc createFont*(ctx; name: string, filename: string): Font =
  result = wrapper.createFont(ctx, name, filename)
  if result == NoFont:
    raise newException(NVGError, "Failed to create font")


proc createFontAtIndex*(ctx; name: string, filename: string,
                        fontIndex: Natural): Font =
  result = createFontAtIndex(ctx, name, filename, fontIndex.cint)
  if result == NoFont:
    raise newException(NVGError, "Failed to create font")


proc createFontMem*(ctx; name: string,
                    data: var openArray[byte]): Font =
  result = createFontMem(ctx, name, cast[ptr byte](data[0].addr),
                         data.len.cint, freeData=0)
  if result == NoFont:
    raise newException(NVGError, "Failed to create font")


proc createFontMemAtIndex*(ctx; name: string, data: var openArray[byte],
                           fontIndex: Natural): Font =
  result = createFontMemAtIndex(ctx, name, cast[ptr byte](data[0].addr),
                                data.len.cint, freeData=0, fontIndex.cint)
  if result == NoFont:
    raise newException(NVGError, "Failed to create font")

#  }}}
# {{{ Text functions

template `++`[A](a: ptr A, offset: int): ptr A =
  cast[ptr A](cast[int](a) + offset)

template `--`[A](a, b: ptr A): int =
  cast[int](a) - cast[int](b)

template getStartPtr(s: string, startPos: Natural): cstring =
  s[0].unsafeAddr ++ startPos

template getEndPtr(s: string, endPos: int): cstring =
  if endPos < 0: nil else: s[0].unsafeAddr ++ endPos ++ 1


proc textAlign*(ctx; halign: HorizontalAlign = haLeft,
                valign: VerticalAlign = vaBaseline) {.inline.} =
  textAlign(ctx, halign.cint or valign.cint)


proc text*(ctx; x, y: float, s: string,
           startPos: Natural = 0, endPos: int = -1,): float {.inline.} =
  if s == "": return
  text(ctx, x, y, getStartPtr(s, startPos), getEndPtr(s, endPos))


proc textBox*(ctx; x, y, breakRowWidth: float, s: string,
              startPos: Natural = 0, endPos: int = -1,) {.inline.} =
  if s == "": return
  textBox(ctx, x, y, breakRowWidth,
          getStartPtr(s, startPos), getEndPtr(s, endPos))


template textMetrics*(ctx): tuple[ascender: float, descender: float,
                                  lineHeight: float] =

  var ascender, descender, lineHeight: cfloat
  textMetrics(ctx, ascender.addr, descender.addr, lineHeight.addr)
  (ascender.float, descender.float, lineHeight.float)


type
  TextRow* = object
    startPos*: Natural
    endPos*:   Natural
    nextPos*:  Natural
    width*:    float
    minX*:     float
    maxX*:     float

proc textBreakLines*(ctx; s: string, startPos: Natural = 0, endPos: int = -1,
                     breakRowWidth: float, maxRows: int = -1): seq[TextRow] =

  result = newSeq[TextRow]()

  if s == "" or maxRows == 0: return

  var
    rows: array[64, wrapper.TextRow]
    rowsLeft = if maxRows >= 0: maxRows else: rows.len
    startPtr = getStartPtr(s, startPos)
    endPtr   = getEndPtr(s, endPos)

  while rowsLeft > 0:
    let numRows = wrapper.textBreakLines(ctx, startPtr, endPtr,
                                         breakRowWidth.cfloat, rows[0].addr,
                                         min(rowsLeft, rows.len).cint)
    for i in 0..<numRows:
      let row = rows[i]
      let sPtr = s[0].unsafeAddr

      let tr = TextRow(
        startPos: row.startPtr[0].unsafeAddr -- sPtr,
        # endPtr points to the char after the last character in the line
        endPos:   row.endPtr[0].unsafeAddr -- sPtr - 1,
        nextPos:  row.nextPtr[0].unsafeAddr -- sPtr,
        width:    row.width,
        minX:     row.minX,
        maxX:     row.maxX
      )
      result.add(tr)

    if numRows == 0:
      rowsLeft = 0
    else:
      startPtr = rows[numRows-1].nextPtr
      rowsLeft -= numRows


template textBreakLines*(ctx; s: string, startPos: Natural = 0,
                         breakRowWidth: float,
                         maxRows: int = -1): seq[TextRow] =

  textBreakLines(ctx, s, startPos, endPos = -1, breakRowWidth, maxRows)


template textBreakLines*(ctx; s: string, breakRowWidth: float,
                         maxRows: int = -1): seq[TextRow] =

  textBreakLines(ctx, s, startPos=0, endPos = -1, breakRowWidth, maxRows)


proc horizontalAdvance*(ctx; x: float, y: float, s: string,
                        startPos: Natural = 0,
                        endPos: int = -1): float {.inline.} =

  if s == "": return
  textBounds(ctx, x, y, getStartPtr(s, startPos), getEndPtr(s, endPos),
             bounds=nil)


proc textWidth*(ctx; s: string, startPos: Natural = 0,
                    endPos: int = -1): float {.inline.} =

  if s == "": return
  textBounds(ctx, 0, 0, getStartPtr(s, startPos), getEndPtr(s, endPos),
             bounds=nil)


proc textBounds*(ctx; x: float, y: float, s: string, startPos: Natural = 0,
                 endPos: int = -1): tuple[bounds: Bounds,
                                          horizAdvance: float] {.inline.} =

  if s == "": return

  var b: Bounds
  let adv = textBounds(ctx, x, y,
                       getStartPtr(s, startPos), getEndPtr(s, endPos),
                       bounds=b.x1.addr)
  result = (b, adv.float)


proc textBoxBounds*(ctx; x: float, y: float,
                    breakRowWidth: float, s: string,
                    startPos: Natural = 0, endPos: int = -1): Bounds {.inline.} =

  if s == "": return
  textBoxBounds(ctx, x, y, breakRowWidth,
                getStartPtr(s, startPos), getEndPtr(s, endPos), result.x1.addr)


proc textGlyphPositions*(ctx; x: float, y: float,
                         s: string, startPos: Natural = 0, endPos: int = -1,
                         positions: var openArray[GlyphPosition]): int {.inline.} =

  if s == "": return
  textGlyphPositions(ctx, x, y, getStartPtr(s, startPos), getEndPtr(s, endPos),
                     positions[0].addr, positions.len.cint)


template textGlyphPositions*(ctx; x: float, y: float,
                             s: string, startPos: Natural = 0,
                             positions: var openArray[GlyphPosition]): int =
  textGlyphPositions(ctx, x, y, s, startPos, endPos = -1, positions)


template textGlyphPositions*(ctx; x: float, y: float, s: string,
                             positions: var openArray[GlyphPosition]): int =
  textGlyphPositions(ctx, x, y, s, startPos=0, endPos = -1, positions)


# }}}
# {{{ Color functions

func clampToByte(i: int): byte = clamp(i, 0, 255).byte

func rgb*(r, g, b: int): Color =
  rgb(clampToByte(r), clampToByte(g), clampToByte(b))

func rgba*(r, g, b, a: int): Color =
  rgba(clampToByte(r), clampToByte(g), clampToByte(b), clampToByte(a))

func hsla*(h: float, s: float, l: float, a: float): Color =
  hsla(h.cfloat, s.cfloat, l.cfloat, clamp(a * 255, 0, 255).byte)

template withAlpha*(c: Color, a: int): Color =
  wrapper.withAlpha(c, clampToByte(a))

template withAlpha*(c: Color, a: float): Color =
  wrapper.withAlpha(c, a)

template gray*(g: float, a: float = 1.0): Color = rgba(g, g, g, a)
template gray*(g: int, a: int = 255): Color = rgba(g, g, g, a)

template black*(a: float = 1.0): Color = gray(0.0, a)
template white*(a: float = 1.0): Color = gray(1.0, a)

template black*(a: int): Color = black(a/255)
template white*(a: int): Color = white(a/255)

# Useful for debugging
template blue*(a: float = 1.0):    Color = rgba(0.0, 0.0, 1.0, a)
template green*(a: float = 1.0):   Color = rgba(0.0, 1.0, 0.0, a)
template cyan*(a: float = 1.0):    Color = rgba(0.0, 1.0, 1.0, a)
template red*(a: float = 1.0):     Color = rgba(1.0, 0.0, 0.0, a)
template magenta*(a: float = 1.0): Color = rgba(1.0, 0.0, 1.0, a)
template yellow*(a: float = 1.0):  Color = rgba(1.0, 1.0, 0.0, a)

template blue*(a: int):    Color = blue(a/255)
template green*(a: int):   Color = green(a/255)
template cyan*(a: int):    Color = cyan(a/255)
template red*(a: int):     Color = red(a/255)
template magenta*(a: int): Color = magenta(a/255)
template yellow*(a: int):  Color = yellow(a/255)

# }}}
# {{{ Image functions

proc createImage*(ctx; filename: string, flags: set[ImageFlags] = {}): Image =
  result = wrapper.createImage(ctx, filename, flags)
  if result == NoImage:
    raise newException(NVGError, "Failed to create image")


proc createImageMem*(ctx; flags: set[ImageFlags] = {},
                     data: var openArray[byte]): Image =
  result = createImageMem(ctx, flags, cast[ptr byte](data[0].addr),
                          data.len.cint)
  if result == NoImage:
    raise newException(NVGError, "Failed to create image")


proc createImageRGBA*(ctx; w: Natural, h: Natural, flags: set[ImageFlags] = {},
                      data: var openArray[byte]): Image =

  result = createImageRGBA(ctx, w.cint, h.cint, flags,
                           cast[ptr byte](data[0].addr))
  if result == NoImage:
    raise newException(NVGError, "Failed to create image")


proc imageSize*(ctx; image: Image): tuple[w, h: int] =
  var w, h: cint
  imageSize(ctx, image, w.addr, h.addr)
  result = (w.int, h.int)


# {{{ Image extensions

proc stbi_load(filename: cstring, x, y, channels: ptr cint,
               desiredChannels: cint): ptr UncheckedArray[byte]
    {.cdecl, importc: "stbi_load".}

proc stbi_image_free(data: ptr UncheckedArray[byte])
    {.cdecl, importc: "stbi_image_free".}


type ImageData* = object
  width*, height*: Natural
  numChannels*:    Natural
  data*:           ptr UncheckedArray[byte]

proc size*(d: ImageData): Natural =
  d.width * d.height * d.numChannels

proc `=destroy`*(d: var ImageData) =
  if d.data != nil:
    stbi_image_free(d.data)
    d.width = 0
    d.height = 0
    d.numChannels = 0
    d.data = nil


proc loadImage*(filename: string, desiredChannels: Natural = 4): ImageData =
  var w, h, channels: cint

  var data = stbi_load(filename, w.addr, h.addr, channels.addr,
                       desiredChannels.cint)

  if data == nil:
    raise newException(IOError, fmt"Could not load image '{filename}'")

  result = ImageData(
    width:  w.Natural,
    height: h.Natural,
    numChannels: desiredChannels,
    data: data
  )

# }}}
# }}}

# vim: et:ts=2:sw=2:fdm=marker
