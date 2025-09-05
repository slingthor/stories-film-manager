# PLATE JSON INTEGRATION - FOCUSED GUIDE
## Adding Plate Data to Existing Shot JSON Files

### **SIMPLE TASK: Integrate Plate Data Into Shot JSONs**

The Film Manager app UI is **complete and working**. The only missing piece is **plate data in the shot JSON files** so the dropdowns can be populated with actual plate descriptions.

---

## **CURRENT SHOT JSON STRUCTURE**

### **Example Current Shot File:** `shot_8_main_THE_COUNTING_BEGINS_-_EN_TO.json`
```json
{
  "shot_metadata": {
    "id": "8",
    "name": "THE_COUNTING_BEGINS",
    "title": "Danish Counting Violence - EN TO"
  },
  "prompt_variants": [
    {
      "variant_id": "8_story_primary",
      "subject": "[MAGNÚS] beginning the Danish counting...",
      "action": "Magnús shifts to Danish, voice becoming mechanical...",
      "character_plates": {
        "present": ["MAGNÚS", "GUÐRÚN", "SIGRID", "JÓN", "LILJA"],
        "referenced": []
      },
      "environmental_plates": {
        "landscape": "BAÐSTOFA-ORGANIC",
        "weather": "DANISH-COLD-SPREADING"
      }
    }
  ]
}
```

### **REQUIRED: Add Actual Plate Descriptions**
The `character_plates` and `environmental_plates` sections need **actual plate text** instead of just IDs.

---

## **PLATE DATA SOURCES**

### **Character Plate Files to Parse:**
1. `/Users/ingthor/Documents/stories/enhancements/magnus_advanced_character_plates_system.txt`
2. `/Users/ingthor/Documents/stories/enhancements/sigrid_advanced_character_plates_system.txt`
3. `/Users/ingthor/Documents/stories/enhancements/gudrun_advanced_character_plates_system.txt`
4. `/Users/ingthor/Documents/stories/enhancements/jon_advanced_character_plates_system.txt`
5. `/Users/ingthor/Documents/stories/enhancements/lilja_complete_character_plates_expanded.txt`

### **Environmental Plate Files to Parse:**
1. `/Users/ingthor/Documents/stories/enhancements/baðstofa_environmental_plates_bergrisi_transformation.txt`
2. `/Users/ingthor/Documents/stories/enhancements/westfjords_exterior_environmental_plates_system.txt`
3. `/Users/ingthor/Documents/stories/enhancements/sea_environmental_plates_character_progression.txt`

### **Shot Mapping Reference:**
`/Users/ingthor/Documents/stories/enhancements/MASTER_CHARACTER_INTEGRATION_SHOT_BY_SHOT_MAPPING.txt`

---

## **REQUIRED JSON STRUCTURE ENHANCEMENT**

### **Enhanced Shot JSON with Plate Data:**
```json
{
  "shot_metadata": {
    "id": "8",
    "name": "THE_COUNTING_BEGINS",
    "title": "Danish Counting Violence - EN TO"
  },
  "prompt_variants": [
    {
      "variant_id": "8_story_primary",
      "subject": "[MAGNÚS] beginning the Danish counting...",
      "action": "Magnús shifts to Danish, voice becoming mechanical...",
      
      "character_plates": {
        "available_plates": {
          "magnus": [
            {
              "id": "MAGNUS-CONFUSED",
              "name": "Mathematical Breakdown",
              "description": "Magnús Þorláksson, 55-year-old fisherman with weathered rectangular face showing authority cracking, steel-blue eyes unfocused with thousand-yard mathematical stare, gripping driftwood cane white-knuckle tight, hunched posture with defensive shoulder positioning..."
            },
            {
              "id": "MAGNUS-PREDATOR", 
              "name": "Violence Ready",
              "description": "Magnús with 0Hz hands (perfect stillness frequency) creating visible -25°C local temperature drop..."
            }
          ],
          "sigrid": [
            {
              "id": "SIGRID-CALCULATING",
              "name": "Analytical Assessment", 
              "description": "Sigrid with heart-shaped face sharp with analytical intelligence, grey eyes with amber flecks bright from mathematical awareness, positioned exactly 11 feet maintaining defensive spacing..."
            }
          ]
        },
        "selected_plates": {
          "magnus": "MAGNUS-CONFUSED",
          "sigrid": "SIGRID-CALCULATING"
        }
      },
      
      "environmental_plates": {
        "available_plates": {
          "interior": [
            {
              "id": "BAÐSTOFA-ORGANIC",
              "name": "House Breathing Revealed",
              "description": "Baðstofa with driftwood beams flexing clearly like ribs during house breathing, turf walls showing blood vessel patterns..."
            }
          ],
          "weather": [
            {
              "id": "DANISH-COLD-SPREADING", 
              "name": "Administrative Temperature",
              "description": "Danish language creating environmental coldness, administrative vocabulary affecting physical temperature..."
            }
          ]
        },
        "selected_plates": {
          "interior": "BAÐSTOFA-ORGANIC",
          "weather": "DANISH-COLD-SPREADING"
        }
      }
    }
  ]
}
```

