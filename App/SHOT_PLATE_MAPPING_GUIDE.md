# SHOT-PLATE MAPPING INTEGRATION GUIDE
## Connecting Independent Plate Files to Correct Shots

### **APPROACH: Keep Plates in Separate Files + Create Mapping System**

**Goal:** Plates remain in their original enhancement files, but app knows which plates to suggest/select for each shot based on narrative progression.

---

## **MAPPING STRATEGY**

### **1. Create Independent Plate Reference Files:**

#### **character_plates_index.json:**
```json
{
  "plate_files": {
    "magnus": "/Users/ingthor/Documents/stories/enhancements/magnus_advanced_character_plates_system.txt",
    "sigrid": "/Users/ingthor/Documents/stories/enhancements/sigrid_advanced_character_plates_system.txt",
    "gudrun": "/Users/ingthor/Documents/stories/enhancements/gudrun_advanced_character_plates_system.txt",
    "jon": "/Users/ingthor/Documents/stories/enhancements/jon_advanced_character_plates_system.txt", 
    "lilja": "/Users/ingthor/Documents/stories/enhancements/lilja_complete_character_plates_expanded.txt"
  },
  "plate_index": {
    "MAGNUS-AUTHORITY": {
      "file": "magnus",
      "section": "PLATE 1",
      "film_percentage_range": [0, 15],
      "narrative_stage": "patriarch_abundance"
    },
    "MAGNUS-CONFUSED": {
      "file": "magnus", 
      "section": "PLATE 4",
      "film_percentage_range": [25, 45],
      "narrative_stage": "mathematical_breakdown"
    }
  }
}
```

#### **environmental_plates_index.json:**
```json
{
  "plate_files": {
    "interior": "/Users/ingthor/Documents/stories/enhancements/baðstofa_environmental_plates_bergrisi_transformation.txt",
    "exterior": "/Users/ingthor/Documents/stories/enhancements/westfjords_exterior_environmental_plates_system.txt",
    "sea": "/Users/ingthor/Documents/stories/enhancements/sea_environmental_plates_character_progression.txt"
  },
  "plate_index": {
    "BAÐSTOFA-DOMESTIC": {
      "file": "interior",
      "section": "ENVIRONMENT 1", 
      "narrative_stage": "domestic_disguise"
    }
  }
}
```

### **2. Create Shot-to-Plate Mapping:**

#### **shot_plate_recommendations.json:**
```json
{
  "shot_mappings": {
    "0a_prologue": {
      "narrative_context": "Curse establishment, false golden memory",
      "film_percentage": 0.5,
      "recommended_plates": {
        "characters": {},
        "environment": {
          "landscape": "WESTFJORDS-SUMMER-FALSE-PERFECTION",
          "weather": "COOPERATIVE-SUPERNATURAL",
          "lighting": "DAWN-GOLDEN"
        }
      }
    },
    
    "8_main": {
      "narrative_context": "Danish counting as administrative violence, mathematical breakdown",
      "film_percentage": 32.0,
      "recommended_plates": {
        "characters": {
          "magnus": "MAGNUS-CONFUSED",
          "sigrid": "SIGRID-CALCULATING", 
          "gudrun": "GUDRUN-COUNTING",
          "jon": "JON-PROPHET",
          "lilja": "LILJA-MATHEMATICAL"
        },
        "environment": {
          "interior": "BAÐSTOFA-ORGANIC",
          "weather": "DANISH-COLD-SPREADING",
          "lighting": "DIM-MORNING-FROST"
        }
      },
      "breathing_coordination": "Family forced synchronization at 11/min (prey rhythm)",
      "acting_theme": "Colonial mathematics breaking family reality"
    },

    "17_main": {
      "narrative_context": "Three-frame flash revealing all realities simultaneously",
      "film_percentage": 42.0,
      "recommended_plates": {
        "characters": {
          "all_family": "ALL-FAMILY-TRIPLE-REALITY"
        },
        "environment": {
          "interior": "BAÐSTOFA-DARKNESS",
          "lighting": "THREE-FRAME-FLASH"
        }
      },
      "breathing_coordination": "Individual → synchronized → animal simultaneously",
      "acting_theme": "All interpretations simultaneously valid"
    },

    "56_main": {
      "narrative_context": "Family transformation complete with human consciousness retained",
      "film_percentage": 85.0,
      "recommended_plates": {
        "characters": {
          "magnus": "MAGNUS-HYBRID", 
          "gudrun": "GUDRUN-SPEAKING",
          "sigrid": "SIGRID-TRANSITIONAL",
          "jon": "JON-CHANGING", 
          "lilja": "LILJA-FINAL"
        },
        "environment": {
          "interior": "BAÐSTOFA-CLIFF",
          "lighting": "TRANSFORMATION-COMPLETE"
        }
      },
      "breathing_coordination": "All at 8/min sheep rhythm with human awareness",
      "acting_theme": "Human consciousness trapped in livestock bodies"
    }
  }
}
```

