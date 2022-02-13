import math
import strformat
import unicode

import nanovg


const
  FONT_SIZE_FACTOR = 0.8

const
  ICON_SEARCH = 0x1f50d
  ICON_CIRCLED_CROSS = 0x2716
  ICON_CHEVRON_RIGHT = 0xe75e
  ICON_CHECK = 0x2713
  ICON_LOGIN = 0xe740
  ICON_TRASH = 0xe729


proc drawWindow(vg: NVGcontext, title: string, x, y, w, h: float) =
  const cornerRadius = 3.0

  vg.save()

  # Window
  vg.beginPath()
  vg.roundedRect(x, y, w, h, cornerRadius)
  vg.fillColor(rgba(28, 30, 34, 192))
  vg.fill()

  # Drop shadow
  let shadowPaint = vg.boxGradient(x, y+2, w, h, cornerRadius * 2, 10,
                                   black(128), black(0))
  vg.beginPath()
  vg.rect(x-10, y-10, w+20, h+30)
  vg.roundedRect(x, y, w, h, cornerRadius)
  vg.pathWinding(sHole)
  vg.fillPaint(shadowPaint)
  vg.fill()

  # Header
  let headerPaint = vg.linearGradient(x, y, x, y+15, white(8), black(16))
  vg.beginPath()
  vg.roundedRect(x+1, y+1, w-2, 30, cornerRadius-1)
  vg.fillPaint(headerPaint)
  vg.fill()
  vg.beginPath()
  vg.moveTo(x+0.5, y+0.5+30)
  vg.lineTo(x+0.5+w-1, y+0.5+30)
  vg.strokeColor(black(32))
  vg.stroke()

  vg.fontSize(18.0 * FONT_SIZE_FACTOR)
  vg.fontFace("sans-bold")
  vg.textAlign(haCenter, vaMiddle)

  vg.fontBlur(2)
  vg.fillColor(black(128))
  discard vg.text(x+w/2, y+16+1, title)

  vg.fontBlur(0)
  vg.fillColor(gray(220, 160))
  discard vg.text(x+w/2, y+16, title)

  vg.restore()


proc drawSearchBox(vg: NVGcontext, text: string, x, y, w, h: float) =
  let cornerRadius = h/2-1

  # Edit
  let bg = vg.boxGradient(x, y+1.5, w, h, h/2, 5, black(16), black(92))
  vg.beginPath()
  vg.roundedRect(x, y, w, h, cornerRadius)
  vg.fillPaint(bg)
  vg.fill()

  vg.fontSize(h*1.3 * FONT_SIZE_FACTOR)
  vg.fontFace("icons")
  vg.fillColor(white(64))
  vg.textAlign(haCenter, vaMiddle)
  discard vg.text(x+h*0.55, y+h*0.55, toUTF8(Rune(ICON_SEARCH)))

  vg.fontSize(20.0 * FONT_SIZE_FACTOR)
  vg.fontFace("sans")
  vg.fillColor(white(32))

  vg.textAlign(haLeft, vaMiddle)
  discard vg.text(x+h*1.05, y+h*0.5, text)

  vg.fontSize(h*1.3 * FONT_SIZE_FACTOR)
  vg.fontFace("icons")
  vg.fillColor(white(32))
  vg.textAlign(haCenter, vaMiddle)
  discard vg.text(x+w-h*0.55, y+h*0.55, toUTF8(Rune(ICON_CIRCLED_CROSS)))


proc drawDropDown(vg: NVGcontext, text: string, x, y, w, h: float) =
  let
    cornerRadius = 4.0
    bg = vg.linearGradient(x, y, x, y+h, white(16), black(16))
  vg.beginPath()
  vg.roundedRect(x+1, y+1, w-2, h-2, cornerRadius-1)
  vg.fillPaint(bg)
  vg.fill()

  vg.beginPath()
  vg.roundedRect(x+0.5, y+0.5, w-1, h-1, cornerRadius-0.5)
  vg.strokeColor(black(48))
  vg.stroke()

  vg.fontSize(20.0 * FONT_SIZE_FACTOR)
  vg.fontFace("sans")
  vg.fillColor(white(160))
  vg.textAlign(haLeft, vaMiddle)
  discard vg.text(x+h*0.3, y+h*0.5, text)

  vg.fontSize(h*1.3 * FONT_SIZE_FACTOR)
  vg.fontFace("icons")
  vg.fillColor(white(64))
  vg.textAlign(haCenter, vaMiddle)
  discard vg.text(x+w - h*0.5, y + h*0.5, toUTF8(Rune(ICON_CHEVRON_RIGHT)))


proc drawLabel(vg: NVGcontext, text: string, x, y, w, h: float) =
  vg.fontSize(18.0 * FONT_SIZE_FACTOR)
  vg.fontFace("sans")
  vg.fillColor(white(128))

  vg.textAlign(haLeft, vaMiddle)
  discard vg.text(x, y+h*0.5, text)


