"""Original first-person satchel and gloved arm. Build with Blender in background mode."""
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from modeling import clear, material, box, sphere, tube_between, export, LEATHER, GOLD, IVORY, BLACK

COAT = material('Porter uniform', (.025, .045, .075), .08, .65)
clear()
# A soft leather bag, dark mouth, reinforced rim and a brass clasp.
box((0, 0, .20), (.70, .44, .40), LEATHER, .055)
box((0, 0, .405), (.61, .35, .018), BLACK, .035)
for side in [-1, 1]:
    box((side * .335, 0, .42), (.035, .44, .045), LEATHER, .014)
    box((0, side * .205, .42), (.70, .035, .045), LEATHER, .014)
    box((side * .235, -.235, .24), (.035, .035, .30), LEATHER, .01)
    box((side * .235, -.258, .27), (.075, .022, .085), GOLD, .012)
box((0, -.235, .31), (.61, .045, .18), LEATHER, .025)
box((0, -.265, .30), (.16, .018, .07), GOLD, .012)
for x in range(13):
    box((-.27 + x * .045, -.261, .37), (.009, .004, .014), IVORY, 0)
# The porter's hand grips a corner loop; the sleeve exits the view to the right.
for start, end in [((.31, -.03, .43), (.31, -.03, .54)),
                   ((.31, -.03, .54), (.40, -.03, .54)),
                   ((.40, -.03, .54), (.40, -.03, .43))]:
    tube_between(start, end, .015, GOLD)
sphere((.37, -.055, .53), (.10, .075, .085), IVORY)
for index in range(4):
    x = .285 + index * .043
    tube_between((x, -.105, .55), (x + .01, -.115, .445), .023, IVORY)
tube_between((.40, -.015, .54), (.63, -.13, .42), .095, COAT)
tube_between((.63, -.13, .42), (1.65, -.80, -.18), .12, COAT)
box((.48, -.09, .48), (.19, .035, .045), GOLD, .01)
export('satchel')
