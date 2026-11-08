-- ****************************************************************************
-- *
-- *  PROJECT:     vRoleplay
-- *  FILE:        client/classes/Faction/Gangwar/GangwarStatistics.lua
-- *  PURPOSE:     Gangwar-Statistics Client Class
-- *
-- ****************************************************************************

function dxDrawBoxText( text , x, y , w , h , ... )
	dxDrawText( text , x , y , x + w , y + h , ... )
end

function dxDrawBoxShape( x, y, w, h , ...)
	dxDrawLine( x, y, x+w,y,...)
	dxDrawLine( x, y+h , x +w , y+h,...)

	dxDrawLine( x , y ,x , y+h , ... )
	dxDrawLine( x+w , y ,x+w , y+h , ...)
end

function dxDrawShadowText( text , x, y , w , h , shadowOffSetX , shadowOffSetY , tCol , sCol , ... )
	dxDrawText( text , x + shadowOffSetX , y + shadowOffSetY , x + w , y + h , sCol, ... )
	dxDrawText( text , x - shadowOffSetX , y - shadowOffSetY  , x + w , y + h , sCol, ... )
	dxDrawText( text , x , y , x + w , y + h , tCol , ... )
end