proc drawEditBoxBase(vg: NVGcontext, x, y, w, h: float) =
  # Edit
  let bg = vg.boxGradient(x+1, y+1+1.5, w-2, h-2, 3,4, white(32), gray(32, 32))
  vg.beginPath
  vg.roundedRect(x+1, y+1, w-2, h-2, 4-1)
  vg.fillPaint(bg)
  vg.fill()

  vg.beginPath()
  vg.roundedRect(x+0.5, y+0.5, w-1, h-1, 4-0.5)
  vg.strokeColor(black(48))
  vg.stroke()


proc drawEditBox(vg: NVGcontext, text: string, x, y, w, h: float) =
  drawEditBoxBase(vg, x, y, w, h)

  vg.fontSize(20.0 * FONT_SIZE_FACTOR)
  vg.fontFace("sans")
  vg.fillColor(white(64))
  vg.textAlign(haLeft, vaMiddle)
  discard vg.text(x+h*0.3, y+h*0.5, text)


proc drawEditBoxNum(vg: NVGcontext, text: string, units: string,
                    x, y, w, h: float) =

  drawEditBoxBase(vg, x,y, w,h)

  let uw = vg.horizontalAdvance(0,0, units)

  vg.fontSize(18.0 * FONT_SIZE_FACTOR)
  vg.fontFace("sans")
  vg.fillColor(white(64))
  vg.textAlign(haRight, vaMiddle)
  discard vg.text(x+w-h*0.3, y+h*0.5, units)

  vg.fontSize(20.0 * FONT_SIZE_FACTOR)
  vg.fontFace("sans")
  vg.fillColor(white(128))
  vg.textAlign(haRight, vaMiddle)
  discard vg.text(x+w-uw-h*0.5, y+h*0.5, text)


proc drawCheckBox(vg: NVGcontext, text: string, x, y, w, h: float) =
  vg.fontSize(18.0 * FONT_SIZE_FACTOR)
  vg.fontFace("sans")
  vg.fillColor(white(160))

  vg.textAlign(haLeft, vaMiddle)
  discard vg.text(x+28, y+h*0.5, text)

  let bg = vg.boxGradient(x+1, y + floor(h*0.5)-9+1, 18, 18, 3, 3,
                          black(32), black(92))
  vg.beginPath()
  vg.roundedRect(x+1, y + floor(h*0.5)-9, 18, 18, 3)
  vg.fillPaint(bg)
  vg.fill()

  vg.fontSize(40 * FONT_SIZE_FACTOR)
  vg.fontFace("icons")
  vg.fillColor(white(128))
  vg.textAlign(haCenter, vaMiddle)
  discard vg.text(x+9+2, y+h*0.5, toUTF8(Rune(ICON_CHECK)))


proc drawButton(vg: NVGcontext, preicon: int, text: string,
                x, y, w, h: float, col: Color) =

  const cornerRadius = 4.0

  let a = if col == black(): 16 else: 32
  let bg = vg.linearGradient(x,y,x,y+h, white(a), black(a))
  vg.beginPath()
  vg.roundedRect(x+1,y+1, w-2,h-2, cornerRadius-1)

  if not (col == black()):
    vg.fillColor(col)
    vg.fill()

  vg.fillPaint(bg)
  vg.fill()

  vg.beginPath()
  vg.roundedRect(x+0.5, y+0.5, w-1,h-1, cornerRadius-0.5)
  vg.strokeColor(black(48))
  vg.stroke()

  vg.fontSize(20.0 * FONT_SIZE_FACTOR)
  vg.fontFace("sans-bold")
  let tw = vg.horizontalAdvance(0,0, text)

  var iw = 0.0

  if preicon != 0:
    vg.fontSize(h*1.3 * FONT_SIZE_FACTOR)
    vg.fontFace("icons")
    iw = vg.horizontalAdvance(0,0, toUTF8(Rune(preicon)))
    iw += h*0.15

    vg.fontSize(h*1.3 * FONT_SIZE_FACTOR)
    vg.fontFace("icons")
    vg.fillColor(white(96))
    vg.textAlign(haLeft, vaMiddle)
    discard vg.text(x+w*0.5 - tw*0.5 - iw*0.75, y+h*0.5, toUTF8(Rune(preicon)))

  vg.fontSize(20.0 * FONT_SIZE_FACTOR)
  vg.fontFace("sans-bold")
  vg.textAlign(haLeft, vaMiddle)
  vg.fillColor(black(160))
  discard vg.text(x+w*0.5 - tw*0.5 + iw*0.25, y+h*0.5 - 1, text)
  vg.fillColor(white(160))
  discard vg.text(x+w*0.5 - tw*0.5 + iw*0.25, y+h*0.5, text)


