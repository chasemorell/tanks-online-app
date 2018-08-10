-- converts a table of {x,y,x,y,...} to points {x,y}
local function tableToPoints( tbl )
  local pts = {}
  
  for i=1, #tbl-1, 2 do
    pts[#pts+1] = { x=tbl[i], y=tbl[i+1] }
  end
  
  return pts
end
math.tableToPoints = tableToPoints
 
-- converts a list of points {x,y} to a table of coords {x,y,x,y,...}
local function pointsToTable( pts )
  local tbl = {}
  
  for i=1, #pts do
    tbl[#tbl+1] = pts[i].x
    tbl[#tbl+1] = pts[i].y
  end
  
  return tbl
end
math.pointsToTable = pointsToTable

-- ensures that a list of coordinates is converted to a table of {x,y} points
-- returns a table of {x,y} points and the number of points, whether a display group or not
local function ensurePointsTable( tbl )
  if (type(tbl[1]) == "number") then
    -- list contains {x,y,x,y,...} coordinates - convert to table of {x,y} 
    tbl = tableToPoints( tbl )
    return tbl, #tbl
  else
    -- table is already in {x,y} point format...
    -- check for display group
    local count = tbl.numChildren
    if (count == nil) then
      count = #tbl
    end
    return tbl, count
  end
end
math.ensurePointsTable = ensurePointsTable


--[[
  Calculates the middle of a polygon's bounding box - as if drawing a square around the polygon and finding the middle.
  Also calculates the width and height of the bounding box.
  
  Parameters:
    Polygon coordinates as a table of points, display group or list of coordinates.
  
  Returns:
    Centroid (centre) x, y
    Bounding box width, height
  
  Notes:
    Does not centre the polygon. To do this use: math.centrePolygon
]]--
local function getBoundingCentroid( pts )
  pts = math.ensurePointsTable( pts )
  
  local xMin, xMax, yMin, yMax = 100000000, -100000000, 100000000, -100000000
  
  for i=1, #pts do
    local pt = pts[i]
    if (pt.x < xMin) then xMin = pt.x end
    if (pt.x > xMax) then xMax = pt.x end
    if (pt.y < yMin) then yMin = pt.y end
    if (pt.y > yMax) then yMax = pt.y end
  end
  
  local width, height = xMax-xMin, yMax-yMin
  local cx, cy = xMin+(width/2), yMin+(height/2)
  
  local output = {
    centroid = { x=cx, y=cy },
    width = width,
    height = height,
    bounding = { xMin=xMin, xMax=xMax, yMin=yMin, yMax=yMax },
  }
  
  return output
end
math.getBoundingCentroid = getBoundingCentroid

--[[
  Description:
    Calculates the average of all the x's and all the y's and returns the average centre of all points.
    Works with a table proceeding {x,y,x,y,...} as used with display.newLine or physics.addBody
  
  Params:
    pts = table of x,y values in sequence
  
  Returns:
    x, y = average centre location of all points
]]--
local function midPointOfShape( pts )
  local x, y, c, t = 0, 0, #pts, #pts/2
  for i=1, c-1, 2 do
    x = x + pts[i]
    y = y + pts[i+1]
  end
  return x/t, y/t
end
math.midPointOfShape = midPointOfShape
