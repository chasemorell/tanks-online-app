-------------------------------------------------
-- vector2d.lua
-- A 2D vector module
--
-- @module Vector2D
-- @author RenÃ© Aye
-- @license MIT
-- @copyright DevilSquid, RenÃ© Aye 2016
-------------------------------------------------
Vector2D = {}

local math_sqrt = math.sqrt

-------------------------------------------------
-- Creates a Vector2D object.
--
-- @number x   x vector value
-- @number y   y vector value
-- @return    a new Vector2D object
--
-- @usage 
-- local vec1 = Vector2D:new( 12, 36.2 )
-------------------------------------------------
function Vector2D:new(x, y)  
  local object = { x = x or 0, y = y or 0 }
  setmetatable(object, { __index = Vector2D })  
  return object
end
 

-------------------------------------------------
-- Creates a copy of a Vector2D object
-- @return a new Vector2D object
--
-- @usage 
-- local vec2 = vec1:copy()
-------------------------------------------------
function Vector2D:copy()
   return Vector2D:new(self.x, self.y)
end
 

-------------------------------------------------
-- Calculates the magnitude of a Vector2D object.
--
-- This coresponds to the distance from coordinates 0,0 
-- to the position of this vector
--
-- @return the magnitude as a number
--
-- @usage 
-- local mag = vec1:magnitude()
-------------------------------------------------
function Vector2D:magnitude()
   return math_sqrt( self.x*self.x + self.y*self.y )
end


-------------------------------------------------
-- Normalizes a Vector2D object.
--
-- @return nothing
--
-- @usage 
-- vec1:normalize()
-------------------------------------------------
function Vector2D:normalize()
   local temp
   temp = self:magnitude()
   if temp > 0 then
      self.x = self.x / temp
      self.y = self.y / temp
   end
end
 

-------------------------------------------------
-- Limits the Vector2D.
--
-- Limits the x and y values of a Vector2D object to a maximum
--
-- @number l maximum value of the x and y
-- @return nothing
--
-- @usage 
-- -- if x or y values are bigger than 15 then limit them to 15
-- vec1:limit( 15 )
-------------------------------------------------
function Vector2D:limit(l)
   if self.x > l then
      self.x = l     
   end
   
   if self.y > l then
      self.y = l     
   end
end


-------------------------------------------------
-- Check if two vectors are equal.
--
-- @param vec a Vecor2D object to compare to
-- @return true if both vectors are the same
-- @return false if both vectors are different
--
-- @usage 
-- local isEqual = vec1:equals( vec2 )
-------------------------------------------------
function Vector2D:equals( vec )
   if self.x == vec.x and self.y == vec.y then
      return true
   else
      return false
   end
end


-------------------------------------------------
-- Adds two vectors.
--
-- @param vec a Vector2D object to add
-- @return nothing
--
-- @usage 
-- -- vec2 gets added to vec1
-- vec1:add( vec2 )
-------------------------------------------------
function Vector2D:add(vec)
   self.x = self.x + vec.x
   self.y = self.y + vec.y
end


-------------------------------------------------
-- Subtracts two vectors.
--
-- @param vec a Vector2D object to subtract
-- @return nothing
--
-- @usage 
-- -- vec2 gets subtracted from vec1
-- vec1:sub( vec2 )
-------------------------------------------------
function Vector2D:sub(vec)
   self.x = self.x - vec.x
   self.y = self.y - vec.y
end


-------------------------------------------------
-- Multipplies the vector with a value.
--
-- @number s number to multiply the x and y value with
-- @return nothing
--
-- @usage 
-- vec1:mult( 12 )
-------------------------------------------------
function Vector2D:mult(s)
   self.x = self.x * s
   self.y = self.y * s
end
 

-------------------------------------------------
-- Divides the vector with a value.
--
-- @number s number to divide the x and y value with
-- @return nothing
--
-- @usage 
-- vec1:div( 12 )
-------------------------------------------------
function Vector2D:div( s )
   self.x = self.x / s
   self.y = self.y / s
end


-------------------------------------------------
-- Creates a dot product of two vectors
--
-- @param vec a Vecor2D object to compare to
-- @return nothing
--
-- @usage 
-- vec1:dot( vec2 )
-------------------------------------------------
function Vector2D:dot( vec )
   return self.x * vec.x + self.y * vec.y
end
 

-------------------------------------------------
-- Calcuates the distance between two vectors
--
-- @param vec a Vecor2D object to compare to
-- @return nothing
--
-- @usage 
-- vec1:dist( vec2 )
-------------------------------------------------
function Vector2D:dist( vec )
   --return math_sqrt( (vec2.x - self.x) + (vec2.y - self.y) )
   dx = (vec.x - self.x)
   dy = (vec.y - self.y)
   return math_sqrt( dx*dx + dy*dy )
end
 

-------------------------------------------------
-- Calcuates the distance between two vectors
--
-- @param vec a Vecor2D object to compare to
-- @return nothing
--
-- @usage 
-- vec1:dist( vec2 )
-------------------------------------------------
function Vector2D:print()
   print(self.x, self.y)
end


-- Class Methods

-------------------------------------------------
-- Vector2D:NormalA(vec)
--
function Vector2D:NormalA(vec)
  local tempVec = Vector2D:new(0,0)
  tempVec.x = vec.y * (-1)
  tempVec.y = vec.x
  return tempVec
end

-------------------------------------------------
-- Vector2D:NormalB(vec)
--
function Vector2D:NormalB(vec)
  local tempVec = Vector2D:new(0,0)
  tempVec.x = vec.y
  tempVec.y = vec.x * (-1)
  return tempVec
end


