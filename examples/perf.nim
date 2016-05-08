import strutils

import glad/gl
import nanovg


type
  GraphRenderStyle* = enum
    GRAPH_RENDER_FPS, GRAPH_RENDER_MS, GRAPH_RENDER_PERCENT

const GRAPH_HISTORY_COUNT = 100

type
  PerfGraph* = object
    style: GraphRenderStyle
    name: string
    values: array[GRAPH_HISTORY_COUNT, float]
    head: int

const GPU_QUERY_COUNT = 5

type
  GPUtimer* = object
    supported*: bool
    cur, ret: int
    queries: array[GPU_QUERY_COUNT, GLuint]


proc startGPUTimer*(timer: var GPUtimer) =
  if not timer.supported:
    return
  glBeginQuery(GL_TIME_ELAPSED, timer.queries[timer.cur mod GPU_QUERY_COUNT])
  inc timer.cur


proc stopGPUTimer*(timer: GPUtimer): int =
  var available: GLint = 1
  var n = 0
  if not timer.supported:
    return 0

  glEndQuery(GL_TIME_ELAPSED)
  while available > 0 and timer.ret <= timer.cur:
    # check for results if there are any
    glGetQueryObjectiv(timer.queries[timer.ret mod GPU_QUERY_COUNT],
                       GL_QUERY_RESULT_AVAILABLE, available.addr)
  return n

proc initGraph*(style: GraphRenderStyle, name: string): PerfGraph =
  result.style = style
  result.name = name

proc updateGraph*(fps: var PerfGraph, frameTime: float) =
  fps.head = (fps.head+1) mod GRAPH_HISTORY_COUNT
  fps.values[fps.head] = frameTime

proc getGraphAverage*(fps: PerfGraph): float =
  var avg = 0.0
  for i in 0..<GRAPH_HISTORY_COUNT:
    avg += fps.values[i]
  result = avg / float(GRAPH_HISTORY_COUNT)


proc renderGraph*(vg: NVGcontextPtr, x, y: float, fps: PerfGraph) =
  var avg = getGraphAverage(fps)

  let
    w = 200.0
    h = 35.0

  vg.beginPath()
  vg.rect(x, y, float(w), float(h))
  vg.fillColor(nvgRGBA(0,0,0,128))
  vg.fill()

  vg.beginPath()
  vg.moveTo(x, y+h)

  if fps.style == GRAPH_RENDER_FPS:
    for i in 0..<GRAPH_HISTORY_COUNT:
      var v = 1.0 / (0.00001 + fps.values[(fps.head+i) mod GRAPH_HISTORY_COUNT])
      if v > 80.0:
        v = 80.0
      var
        vx = x + (float(i) / (GRAPH_HISTORY_COUNT-1)) * w
        vy = y + h - ((v / 80.0) * h)
      vg.lineTo(vx, vy)

  elif fps.style == GRAPH_RENDER_PERCENT:
    for i in 0..<GRAPH_HISTORY_COUNT:
      var v = fps.values[(fps.head+i) mod GRAPH_HISTORY_COUNT] * 1.0
      if v > 100.0:
        v = 100.0
      var
        vx = x + (float(i) / (GRAPH_HISTORY_COUNT-1)) * w
        vy = y + h - ((v / 100.0) * h)
      vg.lineTo(vx, vy)

  else:
    for i in 0..<GRAPH_HISTORY_COUNT:
      var v = fps.values[(fps.head+i) mod GRAPH_HISTORY_COUNT] * 1000.0
      if v > 20.0:
        v = 20.0
      var
        vx = x + (float(i) / (GRAPH_HISTORY_COUNT-1)) * w
        vy = y + h - ((v / 20.0) * h)
      vg.lineTo(vx, vy)

  vg.lineTo(x+w, y+h)
  vg.fillColor(nvgRGBA(255,192,0,128))
  vg.fill()

  vg.fontFace("sans")

  if fps.name[0] != '\0':
    vg.fontSize(14.0)
    vg.textAlign(haLeft, vaTop)
    vg.fillColor(nvgRGBA(240,240,240,192))
    discard vg.text(x+3, y+1, fps.name, nil)

  if fps.style == GRAPH_RENDER_FPS:
    vg.fontSize(18.0)
    vg.textAlign(haRight, vaTop)
    vg.fillColor(nvgRGBA(240,240,240,255))
    var str = (1.0 / avg).formatFloat(ffDecimal, 2) & " FPS"
    discard vg.text(x+w-3, y+1, str, nil)

    vg.fontSize(15.0)
    vg.textAlign(haRight, vaBottom)
    vg.fillColor(nvgRGBA(240,240,240,160))
    str = (avg * 1000.0).formatFloat(ffDecimal, 2) & " FPS"
    discard vg.text(x+w-3, y+h-1, str, nil)

  elif fps.style == GRAPH_RENDER_PERCENT:
    vg.fontSize(18.0)
    vg.textAlign(haRight, vaTop)
    vg.fillColor(nvgRGBA(240,240,240,255))
    var str = avg.formatFloat(ffDecimal, 1) & " %"
    discard vg.text(x+w-3, y+1, str, nil)

  else:
    vg.fontSize(18.0)
    vg.textAlign(haRight, vaTop)
    vg.fillColor(nvgRGBA(240,240,240,255))
    var str = (avg * 1000.0).formatFloat(ffDecimal, 2) & " ms"
    discard vg.text(x+w-3, y+1, str, nil)

