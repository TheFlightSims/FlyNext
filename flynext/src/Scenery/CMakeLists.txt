include(FlightGearComponent)

set(SOURCES
	SceneryPager.cxx
	redout.cxx
	scenery.cxx
	terrain_stg.cxx
	terrain_pgt.cxx
	tilecache.cxx
	tileentry.cxx
	tilemgr.cxx
  marker.cxx
	)

set(HEADERS
	SceneryPager.hxx
	redout.hxx
	scenery.hxx
	terrain.hxx
	terrain_stg.hxx
	terrain_pgt.hxx
	tilecache.hxx
	tileentry.hxx
	tilemgr.hxx
  marker.hxx
	)

flightgear_component(Scenery "${SOURCES}" "${HEADERS}")
