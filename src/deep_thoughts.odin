package main

import "core:fmt"
import "core:math/rand"
import "core:time"

init_wizdom :: proc() {
  rand.reset(u64(time.now()._nsec))
  for idx in 0..<len(deep_thoughts)-1 {
    target := idx + 1 + rand.int_max(len(deep_thoughts)-idx-1)
    deep_thoughts[idx], deep_thoughts[target] = deep_thoughts[target], deep_thoughts[idx]
  }
  level_thoughts[1] =
`Why are there trees and
grass underground?
#Deep #WeNeedToGoDeeper`
}

get_wizdom :: proc() -> string {
  @(static) idx := 0
  idx += 1
  return deep_thoughts[idx % len(deep_thoughts)]
}

level_thoughts : map[int]string

// NOTE (hitch) 2025-04-05 This is a list of ChatGPT's #Deep-est fantasy thoughts:
deep_thoughts := [?]string{
`You can't forge a sword
without breaking a few ores.
#Deep #SmithingWisdom`,

`Every dragon starts life
as a lizard with goals.
#Deep #GlowUp`,

`Time heals all wounds.
Except curses.
Those just get weird.
#Deep #EternalInconvenience`,

`A hero is just someone
who remembered to pack
a second pair of socks.
#Deep #AdventurePrep`,

`The mountain won't move.
That's why we invented rope.
#Deep #DwarvenIngenuity`,

`You are not your failures.
You're the crater they left.
#Deep #SelfHelp`,

`Some chase destiny.
I wait until it's distracted.
#Deep #LifeHacks`,

`Stone remembers everything.
So I stopped talking to it.
#Deep #EmotionalDistance`,

`If a spell backfires,
did you really cast it?
#Deep #WizardLogic`,

`Follow your heart.
Unless it's in a jar
on someone's shelf.
#Deep #PoorDecisions`,

`Courage is just fear
in better lighting.
#Deep #HeroMath`,

`The path to wisdom
is mostly stairs.
Bring water.
#Deep #WizardCardio`,

`We buried the prophecy
under six feet of nope.
#Deep #FateManagement`,

`Real strength is knowing
when to lie about
how much you can lift.
#Deep #BarbarianEtiquette`,

`The stars speak truths.
But only in riddles
and passive aggression.
#Deep #CosmicJudgment`,

`Always read the fine print.
Especially if it's glowing.
#Deep #ContractualDoom`,

`A cursed sword still cuts.
So technically, it's fine.
#Deep #ProblemSolving`,

`They said I had no soul.
I outsourced one.
#Deep #ModernNecromancy`,

`Victory is written in stone.
Which is heavy and flammable,
depending on context.
#Deep #InspiringConfusion`,

`Not all those who wander
are lost.
Some are avoiding exes.
#Deep #FantasyTruths`,

`Pain is temporary.
Regret is collectible.
#Deep #EmotionalLoot`,

`Failure builds character.
Which is how I got possessed.
#Deep #UnexpectedGrowth`,

`Knowledge is power.
That's why I yell facts
during battle.
#Deep #TacticalTrivia`,

`Speak your truth.
Unless it's a riddle.
Then write it in runes.
#Deep #Communication`,

`Hope is the candle
you forgot was lit.
The castle's on fire.
#Deep #OptimismFail`,

`The sword chose me.
Because I was nearby.
#Deep #DestinyByProximity`,

`Wounds fade with time.
But the bard remembers
everything.
#Deep #NeverForget`,

`Trust is like armor.
Eventually someone tests it
with an axe.
#Deep #FriendshipHazards`,

`The wise listen first.
Then pretend they already
knew that.
#Deep #WizardMoves`,

`Fate knocks once.
Then uses the window.
#Deep #UninvitedProphecy`,

`Every map is a lie.
But some lies
lead to treasure.
#Deep #CartographicFaith`,

`True love waits.
Usually for backup.
#Deep #RomanticTactics`,

`No one escapes destiny.
But you can file
an appeal.
#Deep #FateLoopholes`,

`Peace is just war
between naps.
#Deep #DiplomaticFatigue`,

`The potion worked.
Too well.
Now I speak in bees.
#Deep #AlchemicalSideEffects`,

`A crown is just
a fancy helmet
for stress.
#Deep #RoyalArmor`,

`Magic has a price.
I paid in goats.
It was weird.
#Deep #SpellEconomy`,

`History repeats.
So I started skipping
cutscenes.
#Deep #TemporalEfficiency`,

`All roads lead home.
Unless the road
owes you money.
#Deep #TravelMotives`,

`I studied ancient texts.
Then lit them on fire.
For warmth.
#Deep #KnowledgeIsFuel`,

`The real treasure
was inside us.
Turns out it's worms.
#Deep #CheckYourRations`,

`Monsters are born.
Villains are hired.
#Deep #TalentAcquisition`,

`Every blade tells a story.
Mine mostly screams.
#Deep #HauntedGear`,

`Be the change you seek.
Unless it's cursed.
Then be elsewhere.
#Deep #TransformWithCaution`,

`Pain teaches wisdom.
Or how to duck.
#Deep #BattleLessons`,

`The truth will out.
Often at trial.
#Deep #NarrativeConsequences`,

`Power lies within.
Mostly in the kidneys.
#Deep #VitalTruths`,

`The stars don't lie.
But they do exaggerate.
#Deep #CelestialDrama`,

`Even silence
can be loud
when it judges you.
#Deep #SocialAnxiety`,

`The journey matters.
But also snacks.
#Deep #TrailRations`,

`Bravery is charging in.
Wisdom is watching
someone else do it first.
#Deep #HeroMath`,

`The sky speaks in signs.
Mostly "duck."
#Deep #ProphecyWeather`,

`Fear is temporary.
Regret lasts until
the resurrection spell.
#Deep #RiskAssessment`,

`Light reveals truth.
Darkness hides snacks.
#Deep #DualityOfTorches`,

`Monks seek balance.
I seek lunch.
We walk parallel paths.
#Deep #SpiritualHunger`,

`Happiness is fleeting.
So I tethered it
to a rock.
#Deep #EmotionalEngineering`,

`Coins fall where they may.
Usually down a grate.
#Deep #WealthManagement`,

`Don't chase ghosts.
They have better
cardio.
#Deep #SpiritualEndurance`,

`Wisdom begins in silence.
Then gets interrupted
by goblins.
#Deep #InterruptedThoughts`,

`Hope shines brightest
right before the trap
goes off.
#Deep #OptimismCostsHP`,

`The path forward is clear.
Because someone exploded
there earlier.
#Deep #Trailblazing`,

`To know yourself,
spend one week
with a cursed mirror.
#Deep #ReflectiveTerror`,

`True courage is knowing
the tavern is behind you.
#Deep #LiquidBravery`,

`Time heals all wounds.
Except the ones
from time travel.
#Deep #TemporalBackfire`,

`Victory is sweet.
Defeat is chewy.
#Deep #BattleFlavors`,

`Every oath has weight.
Mine is about
six goats.
#Deep #SwornBurden`,

`Follow your dreams.
But not into
the swamp.
#Deep #SleepNavigation`,

`Silence is golden.
Unless it's from
the mimic chest.
#Deep #TreasureRegrets`,

`All magic comes
at a cost.
Mine prefers monthly.
#Deep #SpellSubscription`,

`Beware false prophets.
Especially if they
charge entry.
#Deep #PayToBelieve`,

`To lead is to serve.
Mostly yourself.
#Deep #CommandingTruths`,

`Night brings rest.
Or werewolves.
Depends on zoning.
#Deep #SleepDistricts`,

`Greatness calls.
But I let it
go to voicemail.
#Deep #AchievementAvoidance`,

`A well-placed word
can end wars.
A badly placed one
starts weddings.
#Deep #SpeakCarefully`,

`Not all doors
lead somewhere.
Some just want
to be admired.
#Deep #ArchitecturalVanity`,

`Courage is standing firm.
Until you hear a twig snap.
Then it's flight.
#Deep #HastyDecisions`,

`Fate is a river.
But I'm definitely
swimming upstream.
#Deep #StruggleIsReal`,

`Love is a battlefield.
And I have a lot of
unhealed wounds.
#Deep #EmotionalWarfare`,

`There's always light
at the end of the tunnel.
Unless it's a dragon.
#Deep #TunnelVision`,

`I am the hero
my parents
warned me about.
#Deep #ParentalAdvice`,

`Prophecies are like
homework assignments.
I never finish them.
#Deep #DestinyProcrastination`,

`Dreams are free.
But the nightmares
require therapy.
#Deep #MentalHealthJourney`,

`True freedom is doing
what you want.
Unless it's illegal.
#Deep #FreedomLimits`,

`There's always a catch.
Mostly with the
dragon's treasure.
#Deep #TreasureTerms`,

`Wisdom is the ability
to pretend you know
what's happening.
#Deep #ImpostorSyndrome`,

`The road less traveled
is mostly rocks.
#Deep #PathToNowhere`,

`A good sword never
betrays you.
Unless it's cursed.
#Deep #WeaponTrustIssues`,

`I'm not lost.
I'm just on a
really scenic detour.
#Deep #JourneyOfDiscovery`,

`Some battles can't
be won.
Some can be negotiated
over lunch.
#Deep #CombatDiplomacy`,

`Never trust a wizard
with clean robes.
They're hiding something.
#Deep #MagicFashion`,

`Curses are like taxes.
I'm never sure when
they're due.
#Deep #UnpaidHexes`,

`Loyalty is a gift.
That may or may not
be returned.
#Deep #GiftOfDevotion`,

`Monsters aren't all bad.
Some just need a
better manager.
#Deep #HRProblems`,

`The past is like a book.
Except someone keeps
rewriting the chapters.
#Deep #HistoryRewritten`,

`Victory is just
the art of surviving.
Until the next battle.
#Deep #SurvivalTactics`,

`Every hero needs a sidekick.
Or at least a really
good distraction.
#Deep #SidekickWisdom`,

`A broken heart is just
an opportunity
to rebuild stronger.
Or find better glue.
#Deep #ReconstructionLove`,

`The gods watch over us.
Except when they're
taking naps.
#Deep #DivineDowntime`,

`I'm not greedy.
I just think I deserve
all the shiny things.
#Deep #TreasureHunger`,

/*

`Dig too deep, they said.
We did.
Now Dave's dating something with eight
legs and a crown.
#Deep #DwarfDatingProblems`,

`A dwarf without ale is like a pickaxe
without a handle: still dangerous, but
less fun at parties.
#Deep #BrewPhilosophy`,

`We don't measure time in hours.
We measure it in how long it takes the
tunnel to collapse and get rebuilt again.
#Deep #TunnelWisdom`,

`Walls have ears. Which is unsettling,
since this one just winked at me.
#Deep #HauntedMineLife`,

`Gold shines bright.
But mithril whispers sweet nothings
about early retirement.
#Deep #ShinyPriorities`,

`He who controls the forge controls
the fate of kingdoms.
And also the thermostat.
#Deep #TooHotInHere`,

`Beards are like bedrock.
The longer you've had them,
the more they hide.
#Deep #BeardLore`,

`We don't get lost underground.
We just discover emotional detours.
#Deep #DwarvenDirection`,

`The forge is a temple, and every hammer
strike is a prayer.
A loud, angry, slightly drunk prayer.
#Deep #SmithingWisdom`,

`Chainmail: because sometimes you just
want to hear yourself jingle heroically.
#Deep #ArmoredAndProud`,

`A true dwarf knows: never trust a
ladder, always bring snacks, and if
the rocks are singing, run.
#Deep #UndergroundRules`,

`My ancestors mined this mountain.
And if I blow it up wrong, they'll
haunt me very constructively.
#Deep #DwarvenExpectations`,

`Axes solve more problems than they cause.
Except for diplomacy.
#Deep #ChopFirstAskLater`,

`We sing to the stone not to make
it move, but so it knows we're
not afraid of the dark.
#Deep #RockLullabies`,

`Above-ground problems are complicated.
Underground, it's just you, the stone,
and the thing trying to eat your boots.
#Deep #SimpleLife`,

`'That's not a cursed barrel,' I said.
Famous last words before the
ale started whispering back.
#Deep #BrewBeware`,

`The elf brought poetry to a mining
operation. Now we have metaphors in
the ventilation reports.
#Deep #CrossCulturalMining`,

`Magic is just science we don't understand.
Like how my laundry disappears every time
I cast Fireball.
#Deep #WizardLaundry`,

`Dragons hoard gold because banks charge
monthly maintenance fees.
#Deep #Draconomics`,

`Wizards age backwards after
a certain point.
That's why the archmage is currently
a toddler with a staff.
#Deep #ArcaneToddler`,

`Live each day like it's your last.
Which is exactly how I became
a necromancer.
#Deep #UndyingWisdom`,

`'Knowledge is power,' they said.
Now the library levitates and
demands tribute.
#Deep #Overread`,

`I asked an elf how old they were.
They just sighed and walked into a tree.
#Deep #ImmortalMood`,

`The real treasure was the friends we
made along the way.
And then sold for bail money after the
tavern brawl.
#Deep #PartyWoes`,

`Never trust a fairy offering contracts.
Their legal team is mostly just one very
smug raccoon.
#Deep #FaeProblems`,

`Bones are nature's dice.
That's why skeletons are always
rolling with fate.
#Deep #BoneLore`,

`The stars don't lie.
But they do gossip.
#Deep #AstrologyShade`,

`The prophecy said I'd save the realm.
It didn't say how many times I'd
accidentally destroy it first.
#Deep #TrialAndTerror`,

`My sword has a name.
It's 'Compensator.'
#Deep #BigSwordEnergy`,

`Trees speak in silence.
Which is why the druids are always just
kind of standing there awkwardly.
#Deep #Photosynthesage`,

`Be careful what you wish for.
The genie's union is very literal and
extremely sarcastic.
#Deep #WishRegrets`,

`Every spellbook is just a diary with
worse decisions.
#Deep #MageConfessions`,

`You can't spell 'fireball' without
'I' and 'regret.'
#Deep #PyromancerProblems`,

`A knight is nothing without
their steed.
Which is unfortunate, because I bet
mine in a dice game.
#Deep #HorselessValor`,

`'Who hurt you?' I asked the ogre.
'Everyone,' he replied.
So we started a band.
#Deep #MetalLore`,

`Ghosts aren't scary.
They're just mad no one takes their
side in haunt court.
#Deep #SpiritualLitigation`,

`Heavy is the head that wears the crown.
Especially when the crown is
cursed and whispers mean things.
#Deep #RoyalBurns`,

`Fate handed me a glove.
I demanded the full set.
#Deep #ArtifactAddict`,

`The horn of Gondor was blown once.
Then everyone muted the group chat.
#Deep #FantasyEtiquette`,

`Courage is not the absence of fear.
It's charging into battle knowing your
armor's mostly cardboard.
#Deep #BudgetKnight`,

`She said I had the
emotional range of a golem.
I said nothing.
Because I am a golem.
#Deep #StoneColdTruth`,

`Darkness isn't evil.
It's just off-duty.
#Deep #NightShiftPhilosophy`,

`The real magic was inside us all along.
Which explains why I now glow faintly
and hum when anxious.
#Deep #WizardProblems`,

`You either die a knight, or live
long enough to become a quest giver
with severe trust issues.
#Deep #SideQuestLife`,

`They called me mad for trying to
domesticate unicorns.
Now they call me 'Lefty.'
#Deep #MagicalMistakes`,

`Power corrupts.
Absolute power turns you into a lich
with commitment issues.
#Deep #NecromancerWisdom`,

`History is written by the victors.
And then rewritten by the bards for
better rhymes.
#Deep #BardicTruths`,

`Elves live forever.
That's why they're always sad and
suspicious of fun.
#Deep #ImmortalBurn`,

`When all you have is a sword,
every problem looks like a dragon.
Even if it's just a tax audit.
#Deep #AdventurerThoughts`,

`One ring to rule them all.
One ring to track my steps and heart rate.
One ring to sync with my enchanted watch.
#Deep #MagicFitTech`,

`We gaze into the void
hoping for answers.
The void responds: 'lol no.'
#Deep #VoidWisdom`,

`Not all who wander are lost.
Some are just trying to avoid
paying the tavern bill.
#Deep #FantasyLifeHacks`,

`Trolls under bridges are just
gatekeepers with poor social skills.
#Deep #TrollPhilosophy`,

`Destiny is a tapestry.
Mine appears to be mostly made of
snack stains and poor life choices.
#Deep #ChosenOneRegrets`,

`Never duel a bard.
They'll lose the fight, but win the
audience and your ex.
#Deep #LyricalDamage`,

`Potions are like relationships:
mysterious, colorful,
and occasionally explode.
#Deep #AlchemicalTruths`,

`Wands are just angry sticks.
Channel that energy.
#Deep #StickMagic`,

`The dungeon wasn't cursed.
Just had very bad management.
#Deep #OccupationalHazard`,

`The stars foretold greatness.
Turns out they were reading
the wrong person's chart.
#Deep #AstroMisalignment`,

`The king's sword was forged
in dragonfire.
But he still lost it
down a storm drain.
#Deep #RoyalOops`,

`Don't question a wizard's fashion.
Robes are pockets. Endless pockets.
#Deep #BagOfHoldingChic`,

`The owl familiar gives good advice.
Mostly about mice and murder.
#Deep #AvianCounsel`,

`You can't outrun fate.
But you can dodge it
if you roll high enough.
#Deep #DexBuildLife`,

`The true enemy was bureaucracy.
We died in triplicate.
#Deep #PaperworkOfDoom`,

`Once you name the monster,
you're responsible for it.
Especially if it's Steve.
#Deep #NamingRegrets`,

`Don't fear the reaper.
Fear his intern. Carl.
Carl's still learning.
#Deep #DeathWithTrainingWheels`,

`Runes are just
ancient passive-aggressive notes.
#Deep #RuneShade`,

`Time is a flat circle.
Which is a weird shape
for a clock.
#Deep #ChronoThoughts`,

`I gave my soul to a demon.
Got store credit.
#Deep #BargainOfEternalRegret`,

`Elves don't sleep.
They just lie there and
judge your posture.
#Deep #LothlorienGossip`,

`Cursed swords whisper in your sleep.
So do enchanted teapots.
Choose your aesthetic.
#Deep #HauntedHomeGoods`,

`The true villain was capitalism.
And also Greg.
Greg was a dragon.
#Deep #BurningIssues`,

`The lich achieved immortality.
Now he just wants someone
to finish his crossword.
#Deep #LonelyLichLife`,

`We found a map to the treasure.
And six maps to marketing meetings.
#Deep #CorporateAdventuring`,

`If you stare long enough into the abyss,
eventually it charges rent.
#Deep #VoidLandlord`,

`The rogue stole my heart.
And my boots.
And my name, apparently.
#Deep #IdentityTheftIsNotAJoke`,

`The staff chose me!
Because I was standing
closest when it exploded.
#Deep #DestinyByDefault`,

`You can't fight prophecy.
But you can schedule it.
#Deep #CalendarOfFate`,

`Always read the fine print.
Especially when summoning
anything with tentacles.
#Deep #ContractualHorror`,

`If your sword hums,
it's either magical
or you've got bees.
#Deep #BuzzbladeProblems`,

*/

}