proc drawSlider(vg: NVGcontext, pos, x, y, w, h: float) =
  let
    cy = y + floor(h*0.5)
    kr = floor(h*0.25)

  vg.save()

  # Slot
  var bg = vg.boxGradient(x, cy-2+1, w,4, 2, 2, black(32), black(128))
  vg.beginPath()
  vg.roundedRect(x, cy-2, w, 4, 2)
  vg.fillPaint(bg)
  vg.fill()

  # Knob Shadow
  bg = vg.radialGradient(x + floor(pos*w), cy+1, kr-3, kr+3,
                         black(64), black(0))
  vg.beginPath()
  vg.rect(x + floor(pos*w)-kr-5, cy-kr-5, kr*2+5+5, kr*2+5+5+3)
  vg.circle(x + floor(pos*w), cy, kr)
  vg.pathWinding(sHole)
  vg.fillPaint(bg)
  vg.fill()

  # Knob
  let knob = vg.linearGradient(x, cy-kr, x, cy+kr, white(16), black(16))
  vg.beginPath()
  vg.circle(x + floor(pos*w), cy, kr-1)
  vg.fillColor(rgb(40, 43, 48))
  vg.fill()
  vg.fillPaint(knob)
  vg.fill()

  vg.beginPath()
  vg.circle(x + floor(pos*w), cy, kr-0.5)
  vg.strokeColor(black(92))
  vg.stroke()

  vg.restore()


proc drawEyes(vg: NVGcontext, x, y, w, h, mx, my, t: float) =
  let
    ex = w * 0.23
    ey = h * 0.5
    lx = x + ex
    ly = y + ey
    rx = x + w - ex
    ry = y + ey
    br = (if ex < ey: ex else: ey) * 0.5
    blink = 1 - pow(sin(t*0.5),200)*0.8

  var
    bg = vg.linearGradient(x, y+h*0.5, x+w*0.1, y+h, black(32), black(16))

  vg.beginPath()
  vg.ellipse(lx+3.0, ly+16.0, ex, ey)
  vg.ellipse(rx+3.0, ry+16.0, ex, ey)
  vg.fillPaint(bg)
  vg.fill()

  bg = vg.linearGradient(x, y+h*0.25, x+w*0.1, y+h, gray(220), gray(128))
  vg.beginPath()
  vg.ellipse(lx, ly, ex, ey)
  vg.ellipse(rx, ry, ex, ey)
  vg.fillPaint(bg)
  vg.fill()

  var
    dx: float = (mx - rx) / (ex * 10)
    dy: float = (my - ry) / (ey * 10)

    d = sqrt(dx*dx + dy*dy)

  if d > 1.0:
    dx /= d
    dy /= d

  dx *= ex*0.4
  dy *= ey*0.5
  vg.beginPath()
  vg.ellipse(lx+dx, ly+dy+ey*0.25*(1-blink), br, br*blink)
  vg.fillColor(gray(32))
  vg.fill()

  dx = (mx - rx) / (ex * 10)
  dy = (my - ry) / (ey * 10)

  d = sqrt(dx*dx + dy*dy)
  if d > 1.0:
    dx /= d
    dy /= d

  dx *= ex*0.4
  dy *= ey*0.5

  vg.beginPath()
  vg.ellipse(rx+dx, ry+dy+ey*0.25*(1-blink), br, br*blink)
  vg.fillColor(gray(32))
  vg.fill()

  var gloss = vg.radialGradient(lx-ex*0.25, ly-ey*0.5, ex*0.1, ex*0.75,
                                white(128), white(0))
  vg.beginPath()
  vg.ellipse(lx, ly, ex, ey)
  vg.fillPaint(gloss)
  vg.fill()

  gloss = vg.radialGradient(rx-ex*0.25, ry-ey*0.5, ex*0.1, ex*0.75,
                            white(128), white(0))
  vg.beginPath()
  vg.ellipse(rx, ry, ex, ey)
  vg.fillPaint(gloss)
  vg.fill()


proc drawGraph(vg: NVGcontext, x, y, w, h, t: float) =
  var
    samples: array[6, float]
    sx: array[6, float]
    sy: array[6, float]

  let dx = w / 5.0

  samples[0] = (1 + sin(t*1.2345  + cos(t*0.33457)*0.44)) * 0.5
  samples[1] = (1 + sin(t*0.68363 + cos(t*1.3)*1.55)) * 0.5
  samples[2] = (1 + sin(t*1.1642  + cos(t*0.33457)*1.24)) * 0.5
  samples[3] = (1 + sin(t*0.56345 + cos(t*1.63)*0.14)) * 0.5
  samples[4] = (1 + sin(t*1.6245  + cos(t*0.254)*0.3) ) * 0.5
  samples[5] = (1 + sin(t*0.345   + cos(t*0.03)*0.6) ) * 0.5

  for i in 0..5:
    sx[i] = x + float(i) * dx
    sy[i] = y + h * samples[i] * 0.8

  # Graph background
  var bg = vg.linearGradient(x, y, x, y+h,
                             rgba(0, 160, 192, 0), rgba(0, 160, 192, 64))
  vg.beginPath()
  vg.moveTo(sx[0], sy[0])

  for i in 1..5:
    vg.bezierTo(sx[i-1] + dx*0.5, sy[i-1], sx[i] - dx*0.5, sy[i],
                sx[i], sy[i])

  vg.lineTo(x+w, y+h)
  vg.lineTo(x, y+h)
  vg.fillPaint(bg)
  vg.fill()

  # Graph line
  vg.beginPath()
  vg.moveTo(sx[0], sy[0]+2)

  for i in 1..5:
    vg.bezierTo(sx[i-1]+dx*0.5, sy[i-1]+2, sx[i]-dx*0.5, sy[i]+2,
                sx[i], sy[i]+2)

  vg.strokeColor(black(32))
  vg.strokeWidth(3.0)
  vg.stroke()

  vg.beginPath()
  vg.moveTo(sx[0], sy[0])

  for i in 1..5:
    vg.bezierTo(sx[i-1]+dx*0.5, sy[i-1], sx[i]-dx*0.5, sy[i], sx[i], sy[i])

  vg.strokeColor(rgb(0, 160, 192))
  vg.strokeWidth(3.0)
  vg.stroke()

  # Graph sample pos
  for i in 0..5:
    bg = vg.radialGradient(sx[i], sy[i]+2, 3.0, 8.0, black(32), black(0))
    vg.beginPath()
    vg.rect(sx[i]-10, sy[i]-10+2, 20, 20)
    vg.fillPaint(bg)
    vg.fill()

  vg.beginPath()
  for i in 0..5:
    vg.circle(sx[i], sy[i], 4.0)
  vg.fillColor(rgb(0, 160, 192))
  vg.fill()

  vg.beginPath()
  for i in 0..5:
    vg.circle(sx[i], sy[i], 2.0)
  vg.fillColor(gray(220))
  vg.fill()

  vg.strokeWidth(1.0)


