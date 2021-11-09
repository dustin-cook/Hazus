# Hazus
Runs Hazus loss assessment

### Current Limitations
- Only runs rail station and rail track assessments
  - rail tracks assessemnt currenlty calculated pgd using overlysimplified (and incorrect) conversion from pga
  - equivalent PGA curves for assessing rail stations are precalculated assuming around a Mw 7.0 event, for a WUS region, for Site Class D, and greater than 15km site-to-source distances
- Only set up to run single scenario assessement of a network and calculated mean loss or recovery time
