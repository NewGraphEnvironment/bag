# Package index

## Fetch

Bring data onto disk — from a URL, from a GeoServer WFS endpoint, or
from a GPS unit’s GPX files.

- [`bag_gpx_import()`](http://www.newgraphenvironment.com/bag/reference/bag_gpx_import.md)
  : Import GPX waypoints and tracks from a GPS mounted as a volume
- [`bag_url()`](http://www.newgraphenvironment.com/bag/reference/bag_url.md)
  : Download and Convert Files to GeoPackage Layers
- [`bag_wfs()`](http://www.newgraphenvironment.com/bag/reference/bag_wfs.md)
  : Download a Vector Layer from a GeoServer WFS

## BC Data Catalogue

Find a catalogue layer and describe its columns, then download it to a
GeoPackage or read it into R.

- [`bag_bcdc()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc.md)
  : Download a BC Data Catalogue Layer to a GeoPackage
- [`bag_bcdc_cols()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc_cols.md)
  : Describe one column of a BC Data Catalogue layer
- [`bag_bcdc_index()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc_index.md)
  : Build a lookup table of BC Data Catalogue layers
- [`bag_bcdc_read()`](http://www.newgraphenvironment.com/bag/reference/bag_bcdc_read.md)
  : Read a BC Data Catalogue layer

## Files

Inspect, convert and back up spatial files.

- [`bag_backup()`](http://www.newgraphenvironment.com/bag/reference/bag_backup.md)
  : Back up a file, with an optional timestamp
- [`bag_gpkg_refresh()`](http://www.newgraphenvironment.com/bag/reference/bag_gpkg_refresh.md)
  : Refresh a single-layer point GeoPackage's coordinate columns
- [`bag_gpkg_to_geojson()`](http://www.newgraphenvironment.com/bag/reference/bag_gpkg_to_geojson.md)
  : Write every layer of a GeoPackage out as GeoJSON
- [`bag_layers()`](http://www.newgraphenvironment.com/bag/reference/bag_layers.md)
  : Summarise Layers and Geometry Types in a Spatial Data Source

## Coordinates

Move between geometry and UTM or latitude/longitude columns.

- [`bag_assign_latlong()`](http://www.newgraphenvironment.com/bag/reference/bag_assign_latlong.md)
  : Assign latitude and longitude columns to an sf point object
- [`bag_assign_utm()`](http://www.newgraphenvironment.com/bag/reference/bag_assign_utm.md)
  : Assign UTM zone, easting and northing to an sf point object
- [`bag_sf_from_utm()`](http://www.newgraphenvironment.com/bag/reference/bag_sf_from_utm.md)
  : Build an sf object from NAD 83 UTM zone, easting and northing
  columns
