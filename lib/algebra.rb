module Algebra
  include Math

  RADIUS_EARTH = 6372.796924

  def midpoint(coords_a, coords_b)
    lat_a = coords_a[0].to_f
    lon_a = coords_a[1].to_f

    lat_b = coords_b[0].to_f
    lon_b = coords_b[1].to_f

    [((lat_a + lat_b) / 2).to_s, ((lon_a + lon_b) / 2).to_s]
  end

  def random_points_into_a_circumference(coordinates, radius, points = 10)
    center_latitude = deg2rad(coordinates[0].to_f)
    center_longitude = deg2rad(coordinates[1].to_f)

    max_distance = radius / RADIUS_EARTH
    cos_dif = cos(max_distance) - 1
    sin_lat = sin(center_latitude)
    cos_lat = cos(center_latitude)

    (1..points).map {
      dist = acos(rand() * cos_dif + 1)
      bearing = 2 * PI * rand()
      lat = asin(sin_lat * cos(dist) + cos_lat * sin(dist) * cos(bearing))
	    lon = center_longitude + atan2(sin(bearing) * sin(dist) * cos_lat, cos(dist) - sin_lat * sin(lat))

      [rad2deg(lat), rad2deg(normalize(lon))]
    }
  end

  def rad2deg(rad)
    (rad * 180) / Math::PI
  end
  
  def deg2rad(dgr)
    (dgr * Math::PI) / 180
  end

  def normalize(lon)
    if (lon > Math::PI)
      lon = lon - 2 * Math::PI
    elsif (lon < -Math::PI)
      lon = lon + 2 * Math::PI
    end
    lon
  end

end
