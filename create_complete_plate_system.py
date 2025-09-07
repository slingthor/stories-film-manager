#!/usr/bin/env python3
"""
Complete Plate System Creator
Creates the full 157-plate system with proper master identification and shot mapping.
"""

import json
import re
import os
from pathlib import Path

class CompletePlateSystemCreator:
    def __init__(self):
        self.character_plates = {}
        self.environmental_plates = {}
        
        # Master plate identification patterns
        self.master_patterns = [
            "base template", "master", "foundation", "primary",
            "main", "core", "template", "reference"
        ]
    
    def create_complete_system(self):
        """Create the complete 157-plate system."""
        
        # Extract all plates from the comprehensive extraction results we created earlier
        print("🔧 Creating Complete 157-Plate System")
        
        # Character plates - all variations from enhancement files
        self.add_magnus_plates()
        self.add_sigrid_plates() 
        self.add_gudrun_plates()
        self.add_jon_plates()
        self.add_lilja_plates()
        
        # Environmental plates - all categories
        self.add_interior_plates()
        self.add_exterior_plates()
        self.add_sea_plates()
        
        print(f"📊 Complete System Created:")
        print(f"   Character plates: {len(self.character_plates)}")
        print(f"   Environmental plates: {len(self.environmental_plates)}")
        print(f"   Total plates: {len(self.character_plates) + len(self.environmental_plates)}")
        
        # Save the complete system
        self.save_complete_system()
        
        # Create shot mappings
        self.create_shot_mappings()
    
    def add_magnus_plates(self):
        """Add all Magnus character plates."""
        magnus_plates = {
            "MAGNUS-MASTER": {"name": "Magnus Master", "description": "Base template for Magnus variations - 55-year-old Westfjords fisherman, weathered rectangular face, broken aquiline nose, steel-blue hooded eyes, charcoal-grey beard.", "is_master": True},
            "MAGNUS-AUTHORITY": {"name": "Authority", "description": "Magnús Þorláksson as confident patriarch, weathered but authoritative, steel-blue eyes showing leadership, clean brown vaðmál sweater, cane held casually, upright posture.", "is_master": False},
            "MAGNUS-CONFUSED": {"name": "Confused", "description": "Authority cracking during mathematical breakdown, counting failure visible, hunched posture, cane gripped for support, disheveled clothing.", "is_master": False},
            "MAGNUS-PREDATOR": {"name": "Predator", "description": "0Hz violence-ready, territorial positioning, cane as weapon, predatory surveillance focus, authority through intimidation.", "is_master": False},
            "MAGNUS-HYBRID": {"name": "Hybrid", "description": "Ram transformation visible, posture lowering toward quadruped, jaw showing ruminant changes, steel-blue eyes developing horizontal pupils.", "is_master": False},
            "S-SUMMER": {"name": "Summer", "description": "[Master base] wearing clean brown vaðmál sweater with recent mending barely visible, dark wool trousers showing minimal wear, sealskin boots freshly oiled.", "is_master": False},
            "S-AUTUMN": {"name": "Autumn", "description": "[Master base] vaðmál sweater showing increased wear, left elbow mending more prominent, trousers with fresh knee patches.", "is_master": False},
            "S-PREPARATION": {"name": "Preparation", "description": "[Master base] layered for winter - vaðmál sweater under sealskin anorak, wool trousers with additional patches.", "is_master": False},
            "S-DEPARTING": {"name": "Departing", "description": "[Master base] heavy winter fishing gear, sealskin anorak with hood up, thick mittens, ice boots, multiple rope coils across chest.", "is_master": False},
            "S-AFLOAT": {"name": "Afloat", "description": "[Master base] stripped to rowing essentials, vaðmál sweater only, sealskin anorak open, no hat exposing grey hair to elements.", "is_master": False},
            "S-AGING": {"name": "Aging", "description": "[Master base] showing supernatural strength cost - hair completely white, new deep lines carved by salt and failure.", "is_master": False},
            "S-WOUNDED": {"name": "Wounded", "description": "[Previous aging base] plus fresh maritime injuries - rope burns across palms, hook puncture in right palm with dried blood.", "is_master": False},
            "S-DEFEATED": {"name": "Defeated", "description": "[Injured base] with complete failure recognition - shoulders completely collapsed, cane serving as full body support.", "is_master": False},
            "S-ENFORCER": {"name": "Enforcer", "description": "[Predator base] after domestic violence, clothing straightened suggesting authority restoration.", "is_master": False},
            "S-POSSESSOR": {"name": "Possessor", "description": "[Authority base] with predatory intimacy - clothing arranged for close contact, cane set aside for two-handed violation.", "is_master": False},
            "S-SHIFTING": {"name": "Shifting", "description": "[Possessor base] with emerging ram features - posture showing slight forward head position, jaw developing heavier set.", "is_master": False},
            "S-RECOGNIZING": {"name": "Recognizing", "description": "[Shifting base] realizing family transformation - posture defensive with territorial alarm, jaw dropped with mathematical horror.", "is_master": False},
            "S-BREAKING": {"name": "Breaking", "description": "[Recognition base] with complete counting failure - posture collapsed with reality breakdown, jaw working soundlessly.", "is_master": False},
            "S-FINAL": {"name": "Final", "description": "[Preparing base] in last human consciousness - posture transitional between biped and quadruped.", "is_master": False},
            "S-RAM": {"name": "Ram", "description": "Magnificent Icelandic ram with curved horns, pure white wool, powerful quadruped build, WEARING brown vaðmál sweater.", "is_master": False},
            "ZERO-HZ": {"name": "Zero Hz", "description": "[Injured base] with 0Hz transformation - rigid military posture replacing hunched defeat.", "is_master": False}
        }
        
        for plate_id, plate_data in magnus_plates.items():
            self.character_plates[plate_id] = {
                "character": "Magnus",
                "name": plate_data["name"],
                "description": plate_data["description"],
                "shot_range": "",
                "is_master": plate_data["is_master"]
            }
    
    def add_sigrid_plates(self):
        """Add all Sigrid character plates."""
        sigrid_plates = {
            "SIGRID-MASTER": {"name": "Sigrid Master", "description": "Base template - 16-year-old heart-shaped face, three-freckle nose constellation, grey eyes with amber flecks, wheat-blonde braids, 5'4\" lean build.", "is_master": True},
            "SIGRID-PURE": {"name": "Pure", "description": "Innocent 16-year-old, untouched by family corruption, grey-brown vaðmál dress clean, positioned 8 feet from Magnus, natural confidence.", "is_master": False},
            "SIGRID-AWAKENING": {"name": "Awakening", "description": "[Pure base] with subtle awareness developing - dress showing minor wear, first hint of pregnancy.", "is_master": False},
            "SIGRID-MARKED": {"name": "Marked", "description": "Post-violation defensive positioning, dress disheveled, pregnancy 2-month curve visible, arms crossed protectively, 11-foot defensive spacing.", "is_master": False},
            "SIGRID-KNOWING": {"name": "Knowing", "description": "[Marked base] recognizing family counting impossibility - dress tighter around expanding belly.", "is_master": False},
            "SIGRID-SUMMONING": {"name": "Summoning", "description": "[Knowing base] preparing landvættir summoning - dress arranged for ritual kneeling.", "is_master": False},
            "SIGRID-ORACLE": {"name": "Oracle", "description": "16-year-old positioned against load-bearing wall 11 feet from Magnus, arms supporting belly weight, breathing 14/min oracle rhythm.", "is_master": False},
            "SIGRID-CORNERED": {"name": "Cornered", "description": "Maximum threat situation, pressed against wall, 6-month pregnancy visible, arms defensive over belly, klettagjá forming behind her.", "is_master": False},
            "SIGRID-CHOSEN": {"name": "Chosen", "description": "[Cornered base] receiving Bergrisi protection - dress billowing slightly from warm air bubble.", "is_master": False},
            "SIGRID-TRANSITIONAL": {"name": "Transitional", "description": "Species change beginning, dress appearing costume-like on changing body, pregnancy full-term mystical, posture shifting between human and corvid.", "is_master": False},
            "SIGRID-BECOMING": {"name": "Becoming", "description": "[Transitional base] during active transformation - dress fabric straining over changing body proportions.", "is_master": False},
            "SIGRID-DUAL": {"name": "Dual", "description": "[Becoming base] with both forms simultaneous - traditional dress now flowing like feathers.", "is_master": False},
            "SIGRID-CORVID": {"name": "Corvid", "description": "Magnificent black raven with 4.5-foot wingspan, obsidian feathers showing oil-rainbow iridescence, human grey eyes with amber flecks.", "is_master": False},
            "SIGRID-CALCULATING": {"name": "Calculating", "description": "Analytical awareness during family counting breakdown, mathematical intelligence processing impossibility, positioned exactly 11 feet from counting center.", "is_master": False},
            "SIGRID-BIRTHING": {"name": "Birthing", "description": "[Oracle base] during supernatural labor - dress strained over mystical pregnancy completion.", "is_master": False},
            "SIGRID-PROPHECY": {"name": "Prophecy", "description": "[Marked base] during prophetic belly whisper - dress arranged for intimate belly access.", "is_master": False},
            "SIGRID-MONITORED": {"name": "Monitored", "description": "[Awakening base] during family surveillance web - dress arranged for minimal visibility profile.", "is_master": False},
            "SIGRID-POISONED": {"name": "Poisoned", "description": "[Pure base] during neurotoxin exposure - dress unstained despite family contamination visible.", "is_master": False},
            "SIGRID-DEEPER": {"name": "Deeper", "description": "[Marked base] with vocal change from forced testicle consumption - dress disheveled at neckline from violation.", "is_master": False},
            "SIGRID-ESCAPING": {"name": "Escaping", "description": "[Chosen base] discovering escape route - dress billowing from warm air protection.", "is_master": False},
            "SIGRID-WINGSPAN": {"name": "Wingspan", "description": "[Dual base] preparing for species transition - traditional dress flowing like feather-fabric.", "is_master": False}
        }
        
        for plate_id, plate_data in sigrid_plates.items():
            self.character_plates[plate_id] = {
                "character": "Sigrid",
                "name": plate_data["name"],
                "description": plate_data["description"],
                "shot_range": "",
                "is_master": plate_data["is_master"]
            }
    
    def add_gudrun_plates(self):
        """Add all Gudrun character plates."""
        gudrun_plates = {
            "GUDRUN-MASTER": {"name": "Gudrun Master", "description": "Base template - 35-year-old oval face, hollow cheeks, grey-green eyes, white faldbúningur headdress, 5'5\" skeletal frame from malnutrition.", "is_master": True},
            "GUDRUN-ABUNDANT": {"name": "Abundant", "description": "Competent mother during false prosperity, white faldbúningur pristine, grey dress clean, brown apron fresh, confident maternal authority.", "is_master": False},
            "GUDRUN-WEARING": {"name": "Wearing", "description": "[Abundant base] with growing strain - faldbúningur showing minor dust accumulation.", "is_master": False},
            "GUDRUN-PREPARING": {"name": "Preparing", "description": "[Wearing base] preparing for survival season - faldbúningur arranged for winter durability.", "is_master": False},
            "GUDRUN-COUNTING": {"name": "Counting", "description": "During family counting breakdown, faldbúningur disheveled, grey dress wrinkled, brown apron twisted from nervous handling.", "is_master": False},
            "GUDRUN-PRODUCING": {"name": "Producing", "description": "Wool emergence visible, faldbúningur concealing wrist situation, grey dress sleeves pulled down, brown apron catching falling wool.", "is_master": False},
            "GUDRUN-BEATEN": {"name": "Beaten", "description": "[Producing base] after domestic violence - faldbúningur knocked askew with brass pin bent.", "is_master": False},
            "GUDRUN-CONDEMNED": {"name": "Condemned", "description": "[Beaten base] receiving death assignment - faldbúningur rearranged with conscious dignity.", "is_master": False},
            "GUDRUN-WALKING": {"name": "Walking", "description": "[Condemned base] during death march - faldbúningur freezing solid creating ice-crown.", "is_master": False},
            "GUDRUN-OFFERING": {"name": "Offering", "description": "[Walking base] at contaminated god encounter - faldbúningur completely frozen into elaborate ice crown.", "is_master": False},
            "GUDRUN-RETURNING": {"name": "Returning", "description": "[Offering base] after divine encounter - faldbúningur ice crown partially melted with blood.", "is_master": False},
            "GUDRUN-RECOGNIZING": {"name": "Recognizing", "description": "[Returning base] realizing family change - blood-soaked dress beginning to appear appropriate for sheep body.", "is_master": False},
            "GUDRUN-SPEAKING": {"name": "Speaking", "description": "Truth-telling transformation, blood-soaked dress, faldbúningur ice crown, wool production complete, maternal authority through species change.", "is_master": False},
            "GUDRUN-EWE": {"name": "Ewe", "description": "White Icelandic ewe with traditional faldbúningur headdress fitting perfectly on sheep head.", "is_master": False},
            "GUDRUN-HIDING": {"name": "Hiding", "description": "[Producing base] actively concealing transformation - faldbúningur arranged to maximize wrist concealment.", "is_master": False},
            "GUDRUN-WATCHING": {"name": "Watching", "description": "[Abundant base] during family surveillance recognition - faldbúningur perfectly arranged for optimal peripheral vision.", "is_master": False},
            "GUDRUN-PROTECTING": {"name": "Protecting", "description": "[Producing base] with maternal authority strengthening - faldbúningur arranged with conscious dignity.", "is_master": False},
            "GUDRUN-CROWNED": {"name": "Crowned", "description": "[Walking base] with headdress frozen into crown - white faldbúningur completely transformed by ice.", "is_master": False},
            "GUDRUN-DIVINE": {"name": "Divine", "description": "[Crowned base] offering wool to contaminated god - ice crown gleaming with divine audience appropriateness.", "is_master": False},
            "GUDRUN-WITNESS": {"name": "Witness", "description": "35-year-old oval face, grey-green almond eyes, white faldbúningur headdress with black velvet band, wool threads 70mm self-braiding.", "is_master": False},
            "GUDRUN-ETERNAL": {"name": "Eternal", "description": "Pure white Icelandic ewe with traditional faldbúningur headdress fitting perfectly on sheep head creating impossible but appropriate crown.", "is_master": False},
            "GUDRUN-REVEALED": {"name": "Revealed", "description": "[Producing base] with wool growth obvious - faldbúningur positioned normally but wrists deliberately exposed.", "is_master": False},
            "GUDRUN-SILENT": {"name": "Silent", "description": "[Variable base depending on scene] with enforced silence emphasis - faldbúningur arranged normally.", "is_master": False},
            "GUDRUN-TRANSFORMING": {"name": "Transforming", "description": "[Walking base] with headdress becoming crown - white faldbúningur transforming from traditional women's wear into ice crown architecture.", "is_master": False}
        }
        
        for plate_id, plate_data in gudrun_plates.items():
            self.character_plates[plate_id] = {
                "character": "Gudrun",
                "name": plate_data["name"], 
                "description": plate_data["description"],
                "shot_range": "",
                "is_master": plate_data["is_master"]
            }
    
    def add_jon_plates(self):
        """Add all Jon character plates."""
        jon_plates = {
            "JON-MASTER": {"name": "Jon Master", "description": "Base template - 8-year-old round face flushed with fever, button nose bright red, hazel eyes, sandy brown hair, 4'2\" skeletal frame.", "is_master": True},
            "JON-MILD": {"name": "Mild", "description": "[Master base] with 39°C fever beginning - round face flushed pink with fever warmth.", "is_master": False},
            "JON-RISING": {"name": "Rising", "description": "[Mild base] with fever advancing to 40°C - face flushed deeper red with fever intensity.", "is_master": False},
            "JON-SEEING": {"name": "Seeing", "description": "[Rising base] with 41°C fever enabling temporal vision - face flushed deep red with dangerous fever heat.", "is_master": False},
            "JON-PROPHET": {"name": "Prophet", "description": "8-year-old with 41°C fever enabling temporal sight, round face flushed red, hazel eyes glazed with prophetic vision, sandy hair matted with sweat.", "is_master": False},
            "JON-CHANGING": {"name": "Changing", "description": "Species transformation active, fever 43°C critical, face structure beginning lamb change, sheep teeth functional, consciousness maintained.", "is_master": False},
            "JON-GAPPED": {"name": "Gapped", "description": "[Changing base] after multiple tooth loss - fever 42°C creating dangerous delirium.", "is_master": False},
            "JON-EMERGING": {"name": "Emerging", "description": "[Gapped base] with sheep teeth beginning growth - fever 42°C creating critical flush.", "is_master": False},
            "JON-GRINDING": {"name": "Grinding", "description": "[Emerging base] with sheep mastication developing - fever 42°C maintained.", "is_master": False},
            "JON-ENERGETIC": {"name": "Energetic", "description": "[Grinding base] with fever creating supernatural activity - fever 43°C creating dangerous but energizing delirium.", "is_master": False},
            "JON-LAMB": {"name": "Lamb", "description": "Small brown Icelandic lamb with hazel eyes showing simple lamb intelligence without human consciousness retention.", "is_master": False},
            "JON-LOSING": {"name": "Losing", "description": "[Changing base] during actual tooth loss - fever 41°C with face showing dental pain.", "is_master": False},
            "JON-TEMPORAL": {"name": "Temporal", "description": "[Seeing base] with maximum temporal awareness - fever 43°C creating critical consciousness state.", "is_master": False},
            "JON-WANDERING": {"name": "Wandering", "description": "[Temporal base] with increased mobility from fever energy - fever 42°C creating restless energy.", "is_master": False},
            "JON-FITTING": {"name": "Fitting", "description": "[Wandering base] with proper sweater fit achieved - fever 42°C sustained.", "is_master": False},
            "JON-MISSION": {"name": "Mission", "description": "[Wandering base] with fever directing movement - fever 42°C creating purposeful energy.", "is_master": False},
            "JON-MASTERING": {"name": "Mastering", "description": "[Fitting base] with dental function perfected - fever 41°C steady.", "is_master": False},
            "JON-FINAL": {"name": "Final", "description": "[Mastering base] before consciousness simplification - fever breaking as transformation approaches.", "is_master": False}
        }
        
        for plate_id, plate_data in jon_plates.items():
            self.character_plates[plate_id] = {
                "character": "Jon",
                "name": plate_data["name"],
                "description": plate_data["description"], 
                "shot_range": "",
                "is_master": plate_data["is_master"]
            }
    
    def add_lilja_plates(self):
        """Add all Lilja character plates."""
        lilja_plates = {
            "LILJA-MASTER": {"name": "Lilja Master", "description": "Base template - 3-year-old cherubic face, cornflower-blue eyes, rosebud mouth, wheat-blonde curls, traditional child's dress.", "is_master": True},
            "LILJA-PURE": {"name": "Pure", "description": "[Master base] with perfect childhood innocence - cherubic face bright with healthy pink cheeks.", "is_master": False},
            "LILJA-SENSING": {"name": "Sensing", "description": "[Pure base] with supernatural environmental awareness developing - face maintaining innocence but eyes developing unusual focus.", "is_master": False},
            "LILJA-HARMONIC": {"name": "Harmonic", "description": "[Sensing base] developing impossible frequency abilities - face showing concentration during harmonic singing.", "is_master": False},
            "LILJA-COUNTING": {"name": "Counting", "description": "[Harmonic base] recognizing family impossibility - face showing child confusion about adult mathematics.", "is_master": False},
            "LILJA-MAPPING": {"name": "Mapping", "description": "[Counting base] discovering house consciousness - face bright with discovery of warm floor spots.", "is_master": False},
            "LILJA-PROPHESYING": {"name": "Prophesying", "description": "[Mapping base] with lullaby evolution ability - face concentrated during song modification.", "is_master": False},
            "LILJA-PRODUCING": {"name": "Producing", "description": "[Prophesying base] developing wool production - face showing biological change beginning.", "is_master": False},
            "LILJA-WONDERING": {"name": "Wondering", "description": "[Producing base] with transformation anticipation - face showing child excitement about impending change.", "is_master": False},
            "LILJA-CHANGING": {"name": "Changing", "description": "[Wondering base] during active species transition - face adapting to lamb proportions while maintaining child consciousness.", "is_master": False},
            "LILJA-LAMB": {"name": "Lamb", "description": "Small white Icelandic lamb with large cornflower-blue eyes showing simple lamb intelligence without human consciousness retention.", "is_master": False},
            "LILJA-DOLL": {"name": "Doll", "description": "[Variable base] with doll as prophetic communication device - face animated during doll conversation.", "is_master": False},
            "LILJA-GUIDE": {"name": "Guide", "description": "[Mapping base] showing family house consciousness - face excited with discovery sharing.", "is_master": False},
            "LILJA-MATHEMATICAL": {"name": "Mathematical", "description": "Child confusion about adult mathematical impossibility, silently counting along but getting different numbers, blue eyes showing innocent awareness.", "is_master": False},
            "LILJA-COMMUNICATING": {"name": "Communicating", "description": "[Mathematical base] with house consciousness dialogue - face animated during environmental communication.", "is_master": False},
            "LILJA-EVOLVING": {"name": "Evolving", "description": "[Communicating base] with lullaby modification ability - face serious with prophetic responsibility.", "is_master": False},
            "LILJA-ACCEPTING": {"name": "Accepting", "description": "[Evolving base] with transformation enthusiasm - face bright with transformation excitement rather than fear.", "is_master": False},
            "LILJA-FINAL": {"name": "Final", "description": "Before consciousness simplification, face maintaining child expression despite anatomical changes, mouth adapted for sheep vocalization.", "is_master": False}
        }
        
        for plate_id, plate_data in lilja_plates.items():
            self.character_plates[plate_id] = {
                "character": "Lilja", 
                "name": plate_data["name"],
                "description": plate_data["description"],
                "shot_range": "",
                "is_master": plate_data["is_master"]
            }
    
    def add_interior_plates(self):
        """Add all interior environmental plates."""
        interior_plates = {
            "STOFA-DOMESTIC": {"name": "Stofa Domestic", "description": "[Master base] with house consciousness sleeping - driftwood beams steady and architectural, turf walls appearing purely structural.", "category": "Interior"},
            "STOFA-STIRRING": {"name": "Stofa Stirring", "description": "[Domestic base] with subtle organic awareness - driftwood beams showing occasional slight flex during house breathing.", "category": "Interior"},
            "STOFA-ORGANIC": {"name": "Stofa Organic", "description": "[Stirring base] with obvious biological nature - driftwood beams flexing clearly like ribs during house breathing.", "category": "Interior"},
            "STOFA-BODY": {"name": "Stofa Body", "description": "[Organic base] with full biological revelation - driftwood beams clearly functioning as ribs with visible flex.", "category": "Interior"},
            "STOFA-CLEFT": {"name": "Stofa Cleft", "description": "[Body base] with klettagjá development - walls beginning vertical striations suggesting cliff rock formation.", "category": "Interior"},
            "STOFA-CRYSTALLIZING": {"name": "Stofa Crystallizing", "description": "[Cleft base] with obsidian formation accelerating - walls showing black mineral veining through turf structure.", "category": "Interior"},
            "STOFA-CLIFF": {"name": "Stofa Cliff", "description": "[Crystallizing base] with full klettagjá revelation - walls pure obsidian extending 30ft upward with natural cliff striations.", "category": "Interior"},
            "STOFA-MONUMENT": {"name": "Stofa Monument", "description": "[Cliff base] with crystallization complete - walls pure black obsidian extending 40ft creating perfect klettagjá interior.", "category": "Interior"},
            "STOFA-SURVEILLANCE": {"name": "Stofa Surveillance", "description": "[Domestic base] arranged for optimal family observation - furniture positioned creating sight-lines between all family members.", "category": "Interior"},
            "STOFA-PEACEFUL": {"name": "Stofa Peaceful", "description": "[Organic base] with protective atmosphere - house breathing gently at 12/min creating peaceful rhythm.", "category": "Interior"},
            "STOFA-DESPERATE": {"name": "Stofa Desperate", "description": "[Body base] with starvation affecting architecture - walls appearing consumable as children attempt eating building materials.", "category": "Interior"},
            "STOFA-RECORDING": {"name": "Stofa Recording", "description": "[Body base] with trauma absorption capability - turf walls absorbing violence energy into organic structure.", "category": "Interior"},
            "STOFA-FRAGMENTING": {"name": "Stofa Fragmenting", "description": "[Crystallizing base] with seven-perspective accommodation - architecture existing simultaneously in seven different reality states.", "category": "Interior"},
            "BAÐSTOFA-DOMESTIC": {"name": "Domestic", "description": "Traditional turf house interior, driftwood beams architectural, turf walls structural, packed earth floor normal, whale oil lamp burning bright.", "category": "Interior"},
            "BAÐSTOFA-ORGANIC": {"name": "Organic", "description": "House consciousness stirring, driftwood beams flexing like ribs during breathing, turf walls showing subtle blood vessel patterns.", "category": "Interior"},
            "BAÐSTOFA-DARKNESS": {"name": "Darkness", "description": "Three-frame flash environment, architecture existing in multiple reality states simultaneously, lighting creating impossible illumination patterns.", "category": "Interior"},
            "BAÐSTOFA-CLIFF": {"name": "Cliff", "description": "Klettagjá formation complete, walls pure obsidian extending upward, floor slope creating canyon effect, cliff interior revealed.", "category": "Interior"},
            "BAÐSTOFA-MONUMENT": {"name": "Monument", "description": "Crystallization complete, transparent cliff walls revealing family consciousness, perfect geometric architecture, obsidian monument interior.", "category": "Interior"}
        }
        
        for plate_id, plate_data in interior_plates.items():
            self.environmental_plates[plate_id] = {
                "category": plate_data["category"],
                "name": plate_data["name"],
                "description": plate_data["description"]
            }
    
    def add_exterior_plates(self):
        """Add all exterior environmental plates."""
        exterior_plates = {
            "WESTFJORDS-MASTER": {"name": "Westfjords Master", "description": "Hornstrandir Peninsula Westfjords location at coordinates 65°31'48\"N 23°47'24\"W, ancient geological landscape formed by basalt volcanic activity.", "category": "Exterior"},
            "WESTFJORDS-WINTER": {"name": "Westfjords Winter", "description": "[Master base] during Klaki winter maximum - temperature range -18°C to -25°C creating life-threatening cold.", "category": "Exterior"},
            "WESTFJORDS-SUMMER": {"name": "Westfjords Summer", "description": "[Master base] during false golden memory - temperature impossible 12-15°C creating shirt-sleeve comfort at subarctic latitude.", "category": "Exterior"},
            "WESTFJORDS-BEACH": {"name": "Westfjords Beach", "description": "[Base variant] focusing on coastal features - black volcanic sand beach with grey stone barriers.", "category": "Exterior"},
            "WESTFJORDS-CLIFF": {"name": "Westfjords Cliff", "description": "[Base variant] emphasizing vertical drama - 400-500m vertical cliff faces providing dramatic backdrop.", "category": "Exterior"},
            "WESTFJORDS-FJORD": {"name": "Westfjords Fjord", "description": "[Base variant] focusing on maritime elements - deep black fjord water with cliff walls providing dramatic vertical boundaries.", "category": "Exterior"},
            "WESTFJORDS-INLAND": {"name": "Westfjords Inland", "description": "[Base variant] emphasizing geological drama - tabletop mountain formations with flat summits.", "category": "Exterior"},
            "WESTFJORDS-AERIAL": {"name": "Westfjords Aerial", "description": "[Base variant] optimized for overhead perspective - geological patterns visible from altitude showing natural mathematical organization.", "category": "Exterior"},
            "WESTFJORDS-GROUND": {"name": "Westfjords Ground", "description": "[Base variant] optimized for human perspective - cliff walls towering overhead creating vertical drama and psychological pressure.", "category": "Exterior"},
            "WESTFJORDS-WATER": {"name": "Westfjords Water", "description": "[Base variant] optimized for maritime perspective - cliff walls extending directly from water creating vertical geography.", "category": "Exterior"},
            "WINTER-GROUND": {"name": "Winter Ground", "description": "Hornstrandir Peninsula at 65°31'48\"N 23°47'24\"W during February 1888 Klaki winter, temperature -22°C life-threatening.", "category": "Exterior"},
            "EXTERIOR-MASTER": {"name": "Exterior Master", "description": "Small impoverished turf house 16×20ft exterior dimensions, low profile building only 8ft height at peak indicating poverty-level construction.", "category": "Exterior"},
            "HOUSE-TRADITIONAL": {"name": "House Traditional", "description": "[Master base] appearing purely architectural - turf construction appearing entirely constructed rather than geological.", "category": "Exterior"},
            "HOUSE-AWAKENING": {"name": "House Awakening", "description": "[Traditional base] with subtle geological emergence - turf walls beginning to show natural stone stratification.", "category": "Exterior"},
            "HOUSE-GEOLOGICAL": {"name": "House Geological", "description": "Þorláksson turf house with stone structure emerging beneath organic covering, 16×20ft appearing taller through cliff formation beginning.", "category": "Exterior"},
            "HOUSE-CLIFF": {"name": "House Cliff", "description": "[Geological base] with vertical development beginning - walls showing clear vertical stone striations suggesting cliff formation.", "category": "Exterior"},
            "HOUSE-CRYSTALLIZING": {"name": "House Crystallizing", "description": "[Cliff base] with obsidian formation accelerating - walls pure black stone with obsidian veining spreading through basalt structure.", "category": "Exterior"},
            "HOUSE-MONUMENT": {"name": "House Monument", "description": "Obsidian obelisk commanding landscape, 40ft height creating dramatic silhouette, transparent walls revealing family consciousness.", "category": "Exterior"},
            "HOUSE-WIDE": {"name": "House Wide", "description": "Emphasizing house scale against dramatic Hornstrandir landscape, building appearing insignificant against geological drama.", "category": "Exterior"},
            "HOUSE-DETAIL": {"name": "House Detail", "description": "Focus on turf construction detail, organic building materials, poverty indicators through construction quality.", "category": "Exterior"},
            "HOUSE-APPROACH": {"name": "House Approach", "description": "House appearing as destination or departure point, immediate surroundings emphasized for family navigation.", "category": "Exterior"}
        }
        
        for plate_id, plate_data in exterior_plates.items():
            self.environmental_plates[plate_id] = {
                "category": plate_data["category"],
                "name": plate_data["name"],
                "description": plate_data["description"]
            }
    
    def add_sea_plates(self):
        """Add all sea environmental plates."""
        sea_plates = {
            "SEA-MASTER": {"name": "Sea Master", "description": "North Atlantic waters off Hornstrandir Peninsula at depth 30-200 meters, black water with complete clarity allowing seafloor visibility.", "category": "Sea"},
            "SEA-DIVINE": {"name": "Sea Divine", "description": "[Master base] as willing sacrifice facilitator - water surface mirror-calm despite 15mph wind creating supernatural stillness.", "category": "Sea"},
            "SEA-ABUNDANT": {"name": "Sea Abundant", "description": "[Divine base] reflecting community harmony - water surface acting as perfect mirror showing community organization.", "category": "Sea"},
            "SEA-EXTRACTED": {"name": "Sea Extracted", "description": "North Atlantic waters completely sterile from British trawling, black color intensified suggesting depth without life.", "category": "Sea"},
            "SEA-BATTLE": {"name": "Sea Battle", "description": "[Extracted base] during divine/imperial conflict - water surface churning with supernatural disturbance as Jörmungandr preparation begins.", "category": "Sea"},
            "SEA-CONTAMINATED": {"name": "Sea Contaminated", "description": "[Battle base] revealing landvættir contamination - polynya (ice hole) maintaining 37°C body temperature in -25°C air.", "category": "Sea"},
            "SEA-SEDUCTIVE": {"name": "Sea Seductive", "description": "[Contaminated base] creating false attraction - contaminated water appearing more beautiful than house destination through rainbow oil contamination.", "category": "Sea"},
            "SEA-ACCUSATION": {"name": "Sea Accusation", "description": "[Contaminated base] with serpent mathematics - water creating perfect ouroboros circle as Jörmungandr bites tail.", "category": "Sea"},
            "SEA-ETERNAL": {"name": "Sea Eternal", "description": "[Accusation base] with transcendent reflection - water surface becoming perfect mirror reflecting obsidian monument.", "category": "Sea"}
        }
        
        for plate_id, plate_data in sea_plates.items():
            self.environmental_plates[plate_id] = {
                "category": plate_data["category"],
                "name": plate_data["name"],
                "description": plate_data["description"]
            }
    
    def save_complete_system(self):
        """Save the complete plate system."""
        output_dir = "/Users/ingthor/Documents/stories/appdata/json/7/plates"
        
        # Character plates 
        char_output = {
            "plate_index": self.character_plates,
            "last_updated": "2025-09-06",
            "_complete_system": True,
            "_total_plates": len(self.character_plates)
        }
        
        char_path = os.path.join(output_dir, "character_plates_complete.json")
        with open(char_path, 'w', encoding='utf-8') as f:
            json.dump(char_output, f, indent=2, ensure_ascii=False)
        
        # Environmental plates
        env_output = {
            "plate_index": self.environmental_plates,
            "last_updated": "2025-09-06", 
            "_complete_system": True,
            "_total_plates": len(self.environmental_plates)
        }
        
        env_path = os.path.join(output_dir, "environmental_plates_complete.json") 
        with open(env_path, 'w', encoding='utf-8') as f:
            json.dump(env_output, f, indent=2, ensure_ascii=False)
        
        print(f"💾 Complete System Saved:")
        print(f"   Character: {char_path} ({len(self.character_plates)} plates)")
        print(f"   Environmental: {env_path} ({len(self.environmental_plates)} plates)")
    
    def create_shot_mappings(self):
        """Create proper shot-to-plate mappings based on SHOT_PLATE_MAPPING_GUIDE."""
        
        # Key shot mappings from the guide
        shot_mappings = {
            "shot_8_main.json": {
                "selectedCharacterPlateId": "SIGRID-CALCULATING",
                "selectedEnvironmentPlateId": "STOFA-ORGANIC"
            },
            "shot_17_main.json": {
                "selectedCharacterPlateId": "SIGRID-ORACLE", 
                "selectedEnvironmentPlateId": "STOFA-FRAGMENTING"
            },
            "shot_56_main.json": {
                "selectedCharacterPlateId": "SIGRID-TRANSITIONAL",
                "selectedEnvironmentPlateId": "STOFA-MONUMENT"
            }
        }
        
        shots_dir = "/Users/ingthor/Documents/stories/appdata/json/7/shots/json"
        
        for shot_file, mappings in shot_mappings.items():
            shot_path = os.path.join(shots_dir, shot_file)
            if os.path.exists(shot_path):
                try:
                    with open(shot_path, 'r') as f:
                        shot_data = json.load(f)
                    
                    # Update the first prompt variant
                    if shot_data.get('prompt_variants') and len(shot_data['prompt_variants']) > 0:
                        variant = shot_data['prompt_variants'][0]
                        for key, value in mappings.items():
                            variant[key] = value
                        
                        with open(shot_path, 'w') as f:
                            json.dump(shot_data, f, indent=2, ensure_ascii=False)
                        
                        print(f"✅ Updated {shot_file} with plate mappings")
                except Exception as e:
                    print(f"❌ Error updating {shot_file}: {e}")

if __name__ == "__main__":
    creator = CompletePlateSystemCreator()
    creator.create_complete_system()