---

## **IMPLEMENTATION STEPS**

### **Step 1: Extract Plate Data (1-2 hours)**
For each enhancement file:
1. **Find plate definitions** (look for "PLATE X:" or "CHARACTER-ID:" patterns)
2. **Extract descriptions** (full text between plate headers)
3. **Parse metadata** (breathing rates, acting directions, shot ranges)
4. **Organize by character/category**

### **Step 2: Create Plate Mapping Logic (1 hour)**
Using `MASTER_CHARACTER_INTEGRATION_SHOT_BY_SHOT_MAPPING.txt`:
1. **Map shots to appropriate plates** (Shot 8 → MAGNUS-CONFUSED, SIGRID-CALCULATING)
2. **Create default selections** for each shot
3. **Handle film progression** (early shots use early plates, late shots use transformation plates)

### **Step 3: Update All 165 Shot JSON Files (2-3 hours)**
For each shot file in `/Users/ingthor/Documents/stories/App/shots/json/`:
1. **Add available_plates section** with relevant plate options
2. **Add selected_plates section** with smart defaults
3. **Preserve existing content** (don't break current shot data)
4. **Test with app** to verify dropdowns populate

### **Step 4: App UI Integration (1 hour)**
The PlateManager class in the app just needs to:
1. **Read plate data from JSON** (already structured correctly)
2. **Populate dropdowns** with available_plates arrays
3. **Show selected plate descriptions** in UI
4. **Include plate text in generated prompts**

---

## **PLATE EXTRACTION EXAMPLES**

### **From Magnus File - Extract This:**
```
PLATE 1: Summer Authority (Shots 1-9)
MAGNÚS-AUTHORITY: [Master base] with clean brown vaðmál sweater with skilled mending at left elbow using matching thread, dark charcoal wool trousers with fresh patches at knees using slightly lighter brown fabric for contrast, sealskin boots recently oiled showing water repellency...

Acting Direction: Confident patriarch directing community whale hunt, voice carrying authority across water, gestures precise and economical...
```

### **Convert To JSON:**
```json
{
  "id": "MAGNUS-AUTHORITY",
  "name": "Summer Authority",
  "shot_range": "prologue:1-9", 
  "film_percentage": [0, 15],
  "description": "Magnús Þorláksson, 55-year-old Westfjords fisherman with weathered rectangular face, clean brown vaðmál sweater with skilled mending at left elbow using matching thread...",
  "acting_direction": "Confident patriarch directing community whale hunt, voice carrying authority across water, gestures precise and economical",
  "breathing_rate": "10/min",
  "transformation_stage": "patriarch"
}
```

---

## **SIMPLE SUCCESS CRITERIA**

### **✅ Integration Complete When:**
1. **All 165 shot JSON files** have available_plates and selected_plates sections
2. **App dropdowns populate** with actual plate descriptions
3. **Plate text appears** in generated prompts
4. **Shot selection** automatically shows appropriate plate options
5. **No UI changes needed** - existing dropdowns just get real data

### **Testing:**
1. **Load Shot 8** → Character dropdown shows MAGNUS-CONFUSED, SIGRID-CALCULATING options
2. **Select plates** → Descriptions appear in UI
3. **Generate prompt** → Includes plate text in output
4. **Change shots** → Dropdown options update appropriately

**This is a straightforward data integration task - the app framework is ready, it just needs the plate data in the right JSON format!** 📝