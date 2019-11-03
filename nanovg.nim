import nanovg/wrapper

# Types
export wrapper.Font
export wrapper.Image
export wrapper.NoFont
export wrapper.NoImage
export wrapper.`==`
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
export wrapper.currentTransform
export wrapper.transformIdentity
export wrapper.transformTranslate
export wrapper.transformScale
export wrapper.transformRotate
export wrapper.transformSkewX
export wrapper.transformSkewY
export wrapper.transformMultiply
export wrapper.transformPremultiply
export wrapper.transformInverse
export wrapper.transformPoint

# Images
export wrapper.createImage
export wrapper.createImageMem
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
export wrapper.createFontMem
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
export wrapper.textBounds
export wrapper.textBoxBounds
export wrapper.textGlyphPositions
export wrapper.textBreakLines

# Nim API
var gladInitialized = false

proc gladLoadGLLoader*(a: pointer): cint {.importc.}


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
  text(ctx, x.cfloat, y.cfloat, string, nil)

template textBox*(ctx: NVGContext, x, y, breakRowWidth: float, string: string) =
  textBox(ctx, x.cfloat, y.cfloat, breakRowWidth.cfloat, string, nil)


proc textMetrics*(ctx: NVGContext):
  tuple[ascender: float, descender: float, lineHeight: float] =

  var ascender, descender, lineHeight: cfloat
  textMetrics(ctx, ascender.addr, descender.addr, lineHeight.addr)
  result = (ascender.float, descender.float, lineHeight.float)


func clampToCuchar(i: int): cuchar = clamp(i, 0, 255).cuchar

template rgb*(r, g, b: int): Color =
  rgb(clampToCuchar(r), clampToCuchar(g), clampToCuchar(b))

template rgba*(r, g, b, a: int): Color =
  rgba(clampToCuchar(r), clampToCuchar(g), clampToCuchar(b), clampToCuchar(a))

proc hsla*(h: cfloat, s: cfloat, l: cfloat, a: cfloat): Color =
  hsla(h, s, l, clamp(a * 255, 0.0, 1.0))

template gray*(g: int): Color             = rgb(g, g, g)
template gray*(g: int, a: int): Color     = rgba(g, g, g, a)
template gray*(g: float): Color           = rgb(g, g, g)
template gray*(g: float, a: float): Color = rgba(g, g, g, a)

template withAlpha*(c: Color, a: int): Color =
  withAlpha(c, clampToCuchar(a))

