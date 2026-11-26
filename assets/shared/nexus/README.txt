Nexus Engine - base game data layout
====================================

Everything the base game defines lives in this folder:

  weeks/        week definitions and weekList.txt
  stages/       stage definitions
  characters/   character definitions
  data/         charts (data/<song>/<song>.json), characterList.txt, introText.txt, ...

The code still asks for "weeks/week1.json", "characters/bf.json" and so on.
backend/NexusLayout.hx + Paths.getSharedPath() send those requests to this folder.

Mods are not affected: a mod keeps its own weeks/, stages/, characters/ and data/ folders.