-------------------------------------------------
-- Creates a normalized Vector2D of a different Vector2D object.
--
-- @param vec The vector that is used to calculate the normalized value
-- @return a new Vector2D object
--
-- @usage 
-- local vec2 = Vector2D:Normalize( vec1 ) 
-------------------------------------------------
function Vector2D:Normalize( vec ) 
   local tempVec = Vector2D:new(vec.x,vec.y)
   local temp
   temp = tempVec:magnitude()
   if temp > 0 then
      tempVec.x = tempVec.x / temp
      tempVec.y = tempVec.y / temp
   end
   
   return tempVec
end


-------------------------------------------------
-- Limits a Vector2D object.
--
-- @param vec First vector object to be limited
-- @number l limit value
-- @return (**Vector2D**) a new resulting Vector2D object
--
-- @usage 
-- local vec2 = Vector2D:Sub( vec1, 12 ) 
-------------------------------------------------
function Vector2D:Limit(vec,l)
   local tempVec = Vector2D:new(vec.x,vec.y)
   
   if tempVec.x > l then
      tempVec.x = l     
   end
   
   if tempVec.y > l then
      tempVec.y = l     
   end
   
   return tempVec
end



-------------------------------------------------
-- Vector2D:LimitMagnitude(vec, max)
--
function Vector2D:LimitMagnitude(vec, max)
    local tempVec = Vector2D:new(vec.x, vec.y)
    local lengthSquared = tempVec.x * tempVec.x + tempVec.y * tempVec.y
    if lengthSquared > max * max and lengthSquared > 0 then
        local ratio = max / math_sqrt(lengthSquared)
        tempVec.x = tempVec.x * ratio
        tempVec.y = tempVec.y * ratio
    end

    return tempVec
end


-------------------------------------------------
-- Adds two Vector2D objects.
--
-- @param vec1 First vector object
-- @param vec2 Second vector object
-- @return (**Vector2D**) a new resulting Vector2D object
--
-- @usage 
-- local vec3 = Vector2D:Add( vec1, vec2 ) 
-------------------------------------------------
function Vector2D:Add(vec1, vec2)
   local vec = Vector2D:new(0,0)
   vec.x = vec1.x + vec2.x
   vec.y = vec1.y + vec2.y
   return vec
end


-------------------------------------------------
-- Subtracts two Vector2D objects.
--
-- @param vec1 First vector object
-- @param vec2 Second vector object
-- @return (**Vector2D**) a new resulting Vector2D object
--
-- @usage 
-- local vec3 = Vector2D:Sub( vec1, vec2 ) 
-------------------------------------------------
function Vector2D:Sub(vec1, vec2)
   local vec = Vector2D:new(0,0)
   vec.x = vec1.x - vec2.x
   vec.y = vec1.y - vec2.y
   
   return vec
end


-------------------------------------------------
-- Multiplies a Vector2D object with a number.
--
-- @param vec First vector object (**Vector2D**)
-- @number s Number multiplier
-- @return (**Vector2D**) a new resulting Vector2D object
--
-- @usage 
-- local vec2 = Vector2D:Mult( vec1, 4 ) 
-------------------------------------------------
function Vector2D:Mult(vec, s)
   local tempVec = Vector2D:new(0,0)
   tempVec.x = vec.x * s
   tempVec.y = vec.y * s
   
   return tempVec
end


-------------------------------------------------
-- Divides a Vector2D object by a number.
--
-- @param vec First vector object (**Vector2D**)
-- @number s Number divisor
-- @return (**Vector2D**) a new resulting Vector2D object
--
-- @usage 
-- local vec2 = Vector2D:Div( vec1, 2.5 ) 
-------------------------------------------------
function Vector2D:Div(vec, s)
   local tempVec = Vector2D:new(0,0)
   tempVec.x = vec.x / s
   tempVec.y = vec.y / s
   
   return tempVec
end


-------------------------------------------------
-- Manhattan Distance Calculation.
--
-- A faster but more inaccurate distance calculation between two vectors
--
-- @param vec1 First vector object
-- @param vec2 Second vector object
-- @return (**number**) the distance
--
-- @usage 
-- local distance = Vector2D:DistManhattan( vec1, vec2 ) 
-------------------------------------------------
function Vector2D:DistManhattan(vec1, vec2)
   dx = math.abs((vec2.x - vec1.x))
   dy = math.abs((vec2.y - vec1.y))
   return dx + dy
end

-- ----------------------------------------------------------------
-- distEuclidianSquared - Fast semi-accurate distance heuristic. 
-- The only issue with this one is it treats distances as the square of itself.
function Vector2D:DistEuclidianSquared(vec1, vec2)
   dx = (vec2.x - vec1.x)
   dy = (vec2.y - vec1.y)
   return ((dx*dx) + (dy*dy))
end

-------------------------------------------------
-- Classic Euclidian Distance Calculation.
--
-- Slow but accurate distance heuristic between two vectors
--
-- @param vec1 First vector object
-- @param vec2 Second vector object
-- @return (**number**) the distance
--
-- @usage 
-- local distance = Vector2D:Dist( vec1, vec2 ) 
-------------------------------------------------
function Vector2D:Dist(vec1, vec2)
   dx = (vec2.x - vec1.x)
   dy = (vec2.y - vec1.y)
   return math_sqrt( dx*dx + dy*dy )
end


-------------------------------------------------
-- Draws a vector position.
--
-- @param[opt] radius the size of the dot, default = 2
-- @return nothing
--
-- @usage 
-- vec1:Draw( 5 ) 
-------------------------------------------------
function Vector2D:Draw( radius )
  display.newCircle( self.x, self.y, radius or 2 )
end

return Vector2D