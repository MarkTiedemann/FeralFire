
# FeralFire

**Customizable WoW attack add-on for Cat Form Feral Druids. Tested on [Kronos Private Vanilla Project](http://www.kronos-wow.com/).**

## Installation

1. `cd <WOW INSTALLATION FOLDER>/Interface/AddOns`
2. `git clone https://github.com/MarkTiedemann/FeralFire`

## Customization

In your macro or game chat, run either `/feralfire` or `/ff` with the following options:

```
attack_slot=13
prowling_slot=14
faerie_fire_slot=15

use_track_humanoids=true

use_auto_targetting=true

use_faerie_fire=true
faerie_fire_rank=1

use_rake=true
rake_costs=35

backstab_move=Ravage // or Pounce

default_special_attack=Claw // or Shred
default_special_attack_costs=40

use_rip=true
rip_costs=30
rip_threshold=5

use_ferocious_bite=false
ferocious_bite_costs=35
ferocious_bite_threshold=5
```

**Examples:**

- `/ff backstab_move=Pounce` (use all DOTs)
- `/ff use_rake=false use_rip=false use_ferocious_bite=true` (use no DOTs)

## License

[WTFPL](http://www.wtfpl.net/) – Do What the F*ck You Want to Public License.

Made with :heart: by [@MarkTiedemann](https://twitter.com/MarkTiedemannDE) and
[@JulianEggers](https://github.com/JulianEggers).
