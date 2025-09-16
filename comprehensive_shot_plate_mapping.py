#!/usr/bin/env python3
"""
Comprehensive shot-to-plate mapping system based on:
1. Character appearances in prompts and integration guide
2. Environmental progression throughout the film
3. Story understanding and thematic elements
"""

import json
import re
import os
import glob
from typing import Dict, List, Set, Tuple

# Character plate mappings from the integration guide
CHARACTER_PLATE_MAPPINGS = {
    # PROLOGUE SHOTS - Traditional family with supernatural enhancement
    "0a": {},  # Shadow pole - no characters
    "0b": {},  # Wrong voice - no characters
    "1": {},  # Raven transition - no characters
    "1a": {},  # Black boats - hunters only
    "1b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD", "lilja": "LILJA-PURE"},
    "1c": {},  # Landscape only
    "2a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD", "lilja": "LILJA-PURE"},
    "2b": {},  # Breathing cliffs - no characters
    "3a": {"magnus": "MAGNUS-AUTHORITY", "jon": "JON-MILD"},  # Rope lessons father-son
    "3b": {"jon": "JON-MILD"},  # Descent for eggs
    "4a": {},  # Purple hills
    "4b": {},  # Children's bone circle
    "5a": {},  # Whale arrives
    "5b": {},  # Flensing dance
    "5p": {"magnus": "MAGNUS-WATCHING", "sigrid": "SIGRID-AWAKENING", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-RISING", "lilja": "LILJA-SENSING"},
    "6a": {"gudrun": "GUDRUN-ABUNDANT", "sigrid": "SIGRID-AWAKENING"},
    "6b": {},  # Sheep descending
    "7a": {"magnus": "MAGNUS-AUTHORITY", "gudrun": "GUDRUN-ABUNDANT"},  # Feast assembly
    "7b": {},  # Feast continuation
    "8a": {},  # Feast details
    "8b": {},  # More feast
    "8c": {},  # Feast ending
    "9a": {},  # Feast transformation beginning
    "9b": {"magnus": "MAGNUS-TRANSITION", "sigrid": "SIGRID-MARKED", "gudrun": "GUDRUN-WEARING", "jon": "JON-SEEING", "lilja": "LILJA-HARMONIC"},
    "20": {"sigrid": "SIGRID-PURE"},  # Sigrid's winter song
    "21": {},  # Landscape freezes
    "22": {},  # Landscape continuation

    # MAIN STORY - Mathematical breakdown to transformation
    "1": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET", "lilja": "LILJA-MATHEMATICAL"},
    "2": {"magnus": "MAGNUS-CONFUSED", "gudrun": "GUDRUN-PRODUCING"},  # Forystufé prophecy
    "3": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "gudrun": "GUDRUN-PRODUCING"},  # Breathing house
    "4": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED"},  # Window into trap
    "5": {"magnus": "MAGNUS-CONFUSED"},  # Empty ram pen
    "6": {"magnus": "MAGNUS-CONFUSED"},  # Rising authority
    "7": {"magnus": "MAGNUS-CONFUSED", "gudrun": "GUDRUN-PRODUCING"},  # Livestock positioning
    "8": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET", "lilja": "LILJA-MATHEMATICAL"},
    "9": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET", "lilja": "LILJA-MATHEMATICAL"},
    "10": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET", "lilja": "LILJA-MATHEMATICAL"},
    "11": {"gudrun": "GUDRUN-PRODUCING", "magnus": "MAGNUS-CONFUSED"},
    "12": {"sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL"},  # Krummi lullaby
    "13": {},  # Raven at window
    "14": {"magnus": "MAGNUS-CONFUSED", "gudrun": "GUDRUN-PRODUCING"},  # Hidden feast
    "15": {"magnus": "MAGNUS-CONFUSED", "gudrun": "GUDRUN-PRODUCING", "sigrid": "SIGRID-CALCULATING"},  # Mathematical breaking
    "16": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "gudrun": "GUDRUN-PRODUCING"},  # Last light
    "16p": {"sigrid": "SIGRID-PROPHECY"},  # One perfect human moment
    "17": {"magnus": "MAGNUS-PROVIDER", "gudrun": "GUDRUN-PRODUCING"},  # Departure preparation
    "18": {"magnus": "MAGNUS-PROVIDER", "gudrun": "GUDRUN-PRODUCING", "sigrid": "SIGRID-MARKED"},
    "19": {"magnus": "MAGNUS-PROVIDER"},  # Whale oil dies
    "20": {"sigrid": "SIGRID-ORACLE"},  # Sigrid's winter song (main)
    "21": {},  # Landscape freezes (main)
    "22": {},  # More freezing
    "22b": {"magnus": "MAGNUS-RITUAL"},  # Second pull
    "23": {"magnus": "MAGNUS-RITUAL", "gudrun": "GUDRUN-RITUAL", "sigrid": "SIGRID-SUMMONING"},
    "23a": {"sigrid": "SIGRID-SUMMONING"},  # Sigrid breaks silence
    "23b": {"magnus": "MAGNUS-RITUAL"},  # Rope fights back
    "23c": {"magnus": "MAGNUS-RITUAL", "gudrun": "GUDRUN-RITUAL"},  # Blood circles
    "23p": {},  # Last ship
    "24": {"magnus": "MAGNUS-RITUAL", "gudrun": "GUDRUN-RITUAL", "sigrid": "SIGRID-SUMMONING", "lilja": "LILJA-HARMONIC", "jon": "JON-TEMPORAL"},
    "24a": {"sigrid": "SIGRID-SUMMONING"},  # Giant speaks through her
    "24b": {},  # Eastern response
    "24c": {},  # Western response
    "24d": {},  # Southern/Northern responses
    "25": {"sigrid": "SIGRID-ORACLE"},  # Wrong thing born
    "26": {"magnus": "MAGNUS-AFLOAT"},  # Island trembles
    "27": {"magnus": "MAGNUS-AFLOAT"},  # Stubborn continuation
    "28": {"magnus": "MAGNUS-AFLOAT"},  # Frozen edge
    "29": {"magnus": "MAGNUS-AFLOAT"},  # Launching into nothing
    "30": {"magnus": "MAGNUS-AGING"},  # Hours of nothing
    "31": {"magnus": "MAGNUS-AGING", "jon": "JON-CHANGING", "lilja": "LILJA-SENSING"},  # Children see true shapes
    "32": {"magnus": "MAGNUS-AGING"},  # Underwater truth
    "33": {"magnus": "MAGNUS-AGING"},  # Realization
    "34": {"magnus": "MAGNUS-AGING"},  # Deliberate cut
    "35a": {"magnus": "MAGNUS-WOUNDED"},  # Rifle emerges
    "35b": {"magnus": "MAGNUS-WOUNDED"},  # First shot
    "35c": {"magnus": "MAGNUS-WOUNDED"},  # Jörmungandr withdraws
    "36": {"magnus": "MAGNUS-WOUNDED"},  # Empty victory
    "37": {"sigrid": "SIGRID-ORACLE", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING", "lilja": "LILJA-COMMUNICATING"},
    "38a": {"sigrid": "SIGRID-ORACLE", "gudrun": "GUDRUN-PRODUCING"},  # Fin examined
    "38b": {"magnus": "MAGNUS-DEFEATED"},  # Decision to return
    "39": {"sigrid": "SIGRID-ORACLE", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-GAPPED", "lilja": "LILJA-ACCEPTING"},
    "39p": {"jon": "JON-GAPPED", "lilja": "LILJA-ACCEPTING"},  # Children's hunger
    "40": {"gudrun": "GUDRUN-PRODUCING"},  # Gudrun's silent testimony
    "41": {"magnus": "MAGNUS-PREDATOR", "gudrun": "GUDRUN-BEATEN", "sigrid": "SIGRID-CORNERED", "jon": "JON-GAPPED", "lilja": "LILJA-ACCEPTING"},
    "42a": {"magnus": "MAGNUS-PREDATOR"},  # Door violence
    "42b": {"magnus": "MAGNUS-PREDATOR"},  # Pathetic offering
    "42c": {"magnus": "MAGNUS-ZERO-HZ", "gudrun": "GUDRUN-BEATEN", "sigrid": "SIGRID-CORNERED"},
    "43a": {"magnus": "MAGNUS-ENFORCER"},  # Cane rises
    "43b": {"magnus": "MAGNUS-ENFORCER", "gudrun": "GUDRUN-BEATEN"},  # Strike unseen
    "43c": {"magnus": "MAGNUS-ENFORCER", "gudrun": "GUDRUN-BEATEN"},  # Command to death
    "44a": {"gudrun": "GUDRUN-WALKING"},  # Lamp death
    "44b": {"gudrun": "GUDRUN-WALKING"},  # Following blood trail
    "44c": {"gudrun": "GUDRUN-WALKING"},  # Wool visible
    "45a": {"gudrun": "GUDRUN-CROWNED"},  # Polynya arrival
    "45b": {"gudrun": "GUDRUN-DIVINE"},  # Water changes
    "45c": {"gudrun": "GUDRUN-DIVINE"},  # Griðungur emerges
    "46a": {"gudrun": "GUDRUN-DIVINE"},  # Mutual recognition
    "46b": {"gudrun": "GUDRUN-DIVINE"},  # Offering wool
    "46c": {"gudrun": "GUDRUN-RETURNING"},  # Collapse
    "47a": {"gudrun": "GUDRUN-RETURNING"},  # Trawler speaks
    "47b": {"magnus": "MAGNUS-DEFEATED"},  # Walking through blood
    "47c": {"magnus": "MAGNUS-DEFEATED"},  # House door opens
    "48": {"magnus": "MAGNUS-DEFEATED", "sigrid": "SIGRID-ORACLE", "jon": "JON-GAPPED", "lilja": "LILJA-EVOLVING"},
    "49a": {"magnus": "MAGNUS-POSSESSOR", "sigrid": "SIGRID-CORNERED"},  # Magnus redirects rage
    "49b": {"magnus": "MAGNUS-POSSESSOR", "sigrid": "SIGRID-CORNERED"},  # House responds
    "49c": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING"},  # Krummi evolution
    "50a": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED"},  # Evening falls
    "50b": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED"},  # Old story
    "50c": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED"},  # Male krummi
    "50d": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED"},  # Lingering kiss
    "51a": {"jon": "JON-PROPHET", "lilja": "LILJA-SENSING"},  # Children's shadow prophecy
    "51b": {"gudrun": "GUDRUN-SPEAKING"},  # Empty clothes speaking
    "51c": {"gudrun": "GUDRUN-SPEAKING"},  # Réttir revealed
    "52a": {"sigrid": "SIGRID-TRANSITIONAL"},  # Second monolith
    "52b": {"sigrid": "SIGRID-TRANSITIONAL"},  # Raven's prophecy
    "52c": {"magnus": "MAGNUS-SHIFTING", "sigrid": "SIGRID-CORNERED"},  # Magnus breaks paralysis
    "53a": {"gudrun": "GUDRUN-SPEAKING"},  # House begins to speak
    "53b": {"gudrun": "GUDRUN-SPEAKING"},  # Dying confession
    "53c": {"sigrid": "SIGRID-BECOMING"},  # Bergrisi chooses Sigrid
    "54a": {"magnus": "MAGNUS-SHIFTING", "sigrid": "SIGRID-BECOMING", "gudrun": "GUDRUN-SPEAKING"},
    "54b": {"magnus": "MAGNUS-SHIFTING", "sigrid": "SIGRID-BECOMING", "gudrun": "GUDRUN-SPEAKING"},
    "54c": {"magnus": "MAGNUS-SHIFTING", "sigrid": "SIGRID-BECOMING", "gudrun": "GUDRUN-SPEAKING"},
    "55a": {"magnus": "MAGNUS-RECOGNIZING"},  # Trawler begins circle
    "55b": {"magnus": "MAGNUS-RECOGNIZING"},  # Circle tightens
    "55c": {"magnus": "MAGNUS-BREAKING"},  # The bite
    "55p": {},  # Witness mechanism breaks - no specific characters
    "56": {"magnus": "MAGNUS-SHIFTING", "sigrid": "SIGRID-TRANSITIONAL", "gudrun": "GUDRUN-SPEAKING", "jon": "JON-CHANGING", "lilja": "LILJA-FINAL"},
    "56a": {"magnus": "MAGNUS-SHIFTING"},  # Magnus sees sheep
    "56b": {"gudrun": "GUDRUN-EWE"},  # Headdress sheep
    "56c": {"gudrun": "GUDRUN-EWE"},  # Mamma - human teeth
    "57": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-BECOMING", "gudrun": "GUDRUN-EWE", "jon": "JON-LAMB", "lilja": "LILJA-LAMB"},
    "57a": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-BECOMING"},  # Complete darkness
    "57b": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-BECOMING"},  # Flicker of light
    "57c": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-BECOMING"},  # House speaks in darkness
    "58a": {"sigrid": "SIGRID-DUAL"},  # Light returns
    "58b": {"gudrun": "GUDRUN-EWE"},  # Gudrun-ewe realization
    "58c": {"sigrid": "SIGRID-DUAL"},  # Obelisk rises
    "59a": {"sigrid": "SIGRID-DUAL"},  # House becomes obelisk
    "59b": {"sigrid": "SIGRID-DUAL"},  # Sigrid enters cleft
    "59c": {"sigrid": "SIGRID-DUAL"},  # Sigrid completes transformation
    "60a": {"sigrid": "SIGRID-CORVID"},  # Flight with gammur
    "60b": {"sigrid": "SIGRID-CORVID"},  # Egg laid
    "60c": {"sigrid": "SIGRID-CORVID"},  # Return to obelisk
    "61": {},  # Camera recognizes itself
    "61a": {},  # We are Iceland
    "61b": {},  # Camera as witness
    "61c": {},  # Witness fragments
    "62a": {"magnus": "MAGNUS-RAM", "sigrid": "SIGRID-CORVID", "gudrun": "GUDRUN-ETERNAL", "jon": "JON-LAMB", "lilja": "LILJA-LAMB"},
    "62b": {"magnus": "MAGNUS-RAM", "sigrid": "SIGRID-CORVID", "gudrun": "GUDRUN-ETERNAL", "jon": "JON-LAMB", "lilja": "LILJA-LAMB"},
    "63": {"magnus": "MAGNUS-RAM", "sigrid": "SIGRID-CORVID", "gudrun": "GUDRUN-ETERNAL", "jon": "JON-LAMB", "lilja": "LILJA-LAMB"},
}

# Comprehensive environmental plate mappings
ENVIRONMENTAL_PLATE_MAPPINGS = {
    # PROLOGUE PERIOD - False abundance and seduction
    "0a": ["WESTFJORDS-CLIFF", "LANDSCAPE-ABUNDANT"],  # Shadow pole on headland
    "0b": ["WESTFJORDS-CLIFF", "LANDSCAPE-ABUNDANT"],  # Wrong voice from young mouth
    "1": ["WESTFJORDS-AERIAL", "LANDSCAPE-ABUNDANT"],  # Raven transition
    "1a": ["SEA-DIVINE", "WESTFJORDS-BEACH"],  # Black boats on red water
    "1b": ["SEA-DIVINE", "WESTFJORDS-BEACH", "SEA-ABUNDANT"],  # Spears enter flesh
    "1c": ["WESTFJORDS-CLIFF", "LANDSCAPE-ABUNDANT"],  # Landscape view
    "2a": ["SEA-ABUNDANT", "WESTFJORDS-BEACH", "BADSTOFA-DOMESTIC"],  # Shore division
    "2b": ["WESTFJORDS-CLIFF", "LANDSCAPE-ABUNDANT"],  # Breathing cliffs
    "3a": ["WESTFJORDS-CLIFF", "BADSTOFA-DOMESTIC"],  # Rope lessons at height
    "3b": ["WESTFJORDS-CLIFF"],  # Descent for golden eggs
    "4a": ["WESTFJORDS-INLAND", "LANDSCAPE-ABUNDANT"],  # Purple hills
    "4b": ["WESTFJORDS-BEACH", "BADSTOFA-DOMESTIC"],  # Children's bone circle
    "5a": ["SEA-DIVINE", "WESTFJORDS-BEACH"],  # Whale arrives
    "5b": ["WESTFJORDS-BEACH", "SEA-ABUNDANT", "BADSTOFA-DOMESTIC"],  # Flensing dance
    "5p": ["BADSTOFA-SURVEILLANCE"],  # Surveillance web (special interior)
    "6a": ["BADSTOFA-DOMESTIC", "LANDSCAPE-ABUNDANT"],  # Making purple drink
    "6b": ["WESTFJORDS-INLAND", "LANDSCAPE-ABUNDANT"],  # Sheep descending
    "7a": ["BADSTOFA-DOMESTIC"],  # Feast assembly
    "7b": ["BADSTOFA-DOMESTIC"],  # Feast continuation
    "8a": ["BADSTOFA-STIRRING"],  # Feast with consciousness stirring
    "8b": ["BADSTOFA-STIRRING"],
    "8c": ["BADSTOFA-STIRRING"],
    "9a": ["BADSTOFA-STIRRING"],  # Feast transformation beginning
    "9b": ["BADSTOFA-ORGANIC"],  # Feast to starvation transformation
    "20": ["BADSTOFA-ORGANIC", "WESTFJORDS-WINTER"],  # Sigrid's winter song
    "21": ["WESTFJORDS-WINTER", "LANDSCAPE-HOSTILE"],  # Landscape freezes
    "22": ["WESTFJORDS-WINTER", "LANDSCAPE-HOSTILE"],

    # MAIN STORY - Winter survival and transformation
    "1": ["BADSTOFA-BODY", "WESTFJORDS-WINTER", "LANDSCAPE-HOSTILE"],  # Cosmic abandonment
    "2": ["BADSTOFA-BODY", "WESTFJORDS-WINTER"],  # Forystufé prophecy
    "3": ["BADSTOFA-BODY"],  # Breathing house
    "4": ["BADSTOFA-BODY", "WESTFJORDS-WINTER"],  # Window into trap
    "5": ["BADSTOFA-BODY", "WESTFJORDS-WINTER"],  # Empty ram pen
    "6": ["BADSTOFA-BODY"],  # Rising authority
    "7": ["BADSTOFA-BODY", "WESTFJORDS-WINTER"],  # Livestock positioning
    "8": ["BADSTOFA-BODY"],  # Counting begins
    "9": ["BADSTOFA-BODY"],  # Tre fire fem
    "10": ["BADSTOFA-BODY"],  # Seks - impossible count
    "11": ["BADSTOFA-BODY"],  # Empty bounty
    "12": ["BADSTOFA-BODY"],  # Krummi lullaby
    "13": ["BADSTOFA-BODY", "WESTFJORDS-WINTER"],  # Raven at window
    "14": ["BADSTOFA-BODY"],  # Hidden feast
    "15": ["BADSTOFA-BODY"],  # Mathematical breaking
    "16": ["BADSTOFA-BODY"],  # Last light
    "16p": ["BADSTOFA-PEACEFUL"],  # One perfect human moment (special)
    "17": ["BADSTOFA-BODY"],  # Departure preparations
    "18": ["BADSTOFA-BODY", "WESTFJORDS-WINTER"],  # Departure
    "19": ["BADSTOFA-BODY"],  # Whale oil dies
    "20": ["BADSTOFA-BODY", "WESTFJORDS-WINTER"],  # Sigrid's winter song (main)
    "21": ["WESTFJORDS-WINTER", "LANDSCAPE-HOSTILE"],  # Landscape freezes
    "22": ["WESTFJORDS-WINTER", "LANDSCAPE-HOSTILE"],
    "22b": ["BADSTOFA-BODY"],  # Second pull
    "23": ["BADSTOFA-BODY", "WESTFJORDS-WINTER"],  # Sigrid's preparation
    "23a": ["BADSTOFA-BODY"],  # Sigrid breaks silence
    "23b": ["BADSTOFA-BODY"],  # Rope fights back
    "23c": ["BADSTOFA-BODY", "WESTFJORDS-WINTER"],  # Blood circles
    "23p": ["SEA-EXTRACTED", "WESTFJORDS-FJORD"],  # Last ship
    "24": ["BADSTOFA-BODY", "WESTFJORDS-WINTER"],  # Giant's voice
    "24a": ["BADSTOFA-BODY"],  # Giant speaks through her
    "24b": ["WESTFJORDS-WINTER", "SEA-BATTLE"],  # Eastern response
    "24c": ["WESTFJORDS-WINTER", "SEA-BATTLE"],  # Western response
    "24d": ["WESTFJORDS-WINTER"],  # Southern/Northern
    "25": ["BADSTOFA-BODY"],  # Wrong thing born
    "26": ["SEA-EXTRACTED", "WESTFJORDS-FJORD"],  # Island trembles
    "27": ["SEA-EXTRACTED", "WESTFJORDS-FJORD"],  # Stubborn continuation
    "28": ["SEA-EXTRACTED", "WESTFJORDS-FJORD"],  # Frozen edge
    "29": ["SEA-EXTRACTED", "WESTFJORDS-FJORD"],  # Launching into nothing
    "30": ["SEA-EXTRACTED", "WESTFJORDS-FJORD"],  # Hours of nothing
    "31": ["SEA-EXTRACTED", "BADSTOFA-CLEFT"],  # Children see true shapes
    "32": ["SEA-BATTLE", "WESTFJORDS-FJORD"],  # Underwater truth
    "33": ["SEA-BATTLE", "WESTFJORDS-FJORD"],  # Realization
    "34": ["SEA-BATTLE", "WESTFJORDS-FJORD"],  # Deliberate cut
    "35a": ["SEA-BATTLE", "WESTFJORDS-FJORD"],  # Rifle emerges
    "35b": ["SEA-BATTLE", "WESTFJORDS-FJORD"],  # First shot
    "35c": ["SEA-BATTLE", "WESTFJORDS-FJORD"],  # Jörmungandr withdraws
    "36": ["SEA-EMPTY", "WESTFJORDS-FJORD"],  # Empty victory
    "37": ["BADSTOFA-CLEFT", "WESTFJORDS-BEACH"],  # Shoreline scavenging
    "38a": ["WESTFJORDS-BEACH", "SEA-SEDUCTIVE"],  # Fin examined
    "38b": ["WESTFJORDS-BEACH", "SEA-SEDUCTIVE"],  # Decision to return
    "39": ["BADSTOFA-CLEFT"],  # House transformed
    "39p": ["BADSTOFA-DESPERATE"],  # Children's hunger (special)
    "40": ["BADSTOFA-CLEFT"],  # Gudrun's testimony
    "41": ["BADSTOFA-CLEFT"],  # Children's acceptance
    "42a": ["BADSTOFA-CLEFT"],  # Door violence
    "42b": ["BADSTOFA-CLEFT"],  # Pathetic offering
    "42c": ["BADSTOFA-CLEFT"],  # Recognizing transformation
    "43a": ["BADSTOFA-CLEFT"],  # Cane rises
    "43b": ["BADSTOFA-RECORDING"],  # Shadow violence (special)
    "43c": ["BADSTOFA-CLEFT"],  # Command to death
    "44a": ["BADSTOFA-CLEFT", "WESTFJORDS-WINTER"],  # Lamp death in wind
    "44b": ["WESTFJORDS-WINTER", "LANDSCAPE-PREDATORY"],  # Following blood trail
    "44c": ["WESTFJORDS-WINTER", "LANDSCAPE-PREDATORY"],  # Wool visible
    "45a": ["SEA-CONTAMINATED", "WESTFJORDS-FJORD"],  # Polynya arrival
    "45b": ["SEA-CONTAMINATED", "WESTFJORDS-FJORD"],  # Water changes
    "45c": ["SEA-CONTAMINATED", "WESTFJORDS-FJORD"],  # Griðungur emerges
    "46a": ["SEA-CONTAMINATED", "WESTFJORDS-FJORD"],  # Mutual recognition
    "46b": ["SEA-CONTAMINATED", "WESTFJORDS-FJORD"],  # Offering wool
    "46c": ["SEA-CONTAMINATED", "WESTFJORDS-BEACH"],  # Collapse at shore
    "47a": ["SEA-CONTAMINATED", "WESTFJORDS-FJORD"],  # Trawler speaks
    "47b": ["WESTFJORDS-BEACH", "LANDSCAPE-PREDATORY"],  # Walking through blood
    "47c": ["BADSTOFA-CRYSTALLIZING"],  # House door opens
    "48": ["BADSTOFA-CRYSTALLIZING"],  # Blood dripping entry
    "49a": ["BADSTOFA-CRYSTALLIZING"],  # Magnus redirects rage
    "49b": ["BADSTOFA-CRYSTALLIZING"],  # House responds
    "49c": ["BADSTOFA-CRYSTALLIZING"],  # Krummi evolution
    "50a": ["BADSTOFA-CRYSTALLIZING"],  # Evening falls
    "50b": ["BADSTOFA-CRYSTALLIZING"],  # Old story
    "50c": ["BADSTOFA-CRYSTALLIZING"],  # Male krummi
    "50d": ["BADSTOFA-CRYSTALLIZING"],  # Lingering kiss
    "51a": ["BADSTOFA-CRYSTALLIZING"],  # Children's shadow prophecy
    "51b": ["BADSTOFA-CRYSTALLIZING"],  # Empty clothes speaking
    "51c": ["BADSTOFA-CRYSTALLIZING"],  # Réttir revealed
    "52a": ["BADSTOFA-CRYSTALLIZING"],  # Second monolith
    "52b": ["BADSTOFA-CRYSTALLIZING"],  # Raven's prophecy
    "52c": ["BADSTOFA-CRYSTALLIZING"],  # Magnus breaks paralysis
    "53a": ["BADSTOFA-CRYSTALLIZING"],  # House begins to speak
    "53b": ["BADSTOFA-CRYSTALLIZING"],  # Dying confession
    "53c": ["BADSTOFA-CRYSTALLIZING"],  # Bergrisi chooses Sigrid
    "54a": ["BADSTOFA-CRYSTALLIZING"],  # Morning arrives
    "54b": ["BADSTOFA-CRYSTALLIZING", "WESTFJORDS-WINTER"],  # Bull at threshold
    "54c": ["BADSTOFA-CRYSTALLIZING"],  # Daily routine
    "55a": ["SEA-ACCUSATION", "WESTFJORDS-FJORD"],  # Trawler begins circle
    "55b": ["SEA-ACCUSATION", "WESTFJORDS-FJORD"],  # Circle tightens
    "55c": ["SEA-ACCUSATION", "WESTFJORDS-FJORD"],  # The bite
    "55p": ["BADSTOFA-FRAGMENTING"],  # Witness mechanism (special)
    "56": ["BADSTOFA-CLIFF"],  # Family transformation
    "56a": ["BADSTOFA-CLIFF"],  # Magnus sees sheep
    "56b": ["BADSTOFA-CLIFF"],  # Headdress sheep
    "56c": ["BADSTOFA-CLIFF"],  # Mamma - human teeth
    "57": ["BADSTOFA-CLIFF"],  # Complete darkness
    "57a": ["BADSTOFA-CLIFF"],  # Only breathing
    "57b": ["BADSTOFA-CLIFF"],  # Flicker of light
    "57c": ["BADSTOFA-CLIFF"],  # House speaks in darkness
    "58a": ["BADSTOFA-CLIFF", "WESTFJORDS-CLIFF"],  # Light returns
    "58b": ["BADSTOFA-CLIFF"],  # Gudrun-ewe realization
    "58c": ["BADSTOFA-MONUMENT", "WESTFJORDS-CLIFF"],  # Obelisk rises
    "59a": ["BADSTOFA-MONUMENT", "WESTFJORDS-CLIFF"],  # House becomes obelisk
    "59b": ["BADSTOFA-MONUMENT", "WESTFJORDS-CLIFF"],  # Sigrid enters cleft
    "59c": ["BADSTOFA-MONUMENT", "WESTFJORDS-CLIFF"],  # Sigrid transformation
    "60a": ["WESTFJORDS-AERIAL", "LANDSCAPE-FROZEN"],  # Flight with gammur
    "60b": ["WESTFJORDS-AERIAL", "LANDSCAPE-FROZEN"],  # Egg laid
    "60c": ["BADSTOFA-MONUMENT", "WESTFJORDS-AERIAL"],  # Return to obelisk
    "61": ["BADSTOFA-MONUMENT", "SEA-ETERNAL"],  # Camera recognizes
    "61a": ["BADSTOFA-MONUMENT", "SEA-ETERNAL"],  # We are Iceland
    "61b": ["BADSTOFA-MONUMENT", "SEA-ETERNAL"],  # Witness testimony
    "61c": ["BADSTOFA-MONUMENT", "SEA-ETERNAL"],  # Witness fragments
    "62a": ["LANDSCAPE-FROZEN", "WESTFJORDS-WINTER"],  # Accelerating frost
    "62b": ["BADSTOFA-MONUMENT", "LANDSCAPE-FROZEN"],  # Final clear moment
    "63": ["BADSTOFA-MONUMENT", "SEA-ETERNAL", "LANDSCAPE-FROZEN"],  # White death - final
}

def extract_shot_id(filename: str) -> str:
    """Extract shot ID from filename"""
    match = re.search(r'shot_([^_]+)(?:_(?:prologue|main))?', filename)
    if match:
        return match.group(1)
    return ""

def normalize_shot_id(shot_id: str) -> str:
    """Normalize shot ID for matching"""
    # Handle special cases like "5p" (shot 5.5), "16p" (shot 16.5)
    return shot_id.lower()

def determine_sequence_type(filename: str, data: dict) -> str:
    """Determine if shot is prologue or main"""
    if "prologue" in filename.lower():
        return "prologue"
    elif "main" in filename.lower():
        return "main"

    # Check metadata
    if data.get("metadata", {}).get("sequence_type"):
        return data["metadata"]["sequence_type"]

    # Default to main
    return "main"

def extract_characters_from_prompt(prompt_text: str) -> Set[str]:
    """Extract character names mentioned in prompt text"""
    characters = set()
    text_lower = prompt_text.lower()

    # Character name patterns
    character_patterns = {
        "magnus": ["magnus", "magnús", "father", "patriarch", "pabbi"],
        "sigrid": ["sigrid", "daughter", "witness"],
        "gudrun": ["gudrun", "guðrún", "mother", "wife", "mamma"],
        "jon": ["jon", "jón", "son", "boy", "prophet"],
        "lilja": ["lilja", "youngest", "girl", "child", "lamb"]
    }

    for character, patterns in character_patterns.items():
        for pattern in patterns:
            if pattern in text_lower:
                characters.add(character)
                break

    return characters

def update_shot_file(filepath: str) -> bool:
    """Update a single shot file with comprehensive plate mappings"""
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    filename = os.path.basename(filepath)
    shot_id = extract_shot_id(filename)
    normalized_id = normalize_shot_id(shot_id)
    sequence_type = determine_sequence_type(filename, data)

    print(f"\nProcessing: {filename}")
    print(f"  Shot ID: {shot_id}, Sequence: {sequence_type}")

    changes_made = False

    # Process each prompt variant individually
    for i, variant in enumerate(data.get("prompt_variants", [])):
        print(f"    Variant {i+1}/{len(data.get('prompt_variants', []))}: {variant.get('variant_name', 'Unnamed')[:50]}...")

        # Get all prompt text for this specific variant
        prompt_text = ""
        for field in ["subject", "action", "scene", "dialogue", "style"]:
            if field in variant and variant[field]:
                prompt_text += " " + str(variant[field])

        # Extract characters mentioned in this variant's prompt
        mentioned_characters = extract_characters_from_prompt(prompt_text)

        # Get mapped characters from the integration guide
        mapped_characters = CHARACTER_PLATE_MAPPINGS.get(normalized_id, {})

        # Combine mentioned and mapped characters for this variant
        all_characters = set(mapped_characters.keys()) | mentioned_characters

        # Build character plates for this variant
        character_plates = {}
        for character in all_characters:
            if character in mapped_characters:
                plate_id = mapped_characters[character]
                character_plates[character] = plate_id
                print(f"      Character: {character} -> {plate_id}")
            elif character in mentioned_characters:
                # Use master plate as fallback for characters mentioned in prompt
                master_plate = f"{character.upper()}-MASTER"
                character_plates[character] = master_plate
                print(f"      Character: {character} -> {master_plate} (from prompt)")

        # Get environmental plates (same for all variants of a shot)
        env_plates = ENVIRONMENTAL_PLATE_MAPPINGS.get(normalized_id, [])
        if not env_plates:
            # Default environmental plates based on sequence
            if sequence_type == "prologue":
                env_plates = ["BADSTOFA-DOMESTIC", "WESTFJORDS-SUMMER", "SEA-DIVINE"]
            else:
                env_plates = ["BADSTOFA-BODY", "WESTFJORDS-WINTER", "SEA-EXTRACTED"]

        print(f"      Environment: {', '.join(env_plates)}")

        # Create the flat array format the app expects
        all_plates = []

        # Add character plates
        for char, plate in character_plates.items():
            all_plates.append(plate)

        # Add environmental plates
        all_plates.extend(env_plates)

        # Update variant with flat array format
        variant["selected_plates"] = all_plates

        # Also add for UI support (keeping the structured format for future use)
        variant["available_character_plates"] = character_plates
        variant["available_environmental_plates"] = env_plates

        changes_made = True

    # Save updated file
    if changes_made:
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        print(f"  ✅ Updated successfully")

    return changes_made

def main():
    """Update all shot files with comprehensive plate mappings"""
    shot_dir = "/Users/ingthor/Documents/stories/appdata/json/7/shots/json"

    print("=" * 60)
    print("COMPREHENSIVE SHOT PLATE MAPPING UPDATE")
    print("=" * 60)

    # Get all shot files
    shot_files = glob.glob(os.path.join(shot_dir, "shot_*.json"))
    print(f"Found {len(shot_files)} shot files to process")

    updated_count = 0
    for filepath in sorted(shot_files):
        if update_shot_file(filepath):
            updated_count += 1

    print("\n" + "=" * 60)
    print(f"COMPLETE: Updated {updated_count} shot files")
    print("All shots now have comprehensive character and environmental plate mappings")
    print("=" * 60)

if __name__ == "__main__":
    main()