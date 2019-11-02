import strformat

import glad/gl
import nanovg


const
  GRAPH_HISTORY_COUNT = 100
  GPU_QUERY_COUNT = 5

type
  GraphRenderStyle* = enum
    grsFramesPerSec, grsPercent, grsMilliseconds

  PerfGraph* = object
    style: GraphRenderStyle
    name: string
    values: array[GRAPH_HISTORY_COUNT, float]
    head: int

  GPUtimer* = object
    supported*: bool
    cur, ret: int
    queries: array[GPU_QUERY_COUNT, GLuint]


proc startGPUTimer*(timer: var GPUtimer) =
  if not timer.supported: return
  glBeginQuery(GL_TIME_ELAPSED, timer.queries[timer.cur mod GPU_QUERY_COUNT])
  inc timer.cur


proc stopGPUTimer*(timer: GPUtimer): int =
  var available: GLint = 1
  let n = 0
  if not timer.supported: return 0

  glEndQuery(GL_TIME_ELAPSED)
  while available > 0 and timer.ret <= timer.cur:
    # check for results if there are any
    glGetQueryObjectiv(timer.queries[timer.ret mod GPU_QUERY_COUNT],
                       GL_QUERY_RESULT_AVAILABLE, available.addr)
  result = n

proc initGraph*(style: GraphRenderStyle, name: string): PerfGraph =
  result.style = style
  result.name = name

proc updateGraph*(pg: var PerfGraph, frameTime: float) =
  pg.head = (pg.head + 1) mod GRAPH_HISTORY_COUNT
  pg.values[pg.head] = frameTime

proc getGraphAverage*(pg: PerfGraph): float =
  var avg = 0.0
  for i in 0..<GRAPH_HISTORY_COUNT:
    avg += pg.values[i]
  result = avg / GRAPH_HISTORY_COUNT


proc renderGraph*(vg: NVGContext, x, y: float, pg: PerfGraph) =
  var avg = getGraphAverage(pg)

  let
    w = 200.0
    h = 35.0

  vg.beginPath()
  vg.rect(x, y, w, h)
  vg.fillColor(gray(0, 128))
  vg.fill()

  vg.beginPath()
  vg.moveTo(x, y+h)

  if pg.style == grsFramesPerSec:
    for i in 0..<GRAPH_HISTORY_COUNT:
      let
        v = min(
          1.0 / (0.00001 + pg.values[(pg.head+i) mod GRAPH_HISTORY_COUNT]),
          80
        )
        vx = x + (i / (GRAPH_HISTORY_COUNT-1)) * w
        vy = y + h - ((v / 80.0) * h)

      vg.lineTo(vx, vy)

  elif pg.style == grsPercent:
    for i in 0..<GRAPH_HISTORY_COUNT:
      let
        v = min(
          pg.values[(pg.head+i) mod GRAPH_HISTORY_COUNT] * 1.0,
          100.0
        )
        vx = x + (i / (GRAPH_HISTORY_COUNT-1)) * w
        vy = y + h - ((v / 100.0) * h)

      vg.lineTo(vx, vy)

  else:
    for i in 0..<GRAPH_HISTORY_COUNT:
      let
        v = min(
          pg.values[(pg.head+i) mod GRAPH_HISTORY_COUNT] * 1000.0,
          20.0
        )
        vx = x + (i / (GRAPH_HISTORY_COUNT-1)) * w
        vy = y + h - ((v / 20.0) * h)

      vg.lineTo(vx, vy)

  vg.lineTo(x+w, y+h)
  vg.fillColor(rgba(255, 192, 0, 128))
  vg.fill()

  vg.fontFace("sans")

  if pg.name != "":
    vg.fontSize(14.0)
    vg.textAlign(haLeft, vaTop)
    vg.fillColor(gray(240, 192))
    discard vg.text(x+3, y+1, pg.name)

  if pg.style == grsFramesPerSec:
    vg.fontSize(18.0)
    vg.textAlign(haRight, vaTop)
    vg.fillColor(gray(240))
    discard vg.text(x+w-3, y+1, fmt"{(1.0 / avg):.2f} FPS")

    vg.fontSize(15.0)
    vg.textAlign(haRight, vaBottom)
    vg.fillColor(gray(240, 160))
    discard vg.text(x+w-3, y+h-1, fmt"{(avg * 1000.0):.2f} ms")

  elif pg.style == grsPercent:
    vg.fontSize(18.0)
    vg.textAlign(haRight, vaTop)
    vg.fillColor(gray(240))
    discard vg.text(x+w-3, y+1, fmt"{avg:.1f} %")

  else:
    vg.fontSize(18.0)
    vg.textAlign(haRight, vaTop)
    vg.fillColor(gray(240))
    discard vg.text(x+w-3, y+1, fmt"{(avg * 1000.0):.2f} ms")

