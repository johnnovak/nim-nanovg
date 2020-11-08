import nanovg/wrapper

# Types
export wrapper.Font
export wrapper.Image
export wrapper.NoFont
export wrapper.NoImage
export wrapper.`==`

export wrapper.NVGContext
export wrapper.Color
export wrapper.Paint
export wrapper.PathWinding
export wrapper.Solidity
export wrapper.LineCapJoin
export wrapper.HorizontalAlign
export wrapper.VerticalAlign
export wrapper.BlendFactor
export wrapper.CompositeOperation
export wrapper.ImageFlags
export wrapper.CompositeOperationState
export wrapper.TransformMatrix
export wrapper.Bounds
export wrapper.GlyphPosition
export wrapper.NvgInitFlag

export wrapper.NVGLUFramebuffer

# Global
export wrapper.beginFrame
export wrapper.cancelFrame
export wrapper.endFrame
export wrapper.globalCompositeOperation
export wrapper.globalCompositeBlendFunc
export wrapper.globalCompositeBlendFuncSeparate

# Color utils
export wrapper.rgb
export wrapper.rgb
export wrapper.rgba
export wrapper.rgba
export wrapper.lerp
export wrapper.withAlpha
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
export wrapper.identity
export wrapper.multiply
export wrapper.premultiply
export wrapper.inverse

# Images
export wrapper.createImage
export wrapper.createImageRGBA
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
export wrapper.roundedRectVarying
export wrapper.ellipse
export wrapper.circle
export wrapper.fill
export wrapper.stroke

# Text
export wrapper.createFont
export wrapper.findFont
export wrapper.addFallbackFont
export wrapper.addFallbackFont
export wrapper.fontSize
export wrapper.fontBlur
export wrapper.textLetterSpacing
export wrapper.textLineHeight
export wrapper.fontFace
export wrapper.fontFace
export wrapper.text
export wrapper.textBox


template `++`[A](a: ptr A, offset: int): ptr A =
  cast[ptr A](cast[int](a) + offset)

template `--`[A](a, b: ptr A): int =
  cast[int](a) - cast[int](b)

# Framebuffer
export wrapper.nvgluBindFramebuffer
export wrapper.nvgluDeleteFramebuffer

using ctx: NVGContext

proc nvgluCreateFramebuffer*(ctx; width: int, height: int,
                             imageFlags: set[ImageFlags]): NVGLUFramebuffer =
  nvgluCreateFramebuffer(ctx, width.cint, height.cint, cast[cint](imageFlags))


# Nim API
var gladInitialized = false

proc gladLoadGLLoader*(a: pointer): int {.importc.}


proc nvgInit*(getProcAddress: pointer,
              flags: set[NvgInitFlag] = {}): NVGContext =

  if not gladInitialized:
    if gladLoadGLLoader(getProcAddress) > 0:
      gladInitialized = true
    else:
      echo "Error initialising GLAD C lib"
      return nil

  var vg = nvgCreateContext(flags)
  if vg == nil:
    echo "Error initialising NanoVG"
    return nil

  result = vg


proc nvgDeinit*(ctx) =
  nvgDeleteContext(ctx)


template shapeAntiAlias*(ctx; enabled: bool) =
  shapeAntiAlias(ctx, enabled.cint)

proc imageSize*(ctx; image: Image): tuple[w, h: int] =
  var w, h: cint
  imageSize(ctx, image, w.addr, h.addr)
  result = (w.int, h.int)


proc createImageMem*(ctx; imageFlags: set[ImageFlags] = {},
                     data: var openArray[byte]): Image =
  createImageMem(ctx, imageFlags, cast[ptr cuchar](data[0].addr), data.len.cint)


proc createFontMem*(ctx; name: string,
                    data: var openArray[byte]): Font =
  createFontMem(ctx, name, cast[ptr cuchar](data[0].addr), data.len.cint,
                freeData=0)


# {{{ Transform functions

proc currentTransform*(ctx): TransformMatrix =
  currentTransform(ctx, result)


proc transform*(xform: TransformMatrix, x: cfloat,
                y: cfloat): tuple[x: float, y: float] =
  var destX, destY: cfloat
  transformPoint(destX.addr, destY.addr, xform, x, y)
  result = (destX.float, destY.float)

# }}}
# {{{ Text functions

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

func clampToCuchar(i: int): cuchar = clamp(i, 0, 255).cuchar

func rgb*(r, g, b: int): Color =
  rgb(clampToCuchar(r), clampToCuchar(g), clampToCuchar(b))

func rgba*(r, g, b, a: int): Color =
  rgba(clampToCuchar(r), clampToCuchar(g), clampToCuchar(b), clampToCuchar(a))

func hsla*(h: float, s: float, l: float, a: float): Color =
  hsla(h.cfloat, s.cfloat, l.cfloat, clamp(a * 255, 0, 255).cuchar)

template gray*(g: int,   a: int = 255):   Color = rgba(g, g, g, a)
template gray*(g: float, a: float = 1.0): Color = rgba(g, g, g, a)

template black*(a: int):         Color = gray(0, a)
template black*(a: float = 1.0): Color = gray(0.0, a)
template white*(a: int):         Color = gray(255, a)
template white*(a: float = 1.0): Color = gray(1.0, a)

template withAlpha*(c: Color, a: int): Color =
  wrapper.withAlpha(c, clampToCuchar(a))

template withAlpha*(c: Color, a: float): Color =
  wrapper.withAlpha(c, a)

# }}}

# vim: et:ts=2:sw=2:fdm=marker