proc drawSpinner(vg: NVGcontext, cx, cy, r, t: float) =
  let
    a0 = 0.0 + t*6
    a1 = PI + t*6
    r0 = r
    r1 = r * 0.75

  vg.save()

  vg.beginPath()
  vg.arc(cx, cy, r0, a0, a1, pwCW)
  vg.arc(cx, cy, r1, a1, a0, pwCCW)
  vg.closePath()

  let
    ax = cx + cos(a0) * (r0+r1) * 0.5
    ay = cy + sin(a0) * (r0+r1) * 0.5
    bx = cx + cos(a1) * (r0+r1) * 0.5
    by = cy + sin(a1) * (r0+r1) * 0.5

  let paint = vg.linearGradient(ax, ay, bx, by, black(0), black(128))

  vg.fillPaint(paint)
  vg.fill()

  vg.restore()


proc drawThumbnails(vg: NVGcontext, x, y, w, h: float,
                    images: array[12, Image], t: float) =
  let
    cornerRadius = 3.0
    thumb = 60.0
    arry = 30.5
    stackh = (images.len/2) * (thumb+10) + 10
    u = (1 + cos(t*0.5))*0.5
    u2 = (1 - cos(t*0.2))*0.5

  vg.save()

  # Drop shadow
  var shadowPaint = vg.boxGradient(x, y+4, w, h, cornerRadius*2, 20,
                                   black(128), black(0))
  vg.beginPath()
  vg.rect(x-10, y-10, w+20, h+30)
  vg.roundedRect(x, y, w, h, cornerRadius)
  vg.pathWinding(sHole)
  vg.fillPaint(shadowPaint)
  vg.fill()

  # Window
  vg.beginPath()
  vg.roundedRect(x, y, w, h, cornerRadius)
  vg.moveTo(x-10, y+arry)
  vg.lineTo(x+1, y+arry-11)
  vg.lineTo(x+1, y+arry+11)
  vg.fillColor(gray(200))
  vg.fill()

  vg.save()
  vg.scissor(x, y, w, h)
  vg.translate(0, -(stackh - h) * u)

  let dv = 1.0 / float(images.len-1)

  for i in 0..images.high:
    var
      tx = x+10 + (float(i mod 2) * (thumb+10))
      ty = y+10 + (float(i)/2 * (thumb+10))
      iw, ih, ix, iy: float

    let (imgw, imgh) = vg.imageSize(images[i])

    if imgw < imgh:
      iw = thumb
      ih = iw * float(imgh) / float(imgw)
      ix = 0
      iy = -(ih-thumb)*0.5
    else:
      ih = thumb
      iw = ih * float(imgw) / float(imgh)
      ix = -(iw-thumb)*0.5
      iy = 0

    let
      v = float(i) * dv
      a = clamp((u2-v) / dv, 0, 1)

    if a < 1.0:
      drawSpinner(vg, tx+thumb/2, ty+thumb/2, thumb*0.25, t)

    let imgPaint = vg.imagePattern(tx+ix, ty+iy, iw, ih, 0.0/180.0*PI,
                                   images[i], a)
    vg.beginPath()
    vg.roundedRect(tx,ty, thumb,thumb, 5)
    vg.fillPaint(imgPaint)
    vg.fill()

    shadowPaint = vg.boxGradient(tx-1, ty, thumb+2, thumb+2, 5, 3,
                                 black(128), black(0))
    vg.beginPath()
    vg.rect(tx-5, ty-5, thumb+10, thumb+10)
    vg.roundedRect(tx, ty, thumb, thumb, 6)
    vg.pathWinding(sHole)
    vg.fillPaint(shadowPaint)
    vg.fill()

    vg.beginPath()
    vg.roundedRect(tx+0.5, ty+0.5, thumb-1, thumb-1, 4-0.5)
    vg.strokeWidth(1.0)
    vg.strokeColor(white(192))
    vg.stroke()

  vg.restore()

  # Hide fades
  var fadePaint = vg.linearGradient(x, y, x, y+6, gray(200), gray(200, 0))
  vg.beginPath()
  vg.rect(x+4, y, w-8, 6)
  vg.fillPaint(fadePaint)
  vg.fill()

  fadePaint = vg.linearGradient(x, y+h, x, y+h-6, gray(200), gray(200, 0))
  vg.beginPath()
  vg.rect(x+4, y+h-6, w-8, 6)
  vg.fillPaint(fadePaint)
  vg.fill()

  # Scroll bar
  shadowPaint = vg.boxGradient(x+w-12+1, y+4+1, 8, h-8, 3, 4,
                               black(32), black(92))
  vg.beginPath()
  vg.roundedRect(x+w-12, y+4, 8, h-8, 3)
  vg.fillPaint(shadowPaint)
  vg.fill()

  let scrollh = (h/stackh) * (h-8)
  shadowPaint = vg.boxGradient(x+w-12-1, y+4+(h-8-scrollh)*u-1,
                               8, scrollh, 3, 4, gray(220), gray(128))
  vg.beginPath()
  vg.roundedRect(x+w-12+1, y+4+1 + (h-8-scrollh)*u, 8-2, scrollh-2, 2)
  vg.fillPaint(shadowPaint)
  vg.fill()

  vg.restore()


