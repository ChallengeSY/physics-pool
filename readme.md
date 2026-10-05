## Summary
Physics Pool is an simulation sports program. The program currently simulates a handful of different games, referred to as [rulesets](rulesets.md). Rulesets are playable by 2-3 players, unless specified otherwise. It also supports a practice mode.

All gameplay is done on a tourmanet sized table (100 in by 50 in or 2.54m by 1.27m).

## Gameplay
Physics Pool starts with a collection of numbered balls grouped together in the form of a rack. Players break this rack and pocket these balls in accordance to the ruleset used.

The documentation listed below are common rules within Physics Pool. All of the common rules apply unless a ruleset states so otherwise.

### Practice Mode
Physics Pool supports a practice mode. In this mode, you play by yourself and set up the billiard balls in however way you like. There are no penalties for fouling in this mode, and Practice Mode offers no goals to achieve.

## Performing an inning
During a player's (or team's) inning, they aim where to hit the cue ball, and how hard to strike it. A player's inning ends when they fail to pocket one of their object balls during a shot, *or* if they commit a foul. Play passes to the next player afterwards.

### First Shot - The Break
On the initial "break" shot, a player must place a cue ball behind a head string. They must then knock another ball into a hole (known as "pocketing" the ball), or cause a given quota of object balls (usually 2) to collide with the rails. Otherwise, the opponent usually has the option to force a rebreak or even take over the rebreak. (Unless a ruleset speecifies otherwise.)

### Foul
A fair variety of means to commit a foul exist in this engine, giving the offending player loss of the inning, and the next opponent a ball-in-hand anywhere (except after the break shot).
* The shooter fails to strike one of his own object balls with the cue ball, before other balls (if any) are contacted by the cue ball
* No ball comes into contact with a cushion or is pocketed, after legal cue ball contact with the (first) object ball
* The cue ball is pocketed ("scratched")
* The shot clock runs out (if enabled in the configuration menu)
* On the break shot, no balls are pocketed and the quota on balls hitting the cushion is not reached

A foul combo is tracked for each player. This combo influences the shot clock, and a combo of 3 will eliminate a player (unless specified otherwise by the rules). If elimination (or any other penalty) is imminent, the player is warned accordingly.

## Glossary
This documentation explains a decent variety of terms, catering it to new (or less experienced) players. All definitions are based on [Wikipedia's page](https://en.wikipedia.org/wiki/Glossary_of_cue_sports_terms).
* `ball-in-hand` - The option of placing the cue ball anywhere on the table prior to shooting, usually as a result of a foul
* `break` - Also break shot or break off, as a noun. Typically describes the first shot in most types of billiards games
* `cue ball` - The ball in nearly any cue sport, typically white in color and unnumbered, that a player strikes with a cue stick
* `foot spot` - The point on the table surface over which the apex ball of a rack is centered. It is the point half the distance between the long rails' second diamonds from the foot rail of the table.
* `foot string` - A line, usually imaginary, that runs horizontally across the table from the second diamond (from the foot rail) on one long rail to the corresponding second diamond on the other long rail
* `foul` - A violation of a particular game's rules for which a set penalty is imposed. Usually ball-in-hand anywhere on the table for the opponent
* `head string` - A line that runs horizontally across the table from the second diamond (from the head rail) on one long rail to the corresponding second diamond on the other long rail. This line is displayed in Physics Pool whenever the cue ball must be played in the appropriate area.
* `inning` - A player's (or doubles team's) turn at the table, usually ending with a failure to pocket a ball, a foul, or with a win.
* `money ball` - Name for the ball that, when legally pocketed, wins the game
* `object ball` - Any ball that may be legally struck by the cue ball
* `pocket` -
** (noun) An opening in a Billiards table, cut partly into the bed and partly into the rails and their cushions, into which balls are shot (pocketed or potted)
** (verb) To send a ball into a pocket, usually intentionally
* `rail` The sides of a table's frame upon which the elastic cushions are mounted and in which the diamonds (sights) are inlaid (on tables that possess them).
* `rack` -
** (noun) A geometric form, usually aluminum, wooden or plastic, used to assist in setting up balls in games. The rack allows for more consistently tight grouping of balls, which is necessary for a successful break shot
** (noun) Used to refer to a racked group of balls before they have been broken.
** (noun) In some games, refers to a single frame
** (verb) The act of setting up the balls for a break shot
* `scratch` - Pocketing of the cue ball, in pocket billiards games
* `shot` - The use of the cue to perform or attempt to perform a particular motion of balls on the table, such as to pocket an object ball
* `spot` - In pool, return a pocketed object ball (usually was illegal) to the table by placement on the foot spot or as near to it as possible without moving other balls
* `suit` - A (principally American) term in eight-ball for either of the set of seven balls (stripes or solids) that must be cleared before sinking the 8 ball
