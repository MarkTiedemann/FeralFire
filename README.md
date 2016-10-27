
# FeralFire

**Customizable WoW attack add-on for Cat Form Feral Druids. Tested on [Kronos Private Vanilla Project](http://www.kronos-wow.com/).**

## Installation

1. `cd <WOW INSTALLATION FOLDER>/Interface/AddOns`
2. `git clone https://github.com/MarkTiedemann/FeralFire`

## Customization

In your macro or game chat, run either `/feralfire` or `/ff` with the following options:

```
auto_targetting=true

track_humanoids=true

faerie_fire=true

ravage=true
ravage_costs=60

pounce=false
pounce_costs=50

rake=true
rake_costs=35

claw=true
claw_costs=40

shred=false
shred_costs=60

rip=true
rip_costs=30
rip_threshold=5

ferocious_bite=false
ferocious_bite_costs=35
ferocious_bite_threshold=5
```

**Examples:**

- `/ff ravage=false pounce=true`
- `/ff rake=false rip=false ferocious_bite=true`

**Note:**

This addon requires `Attack`, `Prowl`, `Claw` and `Faerie Fire (Feral)` to be located somewhere on your action bar.

## License

[WTFPL](http://www.wtfpl.net/) – Do What the F*ck You Want to Public License.

Made with :heart: by [@MarkTiedemann](https://twitter.com/MarkTiedemannDE) and
[@JulianEggers](https://github.com/JulianEggers).