proc drawColorwheel(vg: NVGcontext, x, y, w, h, t: float) =
  vg.save()

  let
    hue = sin(t * 0.12)
    cx = x + w*0.5
    cy = y + h*0.5
    r1 = (if w < h: w else: h) * 0.5 - 5.0
    r0 = r1 - 20.0
    aeps = 0.5 / r1  # half a pixel arc length in radians (2pi cancels out).

  for i in 0..5:
    var
      a0 = float(i) / 6.0 * PI * 2.0 - aeps
      a1 = (float(i) + 1.0) / 6.0 * PI * 2.0 + aeps

    vg.beginPath()
    vg.arc(cx,cy, r0, a0, a1, pwCW)
    vg.arc(cx,cy, r1, a1, a0, pwCCW)
    vg.closePath()

    let
      ax = cx + cos(a0) * (r0+r1) * 0.5
      ay = cy + sin(a0) * (r0+r1) * 0.5
      bx = cx + cos(a1) * (r0+r1) * 0.5
      by = cy + sin(a1) * (r0+r1) * 0.5

      paint = vg.linearGradient(ax, ay, bx, by,
                                hsla(a0 / (PI*2), 1.0, 0.55, 1.0),
                                hsla(a1 / (PI*2), 1.0, 0.55, 1.0))
    vg.fillPaint(paint)
    vg.fill()

  vg.beginPath()
  vg.circle(cx, cy, r0-0.5)
  vg.circle(cx, cy, r1+0.5)
  vg.strokeColor(black(64))
  vg.strokeWidth(1.0)
  vg.stroke()

  # Selector
  vg.save()
  vg.translate(cx, cy)
  vg.rotate(hue*PI*2)

  # Marker on
  vg.strokeWidth(2.0)
  vg.beginPath()
  vg.rect(r0-1, -3, r1-r0+2, 6)
  vg.strokeColor(white(192))
  vg.stroke()

  var paint = vg.boxGradient(r0-3, -5, r1-r0+6, 10, 2,4, black(128), black(0))
  vg.beginPath()
  vg.rect(r0-2-10, -4-10, r1-r0+4+20, 8+20)
  vg.rect(r0-2, -4, r1-r0+4, 8)
  vg.pathWinding(sHole)
  vg.fillPaint(paint)
  vg.fill()

  # Center triangle
  var
    r = r0 - 6
    ax = cos(degToRad(120.0)) * r
    ay = sin(degToRad(120.0)) * r
    bx = cos(degToRad(-120.0)) * r
    by = sin(degToRad(-120.0)) * r

  vg.beginPath()
  vg.moveTo(r,0)
  vg.lineTo(ax, ay)
  vg.lineTo(bx, by)
  vg.closePath()

  paint = vg.linearGradient(r, 0, ax, ay, hsla(hue, 1.0 ,0.5, 1.0), white())
  vg.fillPaint(paint)
  vg.fill()
  paint = vg.linearGradient((r+ax)*0.5, (0+ay)*0.5, bx, by, black(0), black())
  vg.fillPaint(paint)
  vg.fill()
  vg.strokeColor(black(64))
  vg.stroke()

  # Select circle on triangle
  ax = cos(degToRad(120.0)) * r*0.3
  ay = sin(degToRad(120.0)) * r*0.4

  vg.strokeWidth(2.0)
  vg.beginPath()
  vg.circle(ax, ay, 5)
  vg.strokeColor(white(192))
  vg.stroke()

  paint = vg.radialGradient(ax,ay, 7,9, black(64), black(0))
  vg.beginPath()
  vg.rect(ax-20, ay-20, 40, 40)
  vg.circle(ax, ay, 7)
  vg.pathWinding(sHole)
  vg.fillPaint(paint)
  vg.fill()

  vg.restore()

  vg.restore()


