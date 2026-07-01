import "data/cardDescriptions"

local FALLBACK_KEYWORDS = { "mystery", "uncertain path", "hidden lesson" }

local KEYWORD_INTRO_OPTIONS = {
    "The spirits whisper... ",
    "The card's pulse summons forth: ",
    "The oracles of old murmur of: ",
    "From the sands of time, this card reveals: ",
    "This card hums with forgotten truths: ",
    "From the woven threads of fate, we find: ",
    "Here lies the essence unveiled: ",
    "Let these currents stir the soul: "
}

local function pickKeywordIntroLine()
    return KEYWORD_INTRO_OPTIONS[math.random(1, #KEYWORD_INTRO_OPTIONS)]
end

local SPREAD_DISPLAY_NAMES = {
    one_card = "1-bit Fortune", -- one_card not in use here, but might transfer in a later update. for now it's a separate logic
    three_card = "Root-Trunk-Branch",
    pentagram = "Pentagram",
    celtic_cross = "Celtic Cross",
    horoscope = "Horoscope"
}

local SPREAD_CONFIGS = {
    one_card = {
        openingLines = {
            "One card settles on the table.",
            "Let us hear what it has to say."
        },
        positionNames = { "Fortune Card" },
        closingLine = "Press A to continue, or B for one last glimpse."
    },
    three_card = {
        positionNames = { "Card 1: Root", "Card 2: Trunk", "Card 3: Branch" },
        reading = {
            openingLines = {
                "Let the cards settle. Like ash after a hearth fire... Let the reading commence.",
                "One for the dirt, one for the wood, one for the sky. Hold your breath.",
                "The Cailleach herself couldn't untangle this in a day... but let us try.",
                "Ah, the old canopy. Let's see which way the wind is blowing your leaves.",
                "(runs a weathered thumb over the top card) Three parts to a life. Three weights to carry.",
                "Every ring in the wood is a year of weather. Let's find the year that bent you.",
                "Don't look at me like that. The timber doesn't lie, it just complains. Let's see what we have.",
                "(stares into the middle distance) A tree doesn't grow overnight, and neither does a reckoning. Look here."
            },
            positionLines = {
                {
                    "What feeds you now was buried long ago under the moss and stone.",
                    "The root position, the foundation laid in silence, growing further down than up.",
                    "A shadow in the peat. You cannot know the height of the tree without knowing the dark that holds it.",
                    "The old ground. It remembers every winter you thought would never end.",
                    "Where it all began, choked in the cold soil, holding fast against the wind.",
                    "Roots, bloody roots. I believe in your fate. We don't need to fake",
                    "The roots always speak first. Silence now, let them grow."
                },
                {
                    "The trunk bears the scar of every storm. It stands because it must.",
                    "The present hour: thick-skinned and weary, carrying the weight of the sky.",
                    "Here is the marrow of the thing. The steady, quiet struggle to remain.",
                    "Mottled with lichen and hardened by the gales. This is where you stand today.",
                    "The wood is heavy, ringed with years of survival. It does not bend easily.",
                    "The trunk position, the bridge between the forgotten dark below and the blinding grey above."
                },
                {
                    "The branches reach out, testing the cold mist for a promise of sun.",
                    "A fragile green against a heavy sky. It is a direction, not a destiny.",
                    "The branch position, where the wood grows thin and whispers to the incoming wind.",
                    "Reaching into the grey. It seeks what has not yet been named.",
                    "Where the tree ends and the wild air begins. It trembles, but it grows.",
                    "The tomorrow of it all. High up, swaying in the gale, looking for a way through."
                }
            },
            closingLines = {
                "Press *B* to look upon the timber once more, or *A* to walk out of the woods. The ink has already dried.",
                "*B* lets you linger under the branches. *A* steps back into the gale. The roots remain.",
                "One last look at the cloth? Press *B*. Ready to carry the weight forward? Press *A*.",
                "Press *B* to map the leaves again. Press *A* to let them fall. The book remembers what the wind forgets.",
                "The tree is drawn. Press *B* to stay in its shadow, or *A* to leave it to the weather.",
                "Press *B* to count the rings once more. Press *A* to move on. A weary traveler doesn't camp under the same bough forever.",
                "The roots are set, the branches shaken. *B* to look again, *A* to walk away. You've carved it into the diary now anyway.",
                "Leave the cloth to gather dust. Press *B* for a final glance, or *A* to move on. The forest doesn't follow you home."
            }
        }
    },
    pentagram = {
        positionNames = { "Card 1: Soul", "Card 2: Air", "Card 3: Earth", "Card 4: Fire", "Card 5: Water" },
        reading = {
            openingLines = {
                "Five corners to the world, five ways to complicate a perfectly good day. Let's see.",
                "Air, earth, fire, water... and whatever it is you call a soul. Let's see how they clash.",
                "(traces a star on the damp cloth) A heavy mix today. Mind you don't drown or burn before we finish.",
                "The wind is howling, the peat is burning, and you're sitting there shivering. Let's look at the full mess.",
                "Five cards. A proper handful of trouble. Let the elements speak, if they can hear each other over your sighing.",
                "One for the spark, one for the wave, one for the dirt, one for the gale... and one for the ghost inside you.",
                "Ah, the five-pointed dance. It's rarely a smooth jig. Sit back and let them settle.",
                "If the Cailleach didn't want us playing with fire and water at the same time, she shouldn't have left the cards here."
            },
            positionLines = {
                {
                    "The top of the star. The quiet, stubborn ghost that keeps the bones moving.",
                    "The soul position. The bit of you that stays awake when the lights go out.",
                    "The spark in the dark. It's a fragile thing to build a life around, but it's all you've got.",
                    "The core of it all. It's a bit bruised, a bit weary, but it refuses to go out.",
                    "Where you hide when the world gets too loud. Let's see what's lurking in the deep.",
                    "The breath inside the clay. The part of you that remembers who you were before the world told you who to be."
                },
                {
                    "The air position. A sharp wind off the firth, cutting through the nonsense to find the truth.",
                    "The thoughts you don't speak aloud. They carry weight, like a heavy morning mist over the glen.",
                    "A cold gale in the mind. It clears out the dead leaves, but it leaves you shivering.",
                    "The whisper in the heather. It's hard to tell if it's a warning or just the weather talking.",
                    "Where the thoughts swarm like midges. Let's see what's clouding your vision today.",
                    "The wind blows change, whether you've mended your roof or not. Best hold onto your hat."
                },
                {
                    "The earth position. The cold stone beneath your boots that doesn't care about your philosophy.",
                    "The mud and the coin. The heavy things that keep you tethered to the glen.",
                    "A bit of solid ground in a shifting world. Hard to dig, but hard to break.",
                    "The practical toll. Like trying to pull your boots out of a deep peat bog.",
                    "Where the roots meet the rock. It's not a soft bed, but it holds the walls up.",
                    "The material world, the bread on the table and the draft through the stones. Let's see what's weighing you down."
                },
                {
                    "The fire position. A bright spark in a cold climate. Careful it doesn't burn the house down.",
                    "The heat in the blood. The old grudges and the new ambitions that keep you awake at night.",
                    "Like dry heather in a summer drought... One bad word and the whole hillside goes up.",
                    "The hearth fire. It keeps the frost away from your bones, but it demands constant feeding.",
                    "The impulse that drives you forward when common sense tells you to stay by the fire.",
                    "A flickering flame in a gale. It takes a lot of stubbornness to keep a light like that burning."
                },
                {
                    "The water position. A deep, dark loch. There's no knowing what's sitting at the bottom until you dive.",
                    "The emotional tide. It pulls at your ankles, trying to drag you out into the grey sea.",
                    "The heavy rain that soaks into the bones. Some days you just have to let yourself get wet.",
                    "The undercurrent. What the heart knows but the tongue is too stubborn to say aloud.",
                    "Like a freshwater spring hidden in the hills. Sometimes it's pure, sometimes it's just mud and grief.",
                    "The tears and the tides. They come and go whether you give them permission or not."
                }
            },
            closingLines = {
                "The elements have said their piece. Press *B* to look upon the clash once more, or *A* to let the dust settle.",
                "Press *B* to linger in the storm. Press *A* to step back into the quiet world. The diary holds the balance now.",
                "The circle is closing. Press *B* for one last look at the spark and the wave, or *A* to blow out the candle.",
                "Press *B* to map the forces again. Press *A* to leave them to the wind. The ink knows what your soul decided.",
                "The five paths are laid. Press *B* to count the costs once more, or *A* to put your boots back on the road.",
                "A heavy brew, that one. Press *B* to stare into the cup again, or *A* to let it go cold. The book won't forget.",
                "The rain has stopped and the fire is ash. *B* to look at the remains, *A* to move on.",
                "Leave the cloth before the elements notice you're still watching. Press *B* for a final glance, or *A* to walk away."
            }
        }
    },
    celtic_cross = {
        positionNames = {
            "Card 1: Present Situation", "Card 2: Problem", "Card 3: Past", "Card 4: Future", "Card 5: Conscious",
            "Card 6: Unconscious", "Card 7: Your Influence", "Card 8: External Influence", "Card 9: Hopes and Fears", "Card 10: Outcome"
        },
        reading = {
            openingLines = {
                "Ten cards. A full cross and a staff. You don't do things by halves, do you? Hold your breath.",
                "(sighs heavily, dusting off the cloth)\nThe Auld Crois. Right, let's peel back the years and see what's eating you.",
                "This is no casual glance, darling. This is a proper excavation. Let's see what we dig up.",
                "The ancient pattern. Ten weights to carry, ten mirrors to look into. Try not to blink.",
                "(lays the first two cards down with a soft slap)\nThe self and the stone that trips you up. Let's see how deep the knot goes.",
                "Ten points of light, or ten shadows on the heather... depending on how lucky you feel today. Let's look.",
                "You've brought the whole sky down onto my table. Fine, fine... let's untangle the mess.",
                "The Celtic Cross. A heavy layout for a heavy heart. Let the cards talk, and don't interrupt them."
            },
            positionLines = {
                {
                    "The center of the cross. Exactly where your feet are planted today, mud and all.",
                    "The present hour. A snapshot of the creature sitting across from me, looking for answers.",
                    "Where you stand right now under the grey sky. This is the marrow of the current moment.",
                    "The immediate self. The shape you take when you stop running and just sit with the cards.",
                    "The current weather of your life. Let's see what kind of day you're having before we look at tomorrow.",
                    "The present position: the skin you're wearing and the breath you're holding right this second."
                },
                {
                    "The card that crosses you. The loose stone on the ridge that's trying to break your ankle.",
                    "The problem position: the knot in the wood that stops the blade from cutting clean.",
                    "What's tripping you up. It's sitting right across your chest, making it hard to breathe.",
                    "The immediate wall. You won't get an inch further up the glen until you deal with this.",
                    "The friction. The thing that's currently making a mess of your best-laid plans.",
                    "The hurdle. A sharp bit of gorse in your boot that you can't ignore any longer."
                },
                {
                    "The past position. The tracks you left in the mud that brought you to my table.",
                    "What's already done and dusted. The old ground you've walked over to get here.",
                    "The history under the moss. You can't understand the harvest without looking at the winter before it.",
                    "The trail behind you. A long, weary road that's still sticking to the soles of your boots.",
                    "What has already been carved into the stone. It's behind your back, but its shadow is long.",
                    "The ghosts that laid the foundation. They've finished their work, but they're still hanging about."
                },
                {
                    "The future position. The next bend in the glen, just before the path drops out of sight.",
                    "The immediate tomorrow. The rain clouds gathering over the ridge, heading straight for us.",
                    "What's drifting toward you on the wind. It's not destiny yet, just the next card to play.",
                    "The short horizon. A glimpse of where you're walking if you don't change your stride.",
                    "The coming weather. It's hovering on the edge of the cloth, waiting for its turn.",
                    "The next step. The ground isn't quite solid yet, but you're about to put your weight on it."
                },
                {
                    "The conscious position. What you tell yourself when you're trying to fall asleep at night.",
                    "The front of the mind. The little lantern you're holding up to the dark, hoping it's enough.",
                    "What you think you're looking for. The loud thoughts that drown out the quiet truths.",
                    "The high ground of the mind. Where you stand when you're pretending to have a plan.",
                    "The story you're currently spinning about yourself. Let's see how true it actually is.",
                    "What's sitting right behind your eyes. The bright, busy thoughts that keep you from looking down."
                },
                {
                    "The unconscious position. What's digging its nails into your back while you're looking somewhere else.",
                    "The deep peat. The stuff buried so far down you forgot it was there, but it's still feeding the soil.",
                    "The hidden driver. The ghost in the cellar that's actually steering the ship.",
                    "What's whispering beneath the floorboards. The truth you only look at when the fire goes out.",
                    "The heavy undercurrent. The silent part of the heart that makes your decisions before your mind can object.",
                    "The dark water. You can pretend it's a smooth surface, but we both know something is moving down there."
                },
                {
                    "Your influence position. The person you pretend to be when you walk into a crowded room.",
                    "The mirror. How you see your own reflection, and how much you blame it for the weather.",
                    "The shape of your own shadow. Are you making yourself smaller than you need to be?",
                    "The armor you've put on for this fight. Careful it isn't too heavy for you to move in.",
                    "What you bring to the table. Your own stubbornness, your own pride, and the specific way you hold your jaw.",
                    "How you handle your own power. Whether you're steering the cart or just dragging your heels in the dirt."
                },
                {
                    "The world outside. The folk talking behind your back or the wind trying to rip the thatch off your roof.",
                    "The external influence position. The stage you're standing on and the crowd that's watching you stumble.",
                    "What the tide washed up on your doorstep. You didn't ask for it, but it's sitting there anyway.",
                    "The neighborhood. The pressures and parameters other people have built around your life.",
                    "The elements pressing in through the cracks. The things you cannot control, no matter how loud you shout.",
                    "The social climate. A cold draft coming under the door, straight from someone else's house."
                },
                {
                    "The hopes and the fears, because humans are foolish enough to pray for the storm just to end the drought.",
                    "What keeps you shivering by the fire. The thing you secretly crave, and the thing that keeps you awake at 3 AM.",
                    "The paradox. Sometimes the thing we're most terrified of is the very thing we need to open the door.",
                    "A nervous look at the horizon. You're scanning the hills for a savior, or a monster. And you aren't sure which is worse.",
                    "The secret wish and the silent dread, tangled up together like old briars in a ditch.",
                    "The position where the heart cheats. You want to win, but a part of you just wants to lie down in the heather and give up."
                },
                {
                    "The outcome position. The place where all these muddy tracks finally converge at the top of the hill.",
                    "The final sum. Given the fire, the stone, and the rain... this is the crop you're likely to harvest.",
                    "The end of the staff. The quiet room at the end of a very long, loud day. Let's see what's waiting.",
                    "The ultimate resolution, the shape the clay takes when the wheel finally stops spinning.",
                    "Where the road drops you. It might not be where you wanted to go, but it's where your feet are heading.",
                    "The bottom line. The grand total of all your plans, your secrets, and your stumbles. Look close."
                }
            },
            closingLines = {
                "The grand cross is laid, and the staff is set. Press *B* to look upon the whole map once more, or *A* to roll up the cloth.",
                "Ten mirrors are staring at you. Press *B* to look back into them, or *A* to throw a sheet over them and go get some air.",
                "That's the whole story, cover to cover. Press *B* to flip through the pages again, or *A* to let the diary hold the weight now.",
                "The cards have run out of breath and so have I. Press *B* to study the wreckage, or *A* to let the ink dry in peace.",
                "The pattern is full. Press *B* to weigh the cross and the problem again, or *A* to walk out the door with what you know.",
                "A rare bit of digging, that. Press *B* to stare down into the trench once more, or *A* to put the spade down and shut the book.",
                "The ten points are settled. Press *B* to watch the shadows shift on the table, or *A* to blow out the light. Your call.",
                "You've got your map of the glen hazards and all. Press *B* to check the route again, or *A* to step back into the world."
            }
        }
    },
    horoscope = {
        positionNames = {
            "Card 1: Aries", "Card 2: Taurus", "Card 3: Gemini", "Card 4: Cancer", "Card 5: Leo", "Card 6: Virgo",
            "Card 7: Libra", "Card 8: Scorpio", "Card 9: Sagittarius", "Card 10: Capricorn", "Card 11: Aquarius", "Card 12: Pisces"
        },
        reading = {
            openingLines = {
                "Twelve cards. The whole bloody sky smashed down onto my little cloth. Sit back, this is going to take a while.",
                "(chuckles dryly, shuffling the full deck). Mapping the entire wheel, are we? Fine. Let's see which stars are doing the heavy lifting today.",
                "A full astrological excavation. Twelve houses, twelve locks to pick. Let's see what's rattling inside them.",
                "Twelve positions from Aries to the deep sea of Pisces. Don't look so nervous, darling, it's only the cosmos.",
                "The grand carousel. Twelve mirrors arranged in a circle to catch you from every single angle. Nowhere to hide now.",
                "(lays out the cards in a wide, sweeping circle). The great wheel turns, and here you are, stuck right in the middle of the machinery. Let's look.",
                "Twelve weights to balance. It's a heavy sky you're carrying on your shoulders today. Let's see where the pressure is.",
                "The full house. Your money, your secrets, your enemies, and your ego. All laid out like fish on a slab. Right, let's begin."
            },
            positionLines = {
                {
                    "The first house. Aries. This is the raw bone of who you are when you look in the mirror before anyone else wakes up.",
                    "The house of the self. Your immediate skin, your temper, and the face you put on when you're walking head-first into a gale.",
                    "Aries' corner. The ego, the spark, and the specific way you stomp into a room when you want to be noticed.",
                    "The first gate. Your identity. Not the polite version you tell your mother, but the actual beast driving the cart.",
                    "The self position. It's your physical frame, your immediate defenses, and the sheer stubbornness that keeps you standing.",
                    "Aries rules the head. This is your initial footprint in the mud, your baseline, and the weapon you use to cut through the noise."
                },
                {
                    "The second house. Taurus. This is your pocket, your pantry, and whether you've got enough coin to pay the ferryman.",
                    "The house of substance. What you actually own, what you cling to, and what you're willing to sweat for.",
                    "Taurus' corner. Your resources and your self-worth. Because it's hard to feel like a king when your boots are letting in water.",
                    "The second gate. Your relationship with gold, greed, and the simple comfort of having a solid floor beneath your feet.",
                    "The material world. This card shows what you hold in your fists, and whether you're hoarding it out of fear or using it to build.",
                    "Taurus rules the throat and the purse. It's how you feed yourself, how you earn your keep, and what you think you're actually worth."
                },
                {
                    "The third house. Gemini. The wagging tongues, the local gossip, and the noise inside your immediate neighborhood.",
                    "The house of the mind's daily hustle. How you speak your peace, or how you twist your words when you're cornered.",
                    "Gemini's corner. The short journeys you take every day, and the casual acquaintances you tolerate on the road.",
                    "The third gate. Your early learning, your siblings, and the basic cleverness you use to navigate the daily grind.",
                    "The immediate environment. This is the air you breathe every day and the routine chatter that fills your ears.",
                    "Mercury's domain. The letters in your drawer, the texts on your screen, and the specific way your brain processes facts."
                },
                {
                    "The fourth house. Cancer. The hearth, the history, and the old foundations under the floorboards of your house.",
                    "The house of roots. The people who made you, the blood in your veins, and the things you left behind in your childhood bedroom.",
                    "Cancer's corner. Your domestic life and your emotional safety, or the lack of it when the storm hits the roof.",
                    "The fourth gate. Where you go when you're bleeding and need to hide from the world for a wee while.",
                    "The private sanctuary. This card shows the shape of your nest, and whether it's a place of comfort or a cage of old habits.",
                    "The Moon's domain. It's your attachments, your family secrets, and the heavy emotional anchors that stop you from drifting away."
                },
                {
                    "The fifth house. Leo. This is your playground, your stage, and the specific way you make a fool of yourself when you fall in love.",
                    "The house of the spark. The things you give birth to, the art you create, and the risks you take just to feel alive.",
                    "Leo's corner. Pure romance and recreation, where you put down your heavy packages and just play for a wee while.",
                    "The fifth gate. Your inner theatre. It's how you shine, how you spend your luck, and what you do when the spotlight hits you.",
                    "The creative urge. This card shows the things you build out of nothing, and whether you're doing it for the joy or just for the applause.",
                    "The Sun's domain. Your inner child, your grand passions, and the reckless gambles of the heart that keep life from getting dull."
                },
                {
                    "The sixth house. Virgo. The daily grind, the dirty dishes, and the small, boring habits that keep your body from falling apart.",
                    "The house of service. The mundane work you do to pay the rent, and the specific way you handle your daily chores.",
                    "Virgo's corner. Your health and your responsibilities, the heavy maintenance required to keep the machine running.",
                    "The sixth gate. Your daily routine. It's not the glamorous stuff; it's the quiet, repetitive labor that keeps the roof over your head.",
                    "The workshop of the soul. This card shows how you handle the details, the micro-problems, and the folk who rely on your labor.",
                    "Mercury's practical side. Your physical well-being, your nervous system, and whether you're driving yourself to an early grave with worry."
                },
                {
                    "The seventh house. Libra. The person sitting right across the table from you. Whether they're holding your hand or a knife.",
                    "The house of the mirror. The commitments you make to other folk, and the specific way you compromise your own ground to keep them.",
                    "Libra's corner. Partnerships and open enemies. Because sometimes, the person you argue with the most is the one you're locked in with.",
                    "The seventh gate. The legal contracts, the marriages, and the public rivalries that define how you play with others.",
                    "The scales of relation. This card shows what you demand from a partner, and what kind of reflection you're constantly chasing in their eyes.",
                    "Venus's social contract. How you handle intimacy, shared weight, and the beautiful, messy business of not being alone in the world."
                },
                {
                    "The eighth house. Scorpio. The things we don't talk about in polite company: death, money, revolution, and raw desire.",
                    "The house of the deep current. What happens behind locked doors when the masks are off and the real bargaining begins.",
                    "Scorpio's own corner. The transformation house. It's about crisis, inheritance, and the specific way you burn your own house down just to rebuild it.",
                    "The eighth gate. Joint resources and shared debts. It shows what you owe to the dark, and what the dark owes to you.",
                    "The crucible. This card looks at the stuff that scares you; the power struggles, the secrets you guard, and the price of real intimacy.",
                    "Pluto's domain. It's the compost pile of the soul. The heavy, messy things that have to rot down before anything new can grow."
                },
                {
                    "The ninth house. Sagittarius. The long road, the big sky, and the miles you travel just to escape your own mind.",
                    "The house of the horizon. Your personal philosophy. The things you believe in when the world gets dark and cynical.",
                    "Sagittarius's corner. Higher learning, deep books, and the laws you live by when nobody else is looking.",
                    "The ninth gate. Adventure and expansion. It's about packing a heavy bag, crossing the border, and seeking something bigger than yourself.",
                    "The grand map. This card shows your appetite for the truth, and whether you're chasing wisdom or just running away from the facts.",
                    "Jupiter's domain. The luck you find when you take a gamble on a completely new perspective, far away from your comfort zone."
                },
                {
                    "The tenth house. Capricorn. The peak of the sky. This is your public face, your career, and the reputation you leave trailing behind you like a shadow.",
                    "The house of the climb. How you stand in the world, the authorities you clash with, and the legacy you're sweating to build.",
                    "Capricorn's corner. Your social responsibilities, the heavy coat you have to wear when the public is watching your every move.",
                    "The tenth gate. Your calling. Not just the job that pays the rent, but the actual mark you want to leave on the stones before you go.",
                    "The public eye. This card shows how the village views you, your successes, and whether you're climbing the mountain for yourself or just to prove them wrong.",
                    "Saturn's domain. Structure, status, and the cold hard discipline required to make something of yourself when the wind is blowing against you."
                },
                {
                    "The eleventh house. Aquarius. Your tribe, your allies, and the people you gather around the fire when you can't face the world alone.",
                    "The house of alliances. The network you weave, the folk who have your back, and the collective noise of your social life.",
                    "Aquarius's corner. Your hopes, your grandest dreams, and the ideals you hold onto when everything else is falling apart.",
                    "The eleventh gate. The community you choose to build. It's about finding your odd little crew in a world that doesn't understand you.",
                    "The social fabric. This card shows how you fit into the crowd, what you give to the collective, and what they expect from you in return.",
                    "Uranus's territory. The lightning strikes of inspiration, your vision for the future, and the unconventional plans you're hatching."
                },
                {
                    "The twelfth house. Pisces. The final room at the back of the house where you lock up everything you don't want the world to see.",
                    "The house of undoing. Your private vices, your hidden sorrows, and the specific way you trip over your own feet in the dark.",
                    "Pisces' corner. The deep fog of the subconscious. It's your dreams, your secrets, and the spiritual weight you carry when nobody is looking.",
                    "The final gate. The things that bring you undone. It's where you go to escape the noise, and where your own ghosts come out to play.",
                    "The hidden ledger. This card shows your blind spots, your private sacrifices, and the ancient karmic lessons you're still trying to clear.",
                    "Neptune's ocean. The place where all your boundaries dissolve. It's your intuition, your private grief, and the things you only confess to the wall."
                }
            },
            closingLines = {
                "The great wheel has spun its full turn. Press *B* to look over the twelve houses once more, or *A* to let the dust settle on the sky.",
                "Twelve mirrors, a perfect circle. Press *B* to stare back at your reflection from every angle, or *A* to pack away the glass.",
                "The whole circus is out on the table now. Press *B* to review the machinery from Aries to Pisces, or *A* to blow out the candles.",
                "That's the full map of your sky, corner to corner. Press *B* to recheck the hazards, or *A* to fold up the chart and walk away.",
                "The twelve houses are locked and loaded. Press *B* to look through the keyholes again, or *A* to step back into the street.",
                "The clock has struck twelve times. Press *B* to watch the shadows move on the wheel, or *A* to shut the book on this lifetime.",
                "The cosmic ledger is full. Press *B* to weigh your money, your secrets, and your stars again, or *A* to leave the counting house.",
                "The grand carousel has stopped spinning. Press *B* to ride the wheel one more time, or *A* to put your boots back on the solid earth."
            }
        }
    }
}

local function shuffledCopy(tbl)
    local copy = {}
    for index = 1, #tbl do
        copy[index] = tbl[index]
    end
    for index = #copy, 2, -1 do
        local swapIndex = math.random(index)
        copy[index], copy[swapIndex] = copy[swapIndex], copy[index]
    end
    return copy
end

local function pickRandomLine(lines)
    if type(lines) ~= "table" or #lines == 0 then
        return nil
    end

    return lines[math.random(#lines)]
end

SpreadReadingData = {}

function SpreadReadingData.normalizeSpreadKey(spreadKey)
    if type(spreadKey) ~= "string" then
        return "unknown"
    end

    return string.gsub(string.lower(spreadKey), "%-", "_")
end

function SpreadReadingData.getConfig(spreadKey)
    return SPREAD_CONFIGS[SpreadReadingData.normalizeSpreadKey(spreadKey)]
end

function SpreadReadingData.getSpreadDisplayName(spreadKey)
    if type(spreadKey) ~= "string" then
        return "Unknown Spread"
    end

    local normalized = SpreadReadingData.normalizeSpreadKey(spreadKey)

    return SPREAD_DISPLAY_NAMES[normalized] or spreadKey
end

function SpreadReadingData.pickKeywords(cardName, inverted, keywordCount)
    local count = keywordCount or 3
    local cardInfo = cardName and CARD_DATA[cardName] or nil
    if not cardInfo then
        return FALLBACK_KEYWORDS
    end

    local sourceKeywords = cardInfo.upright_keywords or {}
    if inverted and cardInfo.reversed_keywords and #cardInfo.reversed_keywords > 0 then
        sourceKeywords = cardInfo.reversed_keywords
    end

    if #sourceKeywords == 0 then
        return FALLBACK_KEYWORDS
    end

    if #sourceKeywords <= count then
        return sourceKeywords
    end

    local shuffled = shuffledCopy(sourceKeywords)
    local selectedKeywords = {}
    for index = 1, count do
        selectedKeywords[index] = shuffled[index]
    end

    return selectedKeywords
end

function SpreadReadingData.buildThemesForCards(cardNames, cardInverted)
    local themesByCard = {}
    local count = math.max(#(cardNames or {}), #(cardInverted or {}))

    for index = 1, count do
        local cardName = cardNames and cardNames[index] or "Unknown Card"
        local inverted = cardInverted and cardInverted[index] == true or false
        themesByCard[index] = SpreadReadingData.pickKeywords(cardName, inverted, 3)
    end

    return themesByCard
end

function SpreadReadingData.getSavedCardThemes(card)
    if type(card) ~= "table" or type(card.themes) ~= "table" or #card.themes == 0 then
        return nil
    end

    return card.themes
end

function SpreadReadingData.getPositionName(spreadKey, index)
    local config = SpreadReadingData.getConfig(spreadKey)
    if not config then
        return "Card " .. tostring(index)
    end

    return config.positionNames and config.positionNames[index] or ("Card " .. tostring(index))
end

function SpreadReadingData.buildCardDetails(spreadKey, cardNames, cardInverted)
    local details = {}
    local config = SPREAD_CONFIGS[spreadKey]
    local count = math.max(#(cardNames or {}), #(cardInverted or {}))

    for index = 1, count do
        local cardName = cardNames and cardNames[index] or "Unknown Card"
        local inverted = cardInverted and cardInverted[index] == true or false
        local positionName = SpreadReadingData.getPositionName(spreadKey, index)
        local themes = SpreadReadingData.pickKeywords(cardName, inverted, 3)
        local readingLines = { positionName }

        local readingConfig = config and config.reading or nil
        local positionLines = readingConfig and readingConfig.positionLines and readingConfig.positionLines[index] or nil
        local positionLine = pickRandomLine(positionLines)
        if positionLine then
            table.insert(readingLines, positionLine)
        end

        table.insert(readingLines, "Card pulled: " .. cardName .. (inverted and " (Reversed)" or ""))

        
        table.insert(readingLines, "Themes: " .. table.concat(themes, ", ") .. ".")

        table.insert(details, {
            position = index,
            positionLabel = positionName,
            cardName = cardName,
            inverted = inverted,
            themes = themes,
            readingLines = readingLines,
            readingText = table.concat(readingLines, "\n")
        })
    end

    return details
end

function SpreadReadingData.buildPlaceholderReadingSections(spreadKey, cardNames, cardInverted, themesByCard)
    local config = SPREAD_CONFIGS[spreadKey]
    if not config then
        return { { type = "unknown", lines = { "This spread has no reading data yet." } } }
    end

    local sections = {}
    local reading = config.reading

    -- If detailed reading table exists, build semantic sections
    if type(reading) == "table" and type(reading.positionLines) == "table" then
        -- Opening section (pick one opening line)
        local openingLine = pickRandomLine(reading.openingLines)
        if openingLine then
            table.insert(sections, { type = "opening", lines = { openingLine } })
        end

        -- Positions: break each position into smaller display sections so pages
        -- can show the position name, a sampled position line, the pulled card,
        -- keyword intro, and themes as separate sections.
        for index, positionLines in ipairs(reading.positionLines) do
            local positionName = config.positionNames and config.positionNames[index] or ("Card " .. tostring(index))
            local cardName = cardNames and cardNames[index] or "Unknown Card"
            local inverted = cardInverted and cardInverted[index] == true

            -- 1) Position name section
            table.insert(sections, { type = "position_name", index = index, lines = { positionName } })

            -- 2) Position flavour/sample line section (may be nil)
            local positionLine = pickRandomLine(positionLines)
            if positionLine then
                table.insert(sections, { type = "position_line", index = index, lines = { positionLine } })
            end

            -- 3) Card pulled section
            table.insert(sections, { type = "card_pulled", index = index, lines = { "Card pulled: " .. cardName .. (inverted and " (Reversed)" or "") } })

            -- 4) Keyword intro section
            table.insert(sections, { type = "keywordIntro", index = index, lines = { pickKeywordIntroLine() } })

            -- 5) Themes section
            local keywords = themesByCard and themesByCard[index] or SpreadReadingData.pickKeywords(cardName, inverted, 3)
            table.insert(sections, { type = "themes", index = index, lines = { table.concat(keywords, ", ") .. "." } })
        end

        -- Closing section (pick one closing line)
        local closingLine = pickRandomLine(reading.closingLines)
        if closingLine then
            table.insert(sections, { type = "closing", lines = { closingLine } })
        end

        return sections
    end

    -- Fallback simple spreads: treat opening lines, then a block per position, then closing
    local simpleSections = {}
    if type(config.openingLines) == "table" then
        table.insert(simpleSections, { type = "opening", lines = config.openingLines })
    end

    for index, positionName in ipairs(config.positionNames or {}) do
        local cardName = cardNames and cardNames[index] or "Unknown Card"
        local inverted = cardInverted and cardInverted[index] and " (Reversed)" or ""
        local cardInvertedFlag = cardInverted and cardInverted[index] == true or false
        local keywords = themesByCard and themesByCard[index] or SpreadReadingData.pickKeywords(cardName, cardInvertedFlag, 3)

        table.insert(simpleSections, { type = "position", index = index, lines = { positionName .. ": " .. cardName .. inverted } })
        table.insert(simpleSections, { type = "keywordIntro", index = index, lines = { pickKeywordIntroLine() } })
        table.insert(simpleSections, { type = "themes", index = index, lines = { table.concat(keywords, ", ") .. "." } })
    end

    if config.closingLine then
        table.insert(simpleSections, { type = "closing", lines = { config.closingLine } })
    end

    return simpleSections
end

function SpreadReadingData.buildPlaceholderReadingText(spreadKey, cardNames, cardInverted, themesByCard)
    -- Build a flattened list for legacy callers/diary persistence by using the
    -- section-aware builder and then concatenating the sections in order.
    local sections = SpreadReadingData.buildPlaceholderReadingSections(spreadKey, cardNames, cardInverted, themesByCard)
    local lines = {}
    for _, section in ipairs(sections) do
        for _, l in ipairs(section.lines or {}) do
            table.insert(lines, l)
        end
    end
    return lines
end
