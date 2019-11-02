type
  Handle = distinct cint

const NoHandle = Handle(-1)

var h = Handle(5)
if Handle(3) == Handle(2): echo "nope"
