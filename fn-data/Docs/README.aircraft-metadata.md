Aircraft meta-data

The aim of aircraft meta-data is to make the user-experience around aircraft as easy and correct as possible, 
especially for less experienced users. Meta-data is collected in the aircraft's -set.xml file as properties,
and extracted by various tools. Most notably the website and catalog (hangar) system use aircraft meta-data
to present aircraft to users before downloading / installing aircraft.

(The wiki also parses this information for each aircraft page)

Basic Information

- the name of your aircraft. For historical reasons this is stored in a tag called <description>, but
treat it like full name of your aircraft. This is the primary string displayed to users, so ensure it's
fully descriptive without being too long.

Good examples: 
    - Boeing 737-800
    - Cessna C172P (with floats)
    - Mikoyan MiG-27 (Flogger)

Bad examples:
    - B738 
        (too short / confusing)
    - deHavilland Canada DHC-6 Twin Otter 
        (manufacturer name is overly detailed, 'DHC-6 Twin Otter' would be fine)
    - Boeing / McDonnell-Douglas MD-11
        (Yes Boeing bought McDonnell-Douglas but not important info for the name,
        probably 'McDonnell-Doughal MD-11' is sufficient)

Where the name is long, remember that the description (discussed below) is also searched when
searching aircraft. Therefore, it may be appropriate to omit information from the name, to keep
the total length shorter.

- an brief description of your aircraft. This is stored in <long-description> and should be a few sentances
or paragraphs at most. Do not include formatting in this text, it will be word-wrapped when presented. 
(Paragraph breaks will be included)

Typically the text should include useful search terms, and often corresponds to the introductory
paragraph you might encounter for the aircraft on Wikipedia. It's not intended to be a comprehensive
README, just enough to help the user decide if this is the aircraft they want, especially when
comparing different versions or variants

Mentioning nicknames for aircraft in the description is encouraged, since this again aids user
searches: eg 'jumbo jet' for the 747, or 'mad dog' for the MD-80. 

The long-description can be localized by supplying a value inside langauge tags:

<de>
    <long-description>...description in Germans</long-description>
</de>

- ratings

.. link to the main aircraft ratings policy ...


- tags

The tag system allows systems to categorise aircraft, for example allowing more advanced searches
in the future. Tags allow better feedback to the user when interacting with your aircraft - for
example if the aircraft is tagged as towable, a glider, or a helicopter, the startup behaviour
can be customised.

Most importantly, set the following tags if appropriate:

    glider
    helicopter
    floats
    skis
    seaplane
    airship
    amphibious
    vtol

These tags are the most helpful in customising the start-up experience based on the
type of aircraft. (Especially, which starting locations are offered / preferred
when searching)

- author information

Previously, aircraft could define a single <author> tag with a string listing the authors
of the aircraft. This often ended up containing other information, and for complex
aircraft, could become very long.

For FlightGear 2018.3.0 onwards there is a replacement system, based around a structured
list of authors. For each author their name can be supplied, and optionally other data
if desired: nickname, email and a description of what they contributed.

(The strucutre of this deliberatley matches that for add-ons)

Both the old and and new data can co-exist to allow aircraft compatability with older
versions of FlightGear.

- maintainers information

To distuinguish contributions and previous authors from active maintainers, there
is a seperate maintainers section which can be provided. The syntax is the same
as for the authors, but the contact email is more important. In the future we might
potentially use this data to contact / notify all maintainers of aircraft.

- URL information

Aircraft can list significant URLs, such as their home page, support forum or code
repository. Again the format matches that uses for add-ons:

<urls>
    <home-page>http://www.flightgear.org</home-page>
    <wikipedia>https://en.wikipedia.org/wiki/Cessna_172</wikipedia>
</urls>

- previews (splash screens)

Preview images allow users to make a visual assement of an aircraft when browing
a hangar, and also provide a richer visual experience when using the built-in
launcher and when starting up. 

Do /not/ include text or logo elements in preview images, since this reduces where
and how they can be used. For use on splash-screens, there is explicit support
overlaying a logo image instead of text. (link to the docs on this...)

Performance and Flight-planning Data

Information under /aircraft/performance is used for providing reasonable
default values in the UI, and suggesting when user-entered values might
be inappropriate. (Note these values do not influence the actual simulation
at all, they are informational only)

/aircraft/performance/minimum

    * minimum-takeoff-length-ft 
    * minimum-landing-length-ft

If present, this will be used to improve airport and runway selection, by
preferring airports with sufficiently large runways to operate.

/aircraft/performance/cruise

    * mach
    * airspeed-knots
    * altitude-ft
    * flight-level

These values set defaults when planning a flight, and allow basic estimation
of the enroute time for a flight-plan. Provide either a Mach or knots value,
and similarly either a flight-level or altitude value.

/aircraft/performance/maximum

    * mach
    * airspeed-knots
    * altitude-ft
    * flight-level

These values allow the UI to warn if the user would exceed aircraft paramters,
for example with their choosen starting configuration. (The user can choose to
ignore the warning, of course)

/aircraft/performance/approach

    * airspeed-knots

This value allows the UI to suggest a plausibe value for approaches / pattern
operations for the aircraft.

/aircraft/icao/

    * type

This is the official ICAO aircraft type string. This can be looked up here:
