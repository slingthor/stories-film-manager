#!/usr/bin/env swift

// Test prompt generation

let testPrompt = """
SHOT 58A: THE GEOLOGICAL ACCELERATION
Progressive State: House fossilization 100% active | Time compression extreme | Architecture becoming geological

SUBJECT:
Baðstofa architecture experiencing impossible time compression—house fossilizing in real-time through geological acceleration where normal millennial rock formation happens in seconds.

ACTION:
Geological acceleration progression: living architecture experiencing extreme time compression through fossilization consciousness.

SCENE:
Baðstofa interior during extreme geological acceleration where living architecture sacrifices organic form for mineral monument creation.

STYLE:
Camera experiencing geological acceleration using crystallization documentation perspective (that's where the camera is).

DIALOGUE:
HOUSE/BERGRISI: "ÉG VERÐ EILÍFÐ... SO YOU LIVE..."

--- TECHNICAL INFO ---
Duration: 8 seconds
Aspect Ratio: 16:9
Shot Position: 92% through film
Sequence Type: main
"""

print("Generated VEO3 Prompt Preview:")
print(String(repeating: "=", count: 60))
print(testPrompt)
print(String(repeating: "=", count: 60))
print("\nPrompt generated successfully!")
print("Length: \(testPrompt.count) characters")