proc drawLines(vg: NVGcontext, x, y, w, h, t: float) =
  let
    pad = 5.0
    s = w/9.0 - pad*2

  var
    pts: array[8, float]
    joins = [lcjMiter, lcjRound, lcjBevel]
    caps = [lcjButt, lcjRound, lcjSquare]

  vg.save()

  pts[0] = -s*0.25 + cos(t*0.3) * s*0.5
  pts[1] = sin(t*0.3) * s*0.5
  pts[2] = -s*0.25
  pts[3] = 0
  pts[4] = s*0.25
  pts[5] = 0
  pts[6] = s*0.25 + cos(-t*0.3) * s*0.5
  pts[7] = sin(-t*0.3) * s*0.5

  for i in 0..2:
    for j in 0..2:
      let
        fx = x + s*0.5 + float(i*3+j)/9.0*w + pad
        fy = y - s*0.5 + pad

      vg.lineCap(caps[i])
      vg.lineJoin(joins[j])

      vg.strokeWidth(s*0.3)
      vg.strokeColor(black(160))
      vg.beginPath()
      vg.moveTo(fx+pts[0], fy+pts[1])
      vg.lineTo(fx+pts[2], fy+pts[3])
      vg.lineTo(fx+pts[4], fy+pts[5])
      vg.lineTo(fx+pts[6], fy+pts[7])
      vg.stroke()

      vg.lineCap(lcjButt)
      vg.lineJoin(lcjBevel)

      vg.strokeWidth(1.0)
      vg.strokeColor(rgb(0, 192, 255))
      vg.beginPath()
      vg.moveTo(fx+pts[0], fy+pts[1])
      vg.lineTo(fx+pts[2], fy+pts[3])
      vg.lineTo(fx+pts[4], fy+pts[5])
      vg.lineTo(fx+pts[6], fy+pts[7])
      vg.stroke()

  vg.restore()


type
  DemoData* = object
    images:     array[12, Image]
    fontIcons:  Font
    fontNormal: Font
    fontBold:   Font
    fontEmoji:  Font

proc loadDemoData*(vg: NVGcontext, data: var DemoData): bool =
  if vg == nil: return false

  for i in 0..data.images.high:
    let file = fmt"data/images/image{i+1}.jpg"

    data.images[i] = vg.createImage(file)
    if data.images[i] == NoImage:
      echo fmt"Could not load {file}."
      return false

  data.fontIcons = vg.createFont("icons", "data/entypo.ttf")
  if data.fontIcons == NoFont:
    echo "Could not add icon font."
    return false

  data.fontNormal = vg.createFont("sans", "data/Roboto-Regular.ttf")
  if data.fontNormal == NoFont:
    echo "Could not load regular font."
    return false

  data.fontBold = vg.createFont("sans-bold", "data/Roboto-Bold.ttf")
  if data.fontBold == NoFont:
    echo "Could not load bold font."
    return false

  data.fontEmoji = vg.createFont("emoji", "data/NotoEmoji-Regular.ttf")
  if data.fontEmoji == NoFont:
    echo "Could not load emoji font."
    return false

  discard addFallbackFont(vg, data.fontNormal, data.fontEmoji)
  discard addFallbackFont(vg, data.fontBold, data.fontEmoji)

  return true


proc freeDemoData*(vg: NVGcontext, data: DemoData) =
  if vg == nil: return

  for i in 0..data.images.high:
    vg.deleteImage(data.images[i])


