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
export wrapper.TextRow
export wrapper.NvgInitFlag

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


proc nvgDeinit*(ctx: NVGContext) =
  nvgDeleteContext(ctx)


template shapeAntiAlias*(ctx: NVGContext, enabled: bool) =
  shapeAntiAlias(bool.cint)

template textAlign*(ctx: NVGContext, halign: HorizontalAlign = haLeft,
                    valign: VerticalAlign = vaBaseline) =
  textAlign(ctx, halign.cint or valign.cint)

proc imageSize*(ctx: NVGContext, image: Image): tuple[w, h: int] =
  var w, h: cint
  imageSize(ctx, image, w.addr, h.addr)
  result = (w.int, h.int)

template text*(ctx: NVGContext, x, y: float, string: string): float =
  text(ctx, x, y, string, nil)

template textBox*(ctx: NVGContext, x, y, breakRowWidth: float, string: string) =
  textBox(ctx, x, y, breakRowWidth, string, nil)


proc textMetrics*(ctx: NVGContext):
  tuple[ascender: float, descender: float, lineHeight: float] =

  var ascender, descender, lineHeight: cfloat
  textMetrics(ctx, ascender.addr, descender.addr, lineHeight.addr)
  result = (ascender.float, descender.float, lineHeight.float)


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
  withAlpha(c, clampToCuchar(a))


proc createImageMem*(ctx: NVGContext, imageFlags: set[ImageFlags] = {},
                     data: var openArray[byte]): Image =
  createImageMem(ctx, imageFlags, cast[ptr cuchar](data[0].addr), data.len.cint)


proc createFontMem*(ctx: NVGContext, name: cstring,
                    data: var openArray[byte]): Font =
  createFontMem(ctx, name, cast[ptr cuchar](data[0].addr), data.len.cint,
                freeData=0)


proc currentTransform*(ctx: NVGContext): TransformMatrix =
  currentTransform(ctx, result)


proc transform*(xform: TransformMatrix, x: cfloat,
                y: cfloat): tuple[x: float, y: float] =
  var destX, destY: cfloat
  transformPoint(destX.addr, destY.addr, xform, x, y)
  result = (destX.float, destY.float)


proc textBreakLines*(ctx: NVGContext, string: cstring, `end`: cstring,
                     breakRowWidth: float,
                     rows: var openArray[TextRow]): cint =
  textBreakLines(ctx, string, `end`, breakRowWidth, rows[0].addr, rows.len.cint)


proc horizontalAdvance*(ctx: NVGContext, x: float, y: float,
                        string: cstring, `end`: cstring = nil): float =
  textBounds(ctx, x, y, string, `end`, bounds=nil)


proc textBounds*(ctx: NVGContext, x: float, y: float,
             string: cstring,
             `end`: cstring = nil): tuple[bounds: Bounds, horizAdvance: float] =

  var b: Bounds
  let adv = textBounds(ctx, x, y, string, `end`, bounds=b.b[0].addr)
  result = (b, adv.float)


proc textBoxBounds*(ctx: NVGContext, x: float, y: float,
                    breakRowWidth: float, string: cstring,
                    `end`: cstring = nil): Bounds =
  textBoxBounds(ctx, x, y, breakRowWidth, string, `end`, result.b[0].addr)


proc textGlyphPositions*(ctx: NVGContext, x: float, y: float,
                         string: cstring, `end`: cstring,
                         positions: var openArray[GlyphPosition]): int =
  textGlyphPositions(ctx, x, y, string, `end`,
                     positions[0].addr, positions.len.cint)

proc textGlyphPositions*(ctx: NVGContext, x: float, y: float,
                         string: string,
                         positions: var openArray[GlyphPosition]): int =
  textGlyphPositions(ctx, x, y, string, nil,
                     positions[0].addr, positions.len.cint)

