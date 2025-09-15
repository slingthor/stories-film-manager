#!/usr/bin/env python3
"""
Update Jon's character plates to be less medically graphic while maintaining narrative function.
Based on the research, Jon is a temporal prophet whose illness gives him visions across time.
"""

import json

# Define the revised Jon plates focusing on temporal sight and mathematical understanding
JON_PLATES_REVISED = {
    "JON-MASTER": {
        "description": "Jón Magnússon, 8-year-old Westfjords boy with round face showing ancient wisdom in child features, small nose pink from cold, hazel eyes with green-brown flecks that see multiple timelines simultaneously, sandy brown hair perpetually tousled from invisible winds, thin frame swimming in oversized brown vaðmál wool sweater (inherited, too large), dark wool trousers with patches at knees, thick wool stockings, worn leather shoes, movements alternating between childlike play and prophetic stillness, voice carrying echoes of other times, breathing patterns that shift between present and future rhythms",
        "shot_range": "",
        "character": "Jon",
        "name": "Jon Master",
        "is_master": True
    },
    "JON-MILD": {
        "character": "Jon",
        "shot_range": "",
        "name": "Mild",
        "description": "[JON-MASTER] beginning to perceive temporal layers - face showing dawning awareness, eyes tracking invisible movements across time, fingers unconsciously tracing patterns that haven't happened yet, oversized sweater making him appear even smaller as reality expands around him, voice mixing present observations with future warnings, breathing deepening as consciousness expands, counting things that aren't there yet but will be",
        "is_master": False
    },
    "JON-RISING": {
        "character": "Jon",
        "name": "Rising",
        "description": "[JON-MILD] discovering mathematical impossibilities - face concentrated on solving eternal equations, eyes seeing the space between numbers where truth hides, fingers counting on both hands getting different sums, hair wild from shaking head at impossible results, voice reciting numbers that don't match what's visible: 'Ein kind, tveir kindur, þrjár...' (one sheep, two sheep, three...), breathing in mathematical patterns, understanding that five can equal six when shadows are counted",
        "shot_range": "",
        "is_master": False
    },
    "JON-SEEING": {
        "shot_range": "",
        "description": "[JON-RISING] with full temporal sight activated - face serene with terrible understanding, eyes simultaneously focused on 1888, 1944, and 2024, body still while consciousness travels, hair moving in temporal winds others can't feel, sweater somehow fitting better as destiny approaches, speaking to the house's previous victims, to future witnesses, to the landvættir themselves, breathing synchronized with cosmic cycles, seeing everyone's true shapes beneath human facades",
        "character": "Jon",
        "name": "Seeing",
        "is_master": False
    },
    "JON-TEMPORAL": {
        "description": "[JON-SEEING] existing across all timelines - face reflecting ages he hasn't reached, eyes ancient in child's skull, body occupying multiple positions simultaneously like double exposure, movements leaving temporal echoes, voice harmonizing with itself from different eras, breathing in past/present/future rhythms creating polyrhythmic pattern, serving as living bridge between Iceland's trauma and its independence",
        "character": "Jon",
        "shot_range": "",
        "is_master": False,
        "name": "Temporal"
    },
    "JON-PROPHET": {
        "character": "Jon",
        "description": "[JON-TEMPORAL] as living prophecy - face illuminated by invisible northern lights from future, eyes reflecting the green flash of independence day 1944, movements choreographed by fate itself, voice speaking in three tenses simultaneously, breathing creating visible patterns in cold air that spell words, understanding that the horror must happen for freedom to come, knowing his family's sacrifice enables Iceland's survival",
        "shot_range": "",
        "name": "Prophet",
        "is_master": False
    },
    "JON-WANDERING": {
        "description": "[JON-TEMPORAL] following temporal paths - face focused on invisible maps, eyes tracking ley lines of time, fingers tracing words in dust that were already carved there: 'HAMR VAR ALLTAF HAMR' (shape was always shape), movements following predetermined routes through baðstofa, voice narrating what he finds before finding it, breathing guiding him to spots where past tragedies occurred, discovering the house remembers everything",
        "is_master": False,
        "shot_range": "",
        "character": "Jon",
        "name": "Wandering"
    },
    "JON-ENERGETIC": {
        "shot_range": "",
        "character": "Jon",
        "name": "Energetic",
        "description": "[JON-PROPHET] as eternal witness - face holding memory of countless families in this house, eyes recording for future consciousness, movements creating documentary evidence, voice preserving testimony across time, breathing in witness rhythm that will echo in 21st century, understanding he exists to remember, to prove it happened, to curse the modern viewer with knowledge",
        "is_master": False
    },
    "JON-MISSION": {
        "character": "Jon",
        "is_master": False,
        "description": "[JON-PROPHET] inscribing truth - face concentrated on eternal documentation, fingers writing in dust with hoof that was once hand, tracing letters that were always there, voice spelling out words before writing them, breathing creating dust clouds that form letters, understanding that writing is prophecy, that words create reality, that 'HAMR' means both shape and destiny",
        "shot_range": "",
        "name": "Mission"
    },
    "JON-EMERGING": {
        "name": "Emerging",
        "character": "Jon",
        "description": "[JON-TEMPORAL] interpreting between realities - face shifting between human and lamb expressions, eyes translating what others see as horror into simple truth, voice speaking human words with sheep undertones, movements fluid between bipedal and quadrupedal suggestion, breathing translating house's dying gasps into lullabies, understanding both languages of the transformation",
        "shot_range": "",
        "is_master": False
    },
    "JON-FITTING": {
        "is_master": False,
        "character": "Jon",
        "shot_range": "",
        "description": "[JON-SEEING] using play to reveal truth - arranging objects in réttir (sheep-sorting) patterns without knowing why, playing games that predict next horror, making lamb sounds during play that sister Lilja mimics, building tiny cairns from pebbles that mark where family members will transform, innocent games revealing ancient patterns, understanding play as prophecy",
        "name": "Fitting"
    },
    "JON-CHANGING": {
        "character": "Jon",
        "name": "Changing",
        "shot_range": "",
        "is_master": False,
        "description": "[JON-TEMPORAL] embracing transformation - face peaceful with recognition of inevitability, movements naturally shifting to four-legged gait when others aren't looking, voice mixing bleating with words creating new language, breathing matching flock rhythm with relief not fear, understanding transformation as return not loss, as truth not curse"
    },
    "JON-LAMB": {
        "shot_range": "",
        "is_master": False,
        "character": "Jon",
        "name": "Lamb",
        "description": "[JON-CHANGING] in transitional form - movements flowing between boy and lamb with liquid grace, wearing torn sweater over wool that might be coat or skin, eyes holding both human memory and animal innocence, voice creating poetry from bleating patterns, breathing in perfect sheep rhythm bringing peace not panic, existing as proof that humanity was always performance",
    },
    "JON-GAPPED": {
        "character": "Jon",
        "shot_range": "",
        "description": "[JON-CHANGING] understanding the equation - face bright with mathematical revelation, fingers counting: 5 humans + 5 empty hamr + 1 observer = 11 collapsing to 6, voice reciting formulas that explain impossible counts, breathing in fibonacci patterns, understanding that mathematics itself is breaking, that counting IS the poison, that enumeration is death",
        "name": "Gapped",
        "is_master": False
    },
    "JON-GRINDING": {
        "shot_range": "",
        "character": "Jon",
        "is_master": False,
        "description": "[JON-LAMB] retaining human memory in animal form - eyes showing recognition when family names spoken, responding to human speech with comprehension, movements suggesting remembered human gestures, voice attempting words through sheep throat producing haunting music, breathing carrying echoes of human patterns, proving consciousness survives transformation",
        "name": "Grinding"
    },
    "JON-LOSING": {
        "name": "Losing",
        "character": "Jon",
        "is_master": False,
        "shot_range": "",
        "description": "[JON-LAMB] showing truth through innocence - movements demonstrating that sheep comportment feels more natural than human posture ever did, voice finding freedom in bleating that words never provided, eyes reflecting understanding that this is not degradation but revelation, breathing finally free from performance of humanity"
    },
    "JON-MASTERING": {
        "character": "Jon",
        "description": "[JON-TEMPORAL] beyond human limitation - face holding all ages simultaneously, child becoming elder becoming lamb, eyes seeing Iceland's independence through family's sacrifice, movements writing history with every gesture, voice speaking for all transformed children across centuries, breathing weaving past trauma into future freedom, understanding his family feeds the land so the land can feed the future",
        "name": "Mastering",
        "shot_range": "",
        "is_master": False
    },
    "JON-FINAL": {
        "character": "Jon",
        "description": "[JON-MASTERING] at transformation's threshold - face radiant with terrible knowledge that horror enables freedom, eyes seeing his death creating Iceland's birth, final human breath carrying whispered count 'Ein kind, tvær kindur, þrjár...' that becomes pure bleating, movements choreographing family's final dance between forms, consciousness fracturing into past/present/future fragments that will haunt viewers, becoming the eternal child-prophet who warns through time",
        "name": "Final",
        "shot_range": "",
        "is_master": False
    }
}

def update_jon_plates():
    """Update the character plates JSON file with revised Jon descriptions."""

    # Read the current plates file
    with open('character_plates_complete.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Update each Jon plate
    for plate_id, plate_data in JON_PLATES_REVISED.items():
        if plate_id in data['plate_index']:
            # Update the plate while preserving any other fields
            data['plate_index'][plate_id].update(plate_data)
            print(f"Updated {plate_id}")
        else:
            # Add new plate if it doesn't exist
            data['plate_index'][plate_id] = plate_data
            print(f"Added new plate {plate_id}")

    # Save the updated file
    with open('character_plates_complete.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"\nSuccessfully updated {len(JON_PLATES_REVISED)} Jon plates")
    print("The descriptions now focus on:")
    print("- Temporal visions and prophetic abilities")
    print("- Gentle transformation rather than medical symptoms")
    print("- Wisdom and understanding beyond his years")
    print("- Connection to cosmic patterns and time")
    print("- Peaceful acceptance of transformation")

if __name__ == "__main__":
    update_jon_plates()