proc drawParagraph(vg: NVGcontext, x, y, width, height, mx, my: float) =
  vg.save()

  vg.fontSize(18.0 * FONT_SIZE_FACTOR)
  vg.fontFace("sans")
  vg.textAlign(haLeft, vaTop)
  var (_, _, lineHeight) = vg.textMetrics()

  # The text break API can be used to fill a large buffer of rows,
  # or to iterate over the text just few lines (or just one) at a time.
  # The "next" variable of the last returned item tells where to continue.
  let maxRows = 3

  var
    text = "This is longer chunk of text.\n  \n  Would have used lorem ipsum but she    was busy jumping over the lazy dog with the fox and all the men who came to the aid of the party.🎉"

    textStart = 0
    textEnd = text.high

    rows = vg.textBreakLines(text, textStart, textEnd, width, maxRows)

    glyphs: array[100, GlyphPosition]
    lineNum = 0
    px: float
    gx, gy: float
    gutter = 0
    yy = y


  while rows.len > 0:
    for row in rows:
      let
        hit = mx > x and mx < (x + width) and
              my >= yy and my < (yy + lineHeight)

      vg.beginPath()
      vg.fillColor(white(if hit: 64 else: 16))
      vg.rect(x, yy, row.width, lineHeight)
      vg.fill()

      vg.fillColor(white())
      discard vg.text(x, yy, text, row.startPos, row.endPos)

      if hit:
        let nglyphs = vg.textGlyphPositions(x, yy, text,
                                            row.startPos, row.endPos, glyphs)
        var
          caretX = if (mx < x + row.width / 2): x else: x + row.width
          px = x

        for j in 0..<nglyphs:
          let
            x0 = glyphs[j].x
            x1 = if (j+1 < nglyphs): glyphs[j+1].x else: x + row.width
            gx = x0 * 0.3 + x1 * 0.7

          if mx >= px and mx < gx:
            caretX = glyphs[j].x
          px = gx

        vg.beginPath()
        vg.fillColor(rgb(255, 192, 0))
        vg.rect(caretX, yy, 1, lineHeight)
        vg.fill()

        gutter = lineNum + 1
        gx = x - 10
        gy = yy + lineHeight / 2

      inc lineNum
      yy += lineHeight

    # Keep going...
    textStart = rows[^1].nextPos
    rows = vg.textBreakLines(text, textStart, textEnd, width, maxRows)

  # Draw gutter
  if gutter > 0:
    let txt = $gutter
    vg.fontSize(13.0 * FONT_SIZE_FACTOR)
    vg.textAlign(haRight, vaMiddle)
    let (bounds, _) = vg.textBounds(gx, gy, txt)

    vg.beginPath()
    vg.fillColor(rgb(255, 192, 0))
    vg.roundedRect(
      floor(bounds.x1 - 4),
      floor(bounds.y1 - 2),
      floor(bounds.x2 - bounds.x1)+8,
      floor(bounds.y2 - bounds.y1)+4,
      (floor(bounds.y2 - bounds.y1)+4) / 2 - 1
    )
    vg.fill()

    vg.fillColor(gray(32))
    discard vg.text(gx, gy, txt)

  # Draw tooltip
  yy += 20.0

  vg.fontSize(13.0 * FONT_SIZE_FACTOR)
  vg.textAlign(haLeft, vaTop)
  vg.textLineHeight(1.2)

  let tooltipText = "Hover your mouse over the text to see calculated caret position."
  let bounds = vg.textBoxBounds(x, yy, 150, tooltipText)

  # Fade the tooltip out when close to it.
  gx = abs((mx - (bounds.x1+bounds.x2)*0.5) / (bounds.x1 - bounds.x2))
  gy = abs((my - (bounds.y1+bounds.y2)*0.5) / (bounds.y1 - bounds.y2))

  vg.globalAlpha(clamp(max(gx, gy) - 0.5, 0, 1))

  vg.beginPath()
  vg.fillColor(gray(220))
  vg.roundedRect(bounds.x1-2,
                 bounds.y1-2,
                 floor(bounds.x2 - bounds.x1)+4,
                 floor(bounds.y2 - bounds.y1)+4, 3)
  px = floor((bounds.x2 + bounds.x1)/2)
  vg.moveTo(px,bounds.y1 - 10)
  vg.lineTo(px+7, bounds.y1 + 1)
  vg.lineTo(px-7, bounds.y1 + 1)
  vg.fill()

  vg.fillColor(black(220))
  vg.textBox(x, yy, 150, tooltipText)

  vg.restore()


proc drawWidths(vg: NVGcontext, x, y, width: float) =
  vg.save()

  vg.strokeColor(black(0))

  var yy = y
  for i in 0..19:
    let w = (float(i)+0.5)*0.1
    vg.strokeWidth(w)
    vg.beginPath()
    vg.moveTo(x,yy)
    vg.lineTo(x+width,yy+width*0.3)
    vg.stroke()
    yy += 10

  vg.restore()


proc drawCaps(vg: NVGcontext, x, y, width: float) =
  let
    caps = [lcjButt, lcjRound, lcjSquare]
    lineWidth = 8.0

  vg.save()

  vg.beginPath()
  vg.rect(x-lineWidth/2, y, width+lineWidth, 40)
  vg.fillColor(white(32))
  vg.fill()

  vg.beginPath()
  vg.rect(x, y, width, 40)
  vg.fillColor(white(32))
  vg.fill()

  vg.strokeWidth(lineWidth)

  for i in 0..2:
    vg.lineCap(caps[i])
    vg.strokeColor(black())
    vg.beginPath()
    vg.moveTo(x, y + float(i)*10 + 5)
    vg.lineTo(x+width, y + float(i)*10 + 5)
    vg.stroke()

  vg.restore()


proc drawScissor(vg: NVGcontext, x, y, t: float) =
  vg.save()

  # Draw first rect and set scissor to it's area.
  vg.translate(x, y)
  vg.rotate(degToRad(5.0))
  vg.beginPath()
  vg.rect(-20,-20,60,40)
  vg.fillColor(rgb(255, 0, 0))
  vg.fill()
  vg.scissor(-20,-20,60,40)

  # Draw second rectangle with offset and rotation.
  vg.translate(40,0)
  vg.rotate(t)

  # Draw the intended second rectangle without any scissoring.
  vg.save()
  vg.resetScissor()
  vg.beginPath()
  vg.rect(-20,-10,60,30)
  vg.fillColor(rgba(255, 128, 0, 64))
  vg.fill()
  vg.restore()

  # Draw second rectangle with combined scissoring.
  vg.intersectScissor(-20,-10,60,30)
  vg.beginPath()
  vg.rect(-20,-10,60,30)
  vg.fillColor(rgb(255, 128, 0))
  vg.fill()

  vg.restore()


