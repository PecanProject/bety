
module Mercator
  #MercatorProjection code from: http://ym4r.rubyforge.org/
  #Structure that contains configuration data for the WMS tiler
  FurthestZoom = Struct.new(:ul_corner, :zoom, :tile_size)
  
  #Contains LatLon coordinates
  LatLng = Struct.new(:lat,:lng)
  
  #Contain projected coordinates (in pixel or meter)
  Point = Struct.new(:x,:y)

  class MercatorProjection
    DEG_2_RAD = Math::PI / 180
    WGS84_SEMI_MAJOR_AXIS = 6378137.0
    WGS84_ECCENTRICITY = 0.0818191913108718138
    
    attr_reader :zoom, :size, :pixel_per_degree, :pixel_per_radian, :origin, :precision
    
    def initialize(zoom,precision=0)
      @zoom = zoom
      @precision = precision
      #@size = TILE_SIZE * (2 ** zoom)
      @size = 256 * (2 ** zoom)
      @pixel_per_degree = @size / 360.0
      @pixel_per_radian = @size / (2 * Math::PI)
      @origin = Point.new(@size / 2 , @size / 2)
    end
    
    def borne(number, inf, sup)
      if(number < inf)
        inf
      elsif(number > sup)
        sup
      else
        number
      end
    end
    
    #Transforms LatLon coordinate into pixel coordinates in the Google Maps sense
    #See http://www.math.ubc.ca/~israel/m103/mercator/mercator.html for details
    def latlng_to_pixel(latlng)
      answer = Point.new
      answer.x = (@origin.x + latlng.lng * @pixel_per_degree).round(@precision)
      sin = borne(Math.sin(latlng.lat * DEG_2_RAD),-0.9999,0.9999)
      answer.y = (@origin.y + 0.5 * Math.log((1 + sin) / (1 - sin)) * -@pixel_per_radian).round(@precision)
      answer
    end
  
    def lat_to_pixel(lat)
      sin = borne(Math.sin(lat * DEG_2_RAD),-0.9999,0.9999)
      (@origin.y + 0.5 * Math.log((1 + sin) / (1 - sin)) * -@pixel_per_radian).round(@precision)
    end
  
    def lng_to_pixel(lng)
      (@origin.x + lng * @pixel_per_degree).round(@precision)
    end
    
  end
end