---

## **IMPLEMENTATION FOR NEXT CLAUDE**

### **Task 1: Parse Enhancement Files Into Index**
Create script to:
1. **Read each plate file** 
2. **Extract plate IDs and descriptions** (look for "PLATE X:" patterns)
3. **Determine film percentage ranges** based on narrative progression
4. **Create index files** mapping plate IDs to file locations and descriptions

### **Task 2: Create Shot Mapping Logic**
Based on **MASTER_CHARACTER_INTEGRATION_SHOT_BY_SHOT_MAPPING.txt**:
1. **Map each shot** to appropriate character plates
2. **Consider film progression** (early shots = early plates, transformation shots = transformation plates)
3. **Account for character arcs** (Magnus: Authority → Confused → Predator → Ram)

### **Task 3: Update Shot JSON Files** 
For each of the 165 shot files:
1. **Add recommended_plates section** with appropriate plate IDs for that shot
2. **Include plate descriptions** or references to load them
3. **Preserve all existing content**

### **Task 4: App Integration**
The existing app just needs:
1. **PlateManager to load index files**
2. **Dropdown population** from available plates
3. **Plate description display** when selected
4. **Include plate text** in Generate Prompt output

---

## **SPECIFIC SHOT-TO-PLATE MAPPINGS**

### **Prologue Shots (False Abundance):**
- **Magnus:** MAGNÚS-AUTHORITY (clean, confident, leadership)
- **Sigrid:** SIGRID-PURE (innocent, untouched, 8ft distance)
- **Guðrún:** GUÐRÚN-ABUNDANT (competent mother, pristine headdress)
- **Environment:** WESTFJORDS-SUMMER, BAÐSTOFA-DOMESTIC

### **Early Winter Shots (Mathematical Breakdown):**
- **Magnus:** MAGNÚS-CONFUSED (authority cracking, counting failure)
- **Sigrid:** SIGRID-MARKED (post-violation, defensive 11ft distance)
- **Guðrún:** GUÐRÚN-PRODUCING (wool emerging, concealing transformation)
- **Environment:** BAÐSTOFA-ORGANIC, WESTFJORDS-WINTER

### **Mid-Winter Shots (Violence and Crisis):**
- **Magnus:** MAGNÚS-PREDATOR (0Hz violence-ready, territorial)
- **Sigrid:** SIGRID-CORNERED (maximum threat, klettagjá forming)
- **Guðrún:** GUÐRÚN-SACRIFICING (death journey, ice crown)
- **Environment:** BAÐSTOFA-CLIFF, WESTFJORDS-HOSTILE

### **Transformation Shots (Species Change):**
- **Magnus:** MAGNÚS-HYBRID → MAGNÚS-RAM
- **Sigrid:** SIGRID-DUAL → SIGRID-CORVID  
- **Guðrún:** GUÐRÚN-ETERNAL (truth-speaking ewe)
- **Environment:** BAÐSTOFA-MONUMENT, WESTFJORDS-TRANSCENDENT

---

## **SUCCESS CRITERIA**

### **✅ Integration Complete When:**
1. **Shot JSON files reference appropriate plates** for their narrative moment
2. **App dropdowns show relevant options** (not all 97 character plates for every shot)
3. **Plate descriptions load** from original enhancement files
4. **Generate Prompt includes** selected plate text
5. **Smart defaults work** (Shot 8 automatically suggests MAGNUS-CONFUSED)

### **Simple Test:**
1. **Open Shot 8** → Should suggest Magnus: Mathematical Breakdown, Sigrid: Analytical Assessment
2. **Open Shot 56** → Should suggest transformation plates for all characters
3. **Generate prompt** → Should include selected plate descriptions
4. **Change shot** → Should show different appropriate plates

**This is a straightforward mapping task - connect the right plates to the right shots based on narrative progression!** 📝