proc renderDemo*(vg: NVGcontext, mx, my, width, height, t: float,
                 blowup: bool, data: DemoData) =

  drawEyes(vg, width - 250, 50, 150, 100, mx, my, t)
  drawParagraph(vg, width - 450, 50, 150, 100, mx, my)
  drawGraph(vg, 0, height/2, width, height/2, t)
  drawColorwheel(vg, width - 300, height - 300, 250.0, 250.0, t)

  # Line joints
  drawLines(vg, 120, height-50, 600, 50, t)

  # Line caps
  drawWidths(vg, 10, 50, 30)

  # Line caps
  drawCaps(vg, 10, 300, 30)

  drawScissor(vg, 50, height-80, t)

  vg.save()

  if blowup:
    vg.rotate(sin(t*0.3) * 5.0/180.0 * PI)
    vg.scale(2.0, 2.0)

  # Widgets
  drawWindow(vg, "Widgets 'n Stuff", 50, 50, 300, 400)

  var
    x = 60.0
    y = 95.0

  drawSearchBox(vg, "Search", x,y,280.0,25.0)
  y += 40
  drawDropDown(vg, "Effects", x,y,280,28)
  let popy = y + 14
  y += 45

  # Form
  drawLabel(vg, "Login", x,y, 280,20)
  y += 25
  drawEditBox(vg, "Email",  x,y, 280,28)
  y += 35
  drawEditBox(vg, "Password", x,y, 280,28)
  y += 38
  drawCheckBox(vg, "Remember me", x,y, 140,28)
  drawButton(vg, ICON_LOGIN, "Sign in", x+138, y, 140, 28, rgb(0, 96, 128))
  y += 45

  # Slider
  drawLabel(vg, "Diameter", x, y, 280, 20)
  y += 25
  drawEditBoxNum(vg, "123.00", "px", x+180, y, 100, 28)
  drawSlider(vg, 0.4, x, y, 170, 28)
  y += 55

  drawButton(vg, ICON_TRASH, "Delete", x, y, 160, 28, rgb(128, 16, 8))
  drawButton(vg, 0, "Cancel", x+170, y, 110, 28, black(0))

  # Thumbnails box
  drawThumbnails(vg, 365, popy-30, 160, 300, data.images, t)

  vg.restore()


# TODO implement image saving
#proc mini(int a, int b): int =
#  a < b ? a : b
#
#
#proc unpremultiplyAlpha(unsigned char* image, int w, int h, int stride)
#  int x,y
#
#  # Unpremultiply
#  for y = 0 y < h y++:
#    unsigned char *row = &image[y*stride]
#    for x = 0 x < w x++:
#      int r = row[0], g = row[1], b = row[2], a = row[3]
#      if a != 0:
#        row[0] = floor(mini(r * 255 / a, 255))
#        row[1] = floor(mini(g * 255 / a, 255))
#        row[2] = floor(mini(b * 255 / a, 255))
#      row += 4
#
#  # Defringe
#  for y = 0 y < h y++:
#    unsigned char *row = &image[y*stride]
#    for x = 0 x < w x++:
#      int r = 0, g = 0, b = 0, a = row[3], n = 0
#      if a == 0:
#        if x-1 > 0 and row[-1] != 0:
#          r += row[-4]
#          g += row[-3]
#          b += row[-2]
#          n++
#
#        if x+1 < w and row[7] != 0:
#          r += row[4]
#          g += row[5]
#          b += row[6]
#          n++
#
#        if y-1 > 0 and row[-stride+3] != 0:
#          r += row[-stride]
#          g += row[-stride+1]
#          b += row[-stride+2]
#          n++
#
#        if y+1 < h and row[stride+3] != 0:
#          r += row[stride]
#          g += row[stride+1]
#          b += row[stride+2]
#          n++
#
#        if n > 0:
#          row[0] = r/n
#          row[1] = g/n
#          row[2] = b/n
#
#      row += 4
#
#
#proc setAlpha(unsigned char* image, int w, int h, int stride, unsigned char a) =
#  int x, y
#  for (y = 0 y < h y++):
#    unsigned char* row = &image[y*stride]
#    for (x = 0 x < w x++)
#      row[x*4+3] = a
#
#
#proc flipHorizontal(unsigned char* image, int w, int h, int stride) =
#  int i = 0, j = h-1, k
#  while (i < j);
#    unsigned char* ri = &image[i * stride]
#    unsigned char* rj = &image[j * stride]
#    for (k = 0 k < w*4 k++):
#      unsigned char t = ri[k]
#      ri[k] = rj[k]
#      rj[k] = t
#    i++
#    j--
#
#
#proc saveScreenShot(int w, int h, int premult, const char* name) =
#  unsigned char* image = (unsigned char*)malloc(w*h*4)
#
#  if image == nil:
#    return
#
#  glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, image)
#
#  if premult:
#    unpremultiplyAlpha(image, w, h, w*4)
#  else:
#    setAlpha(image, w, h, w*4, 255)
#
#  flipHorizontal(image, w, h, w*4)
#  stbi_write_png(name, w, h, 4, image, w*4)
#  free(image)
#
