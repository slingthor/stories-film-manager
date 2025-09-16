#!/usr/bin/env python3
"""
Final environmental plate mapping using full variety from enhancement files
"""
import json
import os
import glob
import re

# Character progression mappings with correct timing from integration guide
CHARACTER_PLATE_MAPPINGS = {
    # PROLOGUE - Pure/abundant states (shots 0-23)
    "0a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE"},
    "0b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE"},
    "1-": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE"},
    "1a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT"},
    "1b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "1c": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE"},
    "2a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "2b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "3a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "jon": "JON-MILD"},
    "3b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "4a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "4b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "5a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "5b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "5p": {"magnus": "MAGNUS-WATCHING", "sigrid": "SIGRID-AWAKENING", "lilja": "LILJA-SENSING", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-RISING"},
    "6a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-AWAKENING", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "6b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "7a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "7b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "8a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "8b": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "8c": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "9a": {"magnus": "MAGNUS-AUTHORITY", "sigrid": "SIGRID-PURE", "lilja": "LILJA-PURE", "gudrun": "GUDRUN-ABUNDANT", "jon": "JON-MILD"},
    "9b": {"magnus": "MAGNUS-TRANSITION", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-HARMONIC", "gudrun": "GUDRUN-WEARING", "jon": "JON-SEEING"},
    "20": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "21": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "22": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},

    # MAIN STORY EARLY - Winter survival breakdown (shots 1-15)
    "1": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "2": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "3": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "4": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "5": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "6": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-MARKED", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "7": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "8": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "9": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "10": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "11": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "12": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "13": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "14": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "15": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "16": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "16p": {"sigrid": "SIGRID-PROPHECY"},  # One perfect human moment
    "17": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},
    "18": {"magnus": "MAGNUS-PROVIDER", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "19": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-COUNTING", "jon": "JON-PROPHET"},

    # MID STORY - Sea journeys and provider failure (shots 20-40)
    "22b": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "23": {"magnus": "MAGNUS-RITUAL", "sigrid": "SIGRID-SUMMONING", "lilja": "LILJA-HARMONIC", "gudrun": "GUDRUN-RITUAL", "jon": "JON-TEMPORAL"},
    "23a": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "23b": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "23c": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "23p": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "24": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-SUMMONING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "24a": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-SUMMONING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "24b": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "24c": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "24d": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "25": {"magnus": "MAGNUS-CONFUSED", "sigrid": "SIGRID-CALCULATING", "lilja": "LILJA-MATHEMATICAL", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-PROPHET"},
    "26": {"magnus": "MAGNUS-AFLOAT", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-COMMUNICATING", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING"},
    "27": {"magnus": "MAGNUS-AFLOAT", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-COMMUNICATING", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING"},
    "28": {"magnus": "MAGNUS-AFLOAT", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-COMMUNICATING", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING"},
    "29": {"magnus": "MAGNUS-AFLOAT", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-COMMUNICATING", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING"},
    "30": {"magnus": "MAGNUS-AGING", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-COMMUNICATING", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING"},
    "31": {"magnus": "MAGNUS-AGING", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-COMMUNICATING", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING"},
    "32": {"magnus": "MAGNUS-AGING", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-COMMUNICATING", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING"},
    "33": {"magnus": "MAGNUS-AGING", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-COMMUNICATING", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING"},
    "34": {"magnus": "MAGNUS-AGING", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-COMMUNICATING", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING"},
    "35a": {"magnus": "MAGNUS-WOUNDED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-COMMUNICATING", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING"},
    "35b": {"magnus": "MAGNUS-WOUNDED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-COMMUNICATING", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING"},
    "35c": {"magnus": "MAGNUS-WOUNDED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-COMMUNICATING", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING"},
    "36": {"magnus": "MAGNUS-WOUNDED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-COMMUNICATING", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING"},
    "37": {"magnus": "MAGNUS-WOUNDED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-COMMUNICATING", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING"},
    "38a": {"magnus": "MAGNUS-WOUNDED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-COMMUNICATING", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING"},
    "38b": {"magnus": "MAGNUS-WOUNDED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-COMMUNICATING", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING"},
    "39": {"magnus": "MAGNUS-WOUNDED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-COMMUNICATING", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-CHANGING"},
    "39p": {"lilja": "LILJA-ACCEPTING", "jon": "JON-GAPPED"},  # Children's hunger special scene
    "40": {"magnus": "MAGNUS-WOUNDED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-PRODUCING", "jon": "JON-ENERGETIC"},

    # VIOLENCE AND ESCALATION (shots 41-55) - Correct timing for ACCEPTING
    "41": {"magnus": "MAGNUS-PREDATOR", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-ACCEPTING", "gudrun": "GUDRUN-BEATEN", "jon": "JON-TEMPORAL"},
    "42a": {"magnus": "MAGNUS-PREDATOR", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-ACCEPTING", "gudrun": "GUDRUN-BEATEN", "jon": "JON-TEMPORAL"},
    "42b": {"magnus": "MAGNUS-PREDATOR", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-ACCEPTING", "gudrun": "GUDRUN-BEATEN", "jon": "JON-TEMPORAL"},
    "42c": {"magnus": "MAGNUS-PREDATOR", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-ACCEPTING", "gudrun": "GUDRUN-BEATEN", "jon": "JON-TEMPORAL"},
    "43a": {"magnus": "MAGNUS-PREDATOR", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-ACCEPTING", "gudrun": "GUDRUN-BEATEN", "jon": "JON-TEMPORAL"},
    "43b": {"magnus": "MAGNUS-ENFORCER", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-ACCEPTING", "gudrun": "GUDRUN-BEATEN", "jon": "JON-TEMPORAL"},
    "43c": {"magnus": "MAGNUS-ENFORCER", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-ACCEPTING", "gudrun": "GUDRUN-BEATEN", "jon": "JON-TEMPORAL"},
    "44a": {"magnus": "MAGNUS-DEFEATED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-WALKING", "jon": "JON-ENERGETIC"},
    "44b": {"magnus": "MAGNUS-DEFEATED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-WALKING", "jon": "JON-ENERGETIC"},
    "44c": {"magnus": "MAGNUS-DEFEATED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-WALKING", "jon": "JON-ENERGETIC"},
    "45a": {"magnus": "MAGNUS-DEFEATED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-CROWNED", "jon": "JON-ENERGETIC"},
    "45b": {"magnus": "MAGNUS-DEFEATED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-CROWNED", "jon": "JON-ENERGETIC"},
    "45c": {"magnus": "MAGNUS-DEFEATED", "sigrid": "SIGRID-MASTER", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-DIVINE", "jon": "JON-ENERGETIC"},
    "46a": {"magnus": "MAGNUS-DEFEATED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-DIVINE", "jon": "JON-ENERGETIC"},
    "46b": {"magnus": "MAGNUS-DEFEATED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-DIVINE", "jon": "JON-ENERGETIC"},
    "46c": {"magnus": "MAGNUS-DEFEATED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-DIVINE", "jon": "JON-ENERGETIC"},
    "47a": {"magnus": "MAGNUS-DEFEATED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "47b": {"magnus": "MAGNUS-DEFEATED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "47c": {"magnus": "MAGNUS-DEFEATED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "48": {"magnus": "MAGNUS-DEFEATED", "sigrid": "SIGRID-ORACLE", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "49a": {"magnus": "MAGNUS-POSSESSOR", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "49b": {"magnus": "MAGNUS-POSSESSOR", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "49c": {"magnus": "MAGNUS-POSSESSOR", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "50a": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "50b": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "50c": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "50d": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "51a": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "51b": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "51c": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "52a": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "52b": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "52c": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "53a": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "53b": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "53c": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "54a": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "54b": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "54c": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "55a": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "55b": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "55c": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},
    "55p": {"magnus": "MAGNUS-POSSESSING", "sigrid": "SIGRID-CORNERED", "lilja": "LILJA-EVOLVING", "gudrun": "GUDRUN-RETURNING", "jon": "JON-ENERGETIC"},

    # TRANSFORMATION SEQUENCE (shots 56-75) - Active transformation
    "56": {"magnus": "MAGNUS-SHIFTING", "sigrid": "SIGRID-TRANSITIONAL", "lilja": "LILJA-FINAL", "gudrun": "GUDRUN-SPEAKING", "jon": "JON-CHANGING"},
    "56a": {"magnus": "MAGNUS-RECOGNIZING", "sigrid": "SIGRID-TRANSITIONAL", "lilja": "LILJA-FINAL", "gudrun": "GUDRUN-SPEAKING", "jon": "JON-CHANGING"},
    "56b": {"magnus": "MAGNUS-RECOGNIZING", "sigrid": "SIGRID-TRANSITIONAL", "lilja": "LILJA-FINAL", "gudrun": "GUDRUN-SPEAKING", "jon": "JON-CHANGING"},
    "56c": {"magnus": "MAGNUS-RECOGNIZING", "sigrid": "SIGRID-TRANSITIONAL", "lilja": "LILJA-FINAL", "gudrun": "GUDRUN-SPEAKING", "jon": "JON-CHANGING"},
    "57": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-BECOMING", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-EWE", "jon": "JON-LAMB"},
    "57a": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-BECOMING", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-EWE", "jon": "JON-LAMB"},
    "57b": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-BECOMING", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-EWE", "jon": "JON-LAMB"},
    "57c": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-BECOMING", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-EWE", "jon": "JON-LAMB"},
    "58a": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-DUAL", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-EWE", "jon": "JON-LAMB"},
    "58b": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-DUAL", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-EWE", "jon": "JON-LAMB"},
    "58c": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-DUAL", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-EWE", "jon": "JON-LAMB"},
    "59a": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-DUAL", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-EWE", "jon": "JON-LAMB"},
    "59b": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-DUAL", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-EWE", "jon": "JON-LAMB"},
    "59c": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-DUAL", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-EWE", "jon": "JON-LAMB"},
    "60a": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-DUAL", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-EWE", "jon": "JON-LAMB"},
    "60b": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-DUAL", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-EWE", "jon": "JON-LAMB"},
    "60c": {"magnus": "MAGNUS-BREAKING", "sigrid": "SIGRID-DUAL", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-EWE", "jon": "JON-LAMB"},

    # MONUMENT AND TRANSCENDENCE (shots 61-85) - Complete transformation
    "61": {"magnus": "MAGNUS-RAM", "sigrid": "SIGRID-CORVID", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-ETERNAL", "jon": "JON-LAMB"},
    "61a": {"magnus": "MAGNUS-RAM", "sigrid": "SIGRID-CORVID", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-ETERNAL", "jon": "JON-LAMB"},
    "61b": {"magnus": "MAGNUS-RAM", "sigrid": "SIGRID-CORVID", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-ETERNAL", "jon": "JON-LAMB"},
    "61c": {"magnus": "MAGNUS-RAM", "sigrid": "SIGRID-CORVID", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-ETERNAL", "jon": "JON-LAMB"},
    "62a": {"magnus": "MAGNUS-RAM", "sigrid": "SIGRID-CORVID", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-ETERNAL", "jon": "JON-LAMB"},
    "62b": {"magnus": "MAGNUS-RAM", "sigrid": "SIGRID-CORVID", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-ETERNAL", "jon": "JON-LAMB"},
    "63": {"magnus": "MAGNUS-RAM", "sigrid": "SIGRID-CORVID", "lilja": "LILJA-LAMB", "gudrun": "GUDRUN-ETERNAL", "jon": "JON-LAMB"},
}

# Complete environmental plates following enhancement files exactly
ENVIRONMENTAL_PLATE_MAPPINGS = {
    # PROLOGUE - Pure/traditional environment (shots 0-23)
    "0a": ["SEA-DIVINE", "WESTFJORDS-FJORD"],
    "0b": ["SEA-DIVINE", "WESTFJORDS-FJORD"],
    "1-": ["SEA-DIVINE", "WESTFJORDS-FJORD"],
    "1a": ["SEA-DIVINE", "WESTFJORDS-BEACH"],
    "1b": ["SEA-DIVINE", "WESTFJORDS-BEACH"],  # Whale hunt - divine cooperation
    "1c": ["SEA-ABUNDANT", "WESTFJORDS-BEACH"],
    "2a": ["SEA-ABUNDANT", "WESTFJORDS-BEACH"],  # Shore division - abundance reflection
    "2b": ["SEA-DIVINE", "WESTFJORDS-CLIFF"],
    "3a": ["BAÐSTOFA-DOMESTIC", "WESTFJORDS-BEACH"],
    "3b": ["SEA-DIVINE", "WESTFJORDS-CLIFF"],
    "4a": ["WESTFJORDS-CLIFF", "WESTFJORDS-SUMMER"],
    "4b": ["BAÐSTOFA-DOMESTIC", "WESTFJORDS-BEACH"],
    "5a": ["SEA-DIVINE", "WESTFJORDS-BEACH"],
    "5b": ["SEA-DIVINE", "WESTFJORDS-BEACH"],
    "5p": ["STOFA-SURVEILLANCE", "WESTFJORDS-BEACH"],  # Special surveillance web scene
    "6a": ["BAÐSTOFA-DOMESTIC", "WESTFJORDS-BEACH"],
    "6b": ["WESTFJORDS-CLIFF", "WESTFJORDS-SUMMER"],
    "7a": ["BAÐSTOFA-DOMESTIC", "WESTFJORDS-BEACH"],
    "7b": ["BAÐSTOFA-DOMESTIC"],
    "8a": ["BAÐSTOFA-DOMESTIC"],
    "8b": ["BAÐSTOFA-DOMESTIC"],
    "8c": ["BAÐSTOFA-DOMESTIC"],
    "9a": ["BAÐSTOFA-DOMESTIC"],
    "20": ["WESTFJORDS-WINTER", "HOUSE-TRADITIONAL"],  # Sigrid's winter song
    "21": ["WESTFJORDS-WINTER", "HOUSE-TRADITIONAL"],
    "22": ["WESTFJORDS-WINTER", "HOUSE-TRADITIONAL"],

    # MAIN STORY EARLY - House consciousness awakening (shots 1-15)
    "1": ["BAÐSTOFA-STIRRING", "WESTFJORDS-WINTER"],  # Cosmic abandonment - consciousness stirring
    "2": ["BAÐSTOFA-STIRRING", "WESTFJORDS-WINTER"],  # Forystufé prophecy
    "3": ["BAÐSTOFA-STIRRING"],  # Breathing house - consciousness obvious
    "4": ["BAÐSTOFA-STIRRING", "WESTFJORDS-WINTER"],
    "5": ["BAÐSTOFA-STIRRING", "WESTFJORDS-WINTER"],
    "6": ["BAÐSTOFA-STIRRING"],  # Rising authority
    "7": ["BAÐSTOFA-STIRRING", "WESTFJORDS-WINTER"],
    "8": ["BAÐSTOFA-STIRRING"],  # Counting begins
    "9": ["BAÐSTOFA-STIRRING"],  # Tre fire fem
    "10": ["BAÐSTOFA-ORGANIC"],  # Seks - impossible count, organic recognition
    "11": ["BAÐSTOFA-ORGANIC"],  # Empty bounty
    "12": ["BAÐSTOFA-ORGANIC"],  # Krummi lullaby
    "13": ["BAÐSTOFA-ORGANIC", "WESTFJORDS-WINTER"],  # Raven at window
    "14": ["BAÐSTOFA-ORGANIC"],  # Hidden feast
    "15": ["BAÐSTOFA-ORGANIC"],  # Mathematical breaking

    # MAIN STORY MID - Body interior revelation (shots 16-25)
    "16": ["BAÐSTOFA-BODY"],  # Last light - full body interior
    "16p": ["STOFA-PEACEFUL"],  # One perfect human moment - special peaceful scene
    "17": ["BAÐSTOFA-BODY"],  # Departure preparations
    "18": ["BAÐSTOFA-BODY", "WESTFJORDS-WINTER"],
    "19": ["BAÐSTOFA-BODY"],  # Whale oil dies
    "22b": ["BAÐSTOFA-BODY"],  # Second pull
    "23": ["BAÐSTOFA-BODY", "WESTFJORDS-WINTER"],  # Sigrid's preparation
    "23a": ["BAÐSTOFA-BODY"],  # Sigrid breaks silence
    "23b": ["BAÐSTOFA-BODY"],  # Rope fights back
    "23c": ["BAÐSTOFA-BODY", "WESTFJORDS-WINTER"],  # Blood circles
    "23p": ["SEA-EXTRACTED", "WESTFJORDS-FJORD"],  # Last ship

    # MAIN STORY LATE - Sea journeys and cliff formation (shots 24-45)
    "24": ["BAÐSTOFA-BODY", "WESTFJORDS-WINTER"],  # Giant's voice
    "24a": ["BAÐSTOFA-BODY"],  # Giant speaks through her
    "24b": ["WESTFJORDS-WINTER", "SEA-BATTLE"],  # Eastern response - supernatural battleground
    "24c": ["WESTFJORDS-WINTER", "SEA-BATTLE"],  # Western response
    "24d": ["WESTFJORDS-WINTER"],  # Southern/Northern
    "25": ["BAÐSTOFA-BODY"],  # Wrong thing born
    "26": ["SEA-EXTRACTED", "WESTFJORDS-FJORD"],  # Island trembles - extraction victim
    "27": ["SEA-EXTRACTED", "WESTFJORDS-FJORD"],  # Stubborn continuation
    "28": ["SEA-EXTRACTED", "WESTFJORDS-FJORD"],  # Frozen edge
    "29": ["SEA-EXTRACTED", "WESTFJORDS-FJORD"],  # Launching into nothing
    "30": ["SEA-EXTRACTED", "WESTFJORDS-FJORD"],  # Hours of nothing
    "31": ["SEA-EXTRACTED", "BAÐSTOFA-CLEFT"],  # Children see true shapes - cliff formation begins
    "32": ["SEA-BATTLE", "WESTFJORDS-FJORD"],  # Underwater truth
    "33": ["SEA-BATTLE", "WESTFJORDS-FJORD"],  # Realization
    "34": ["SEA-BATTLE", "WESTFJORDS-FJORD"],  # Deliberate cut
    "35a": ["SEA-BATTLE", "WESTFJORDS-FJORD"],  # Rifle emerges
    "35b": ["SEA-BATTLE", "WESTFJORDS-FJORD"],  # First shot
    "35c": ["SEA-BATTLE", "WESTFJORDS-FJORD"],  # Jörmungandr withdraws
    "36": ["SEA-BATTLE", "WESTFJORDS-FJORD"],  # Empty victory
    "37": ["SEA-BATTLE", "WESTFJORDS-FJORD"],  # Shoreline scavenging
    "38a": ["BAÐSTOFA-CLEFT"],  # Fin examined
    "38b": ["SEA-SEDUCTIVE", "WESTFJORDS-FJORD"],  # Decision to return - pathological attraction
    "39": ["BAÐSTOFA-CLEFT", "WESTFJORDS-WINTER"],  # House transformed
    "39p": ["STOFA-DESPERATE"],  # Children's hunger - special desperate scene
    "40": ["BAÐSTOFA-CLEFT", "WESTFJORDS-CLIFF"],  # Guðrún's silent testimony
    "41": ["BAÐSTOFA-CLEFT", "WESTFJORDS-CLIFF"],  # Children's acceptance
    "42a": ["BAÐSTOFA-CLEFT"],  # Door violence
    "42b": ["BAÐSTOFA-CLEFT"],  # Pathetic offering
    "42c": ["BAÐSTOFA-CLEFT"],  # Recognizing transformation
    "43a": ["BAÐSTOFA-CLEFT"],  # Cane rises
    "43b": ["STOFA-RECORDING"],  # Shadow violence - special recording scene
    "43c": ["BAÐSTOFA-CLEFT"],  # Command
    "44a": ["WESTFJORDS-CLIFF"],  # Lamp death
    "44b": ["WESTFJORDS-CLIFF"],  # Following blood trail
    "44c": ["WESTFJORDS-CLIFF"],  # Wool becomes visible
    "45a": ["SEA-BATTLE"],  # Polynya arrival
    "45b": ["SEA-BATTLE"],  # Water changes
    "45c": ["SEA-CONTAMINATED", "WESTFJORDS-FJORD"],  # Griðungur emerges - contaminated divine

    # CLIMAX - Contamination and crystallization (shots 46-60)
    "46a": ["SEA-CONTAMINATED", "WESTFJORDS-FJORD"],  # Mutual recognition
    "46b": ["SEA-CONTAMINATED", "WESTFJORDS-FJORD"],  # The offering
    "46c": ["SEA-CONTAMINATED", "WESTFJORDS-FJORD"],  # The collapse
    "47a": ["SEA-CONTAMINATED"],  # Trawler speaks
    "47b": ["WESTFJORDS-CLIFF"],  # Walking through blood
    "47c": ["BAÐSTOFA-CRYSTALLIZING"],  # House door opens - crystallization begins
    "48": ["BAÐSTOFA-CRYSTALLIZING"],  # Blood dripping entry
    "49a": ["BAÐSTOFA-CRYSTALLIZING", "WESTFJORDS-CLIFF"],  # Magnús redirects rage
    "49b": ["BAÐSTOFA-CRYSTALLIZING"],  # House responds
    "49c": ["BAÐSTOFA-CRYSTALLIZING"],  # Krummi evolution
    "50a": ["BAÐSTOFA-CRYSTALLIZING"],  # Evening falls
    "50b": ["BAÐSTOFA-CRYSTALLIZING"],  # Old story
    "50c": ["BAÐSTOFA-CRYSTALLIZING"],  # Male krummi
    "50d": ["BAÐSTOFA-CRYSTALLIZING", "WESTFJORDS-CLIFF"],  # Lingering kiss
    "51a": ["BAÐSTOFA-CRYSTALLIZING", "WESTFJORDS-CLIFF"],  # Children's shadow prophecy
    "51b": ["BAÐSTOFA-CRYSTALLIZING", "WESTFJORDS-CLIFF"],  # Empty clothes speaking
    "51c": ["BAÐSTOFA-CRYSTALLIZING"],  # Réttir revealed
    "52a": ["BAÐSTOFA-CRYSTALLIZING"],  # Second monolith
    "52b": ["BAÐSTOFA-CRYSTALLIZING"],  # Raven's prophecy
    "52c": ["BAÐSTOFA-CRYSTALLIZING", "WESTFJORDS-CLIFF"],  # Magnús breaks paralysis
    "53a": ["BAÐSTOFA-CRYSTALLIZING"],  # House begins to speak
    "53b": ["BAÐSTOFA-CRYSTALLIZING"],  # Dying confession
    "53c": ["BAÐSTOFA-CRYSTALLIZING"],  # Bergrisi chooses Sigrid
    "54a": ["BAÐSTOFA-CRYSTALLIZING"],  # Morning impossibly arrives
    "54b": ["BAÐSTOFA-CRYSTALLIZING", "WESTFJORDS-CLIFF"],  # Bull at threshold
    "54c": ["BAÐSTOFA-CRYSTALLIZING"],  # Daily routine
    "55a": ["SEA-ACCUSATION", "WESTFJORDS-CLIFF"],  # Trawler begins circle - mathematical accusation
    "55b": ["SEA-ACCUSATION", "WESTFJORDS-CLIFF"],  # Circle tightens
    "55c": ["SEA-ACCUSATION", "WESTFJORDS-CLIFF"],  # The bite - ouroboros trigger
    "55p": ["STOFA-FRAGMENTING"],  # Witness mechanism breaks - special fragmenting scene

    # TRANSFORMATION - Cliff interior and monument (shots 56-75)
    "56": ["BAÐSTOFA-CLIFF"],  # Family transformed
    "56a": ["BAÐSTOFA-CLIFF"],  # Magnús sees sheep
    "56b": ["BAÐSTOFA-CLIFF"],  # Headdress sheep
    "56c": ["BAÐSTOFA-CLIFF", "WESTFJORDS-CLIFF"],  # Mamma - human teeth horror
    "57": ["BAÐSTOFA-CLIFF"],  # Complete darkness
    "57a": ["BAÐSTOFA-CLIFF"],  # Complete darkness
    "57b": ["BAÐSTOFA-CLIFF", "WESTFJORDS-CLIFF"],  # Flicker of light
    "57c": ["BAÐSTOFA-CLIFF"],  # House speaks in darkness
    "58a": ["WESTFJORDS-CLIFF"],  # Light returns
    "58b": ["BAÐSTOFA-CLIFF", "WESTFJORDS-CLIFF"],  # Guðrún-ewes realization
    "58c": ["BAÐSTOFA-CLIFF", "WESTFJORDS-CLIFF"],  # Obelisk rises
    "59a": ["BAÐSTOFA-CLIFF"],  # House becomes obelisk
    "59b": ["BAÐSTOFA-CLIFF"],  # Sigrid enters cleft
    "59c": ["BAÐSTOFA-CLIFF", "WESTFJORDS-CLIFF"],  # Sigrid completes transformation
    "60a": ["BAÐSTOFA-CLIFF", "WESTFJORDS-CLIFF"],  # Flight with Gammur
    "60b": ["BAÐSTOFA-CLIFF", "WESTFJORDS-CLIFF"],  # Egg laid
    "60c": ["BAÐSTOFA-MONUMENT"],  # Return to obelisk - monument completion

    # FINAL MONUMENT - Eternal witness (shots 61-85)
    "61": ["BAÐSTOFA-MONUMENT"],  # Camera recognizes itself - final monument state
    "61a": ["WESTFJORDS-CLIFF"],  # Camera recognizes itself
    "61b": ["WESTFJORDS-CLIFF"],  # We are Iceland watching
    "61c": ["WESTFJORDS-CLIFF"],  # Witness fragments
    "62a": ["SEA-ETERNAL", "WESTFJORDS-CLIFF"],  # Accelerating frost - eternal mirror
    "62b": ["SEA-ETERNAL", "WESTFJORDS-CLIFF"],  # Final clear moment
    "63": ["SEA-ETERNAL", "WESTFJORDS-CLIFF"],  # White death - camera transcends
}

def extract_characters_from_prompt(prompt_text):
    """Extract character names mentioned in brackets from prompt text"""
    if not prompt_text:
        return set()

    characters = set()
    bracket_matches = re.findall(r'\[([A-ZÁÐÞÆÍÓÚÝÖ\s]+)\]', prompt_text.upper())

    for match in bracket_matches:
        cleaned = match.strip()
        if cleaned in ['MAGNÚS', 'MAGNUS']:
            characters.add('magnus')
        elif cleaned == 'SIGRID':
            characters.add('sigrid')
        elif cleaned == 'LILJA':
            characters.add('lilja')
        elif cleaned in ['GUÐRÚN', 'GUDRUN']:
            characters.add('gudrun')
        elif cleaned == 'JÓN' or cleaned == 'JON':
            characters.add('jon')

    return characters

def normalize_shot_id(shot_id):
    """Normalize shot ID for mapping lookup"""
    return shot_id.replace('.', 'p').replace('-', '')

def update_shot_file(filepath):
    """Update a single shot file with comprehensive environmental plates"""
    print(f"\n📁 Processing: {os.path.basename(filepath)}")

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"  ❌ Error reading file: {e}")
        return False

    shot_metadata = data.get('shot_metadata', {})
    shot_id = shot_metadata.get('id', '')
    sequence_type = shot_metadata.get('sequence_type', 'main_story')

    normalized_id = normalize_shot_id(shot_id)
    print(f"  🎬 Shot ID: {shot_id} (normalized: {normalized_id})")
    print(f"  📋 Sequence: {sequence_type}")

    changes_made = False

    # Update each prompt variant
    for i, variant in enumerate(data.get('prompt_variants', [])):
        print(f"    📝 Variant {i+1}: {variant.get('variant_name', 'Unnamed')}")

        # Extract characters mentioned in this variant's prompt
        subject = variant.get('subject', '')
        action = variant.get('action', '')
        scene = variant.get('scene', '')
        prompt_text = f"{subject} {action} {scene}"
        mentioned_characters = extract_characters_from_prompt(prompt_text)

        if mentioned_characters:
            print(f"      👥 Characters in prompt: {', '.join(mentioned_characters)}")

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

        # Get comprehensive environmental plates from enhancement files
        env_plates = ENVIRONMENTAL_PLATE_MAPPINGS.get(normalized_id, [])
        if not env_plates:
            # Default environmental plates based on sequence
            if sequence_type == "prologue":
                env_plates = ["BAÐSTOFA-DOMESTIC", "WESTFJORDS-SUMMER", "SEA-DIVINE"]
            else:
                env_plates = ["BAÐSTOFA-BODY", "WESTFJORDS-WINTER", "SEA-EXTRACTED"]

        print(f"      Environment: {', '.join(env_plates)}")

        # Create the flat array format the app expects
        all_plates = []

        # Add character plates
        for char, plate in character_plates.items():
            all_plates.append(plate)

        # Add environmental plates
        all_plates.extend(env_plates)

        # Update variant with all three required structures
        variant["selected_plates"] = all_plates
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
    """Update all shot files with comprehensive environmental plates from enhancement files"""
    shot_dir = "/Users/ingthor/Documents/stories/appdata/json/7/shots/json"

    print("=" * 60)
    print("FINAL ENVIRONMENTAL PLATE MAPPING")
    print("Using complete variety from enhancement files")
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
    print("Now using full environmental plate variety:")
    print("- House progression: DOMESTIC → STIRRING → ORGANIC → BODY → CLEFT → CRYSTALLIZING → CLIFF → MONUMENT")
    print("- Sea progression: DIVINE → ABUNDANT → EXTRACTED → BATTLE → CONTAMINATED → SEDUCTIVE → ACCUSATION → ETERNAL")
    print("- Special scenes: SURVEILLANCE, PEACEFUL, DESPERATE, RECORDING, FRAGMENTING")
    print("=" * 60)

if __name__ == "__main__":
    main()