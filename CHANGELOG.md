Armory has been released into the public domain on November 2007.
The project page can be found on https://www.curseforge.com/wow/addons/armory.

Thanks for using Armory. You can show your appreciation and support future development by donating!

## v20.0.0-beta3
- Fixes Armory being blamed for blocking the use of a bag item, which happened while item comparison was on. Armory's comparison with Alt now shows up next to the game's comparison instead of replacing it
- The guild bank is stored while you use it instead of when you close it, so Armory no longer interferes with closing the game's guild bank
- Armory no longer interferes with closing a profession window when it stores the complete professions (Classic Era and Burning Crusade Anniversary)

## v20.0.0-beta2
- The realm and faction filter are now two separate options, so you can show both factions on your realm or one faction on all realms
- The item counts in tooltips list your characters first, then your guild banks and then the Warband bank, and can be sorted by name or by count in the Tooltip options
- The Warband bank has its own color in the item counts, which can be set in the Tooltip options (Retail)
- The options of the inventory (bag layout, search all) are now in an Options menu next to the filter, with a new option to show your backpack and bags as one combined bag
- The tooltip of an equipment slot in the paper doll lists the item level of your other characters in that slot, for armor only those with the same armor type
- Fixes a stat of a scaling item showing up among the item counts in the tooltip of an equipment slot, mistaken for an engineering tinker (Retail)
- Fixes an error when logging in or reloading during a keystone, a PvP match or a boss encounter, when Armory joins its share channel (Retail)
- Fixes an error when logging in for the first time on a character that Armory doesn't know yet (Retail and WoW Forever)
- Fixes the check marks in the menu of Armory's icon disappearing while the menu is open

## v20.0.0-beta1
- One Armory for all versions of World of Warcraft: Retail, WoW Forever, Classic Era and Burning Crusade Anniversary now share one addon and one project page
- Shows the paper doll in the Classic Era layout with Forever's stats, the talents with both specs of dual spec, the skills, the happiness and loyalty of your pets (also in the stable), the PvP frame with the PvP rank and honor, the achievements and statistics, and the Legacy trees as a third tab of the achievements frame (WoW Forever)
- Characters are stored under their name and surname, so two of your characters with the same first name are kept apart (WoW Forever)
- Leaves your own realm out of the names in the mail and cooldown messages in the chat
- Fixes Alt-click search on chat links, the spellbook update, the server time and the guild roster request after Blizzard's API changes (Classic Era)
- Fixes the missing close function of the options panel, the UI scale reset, the color picker and an error in the tradeskill price source check (Burning Crusade Anniversary)
- Fixes an error when opening the options and the Defaults button of the options panel (Classic Era and Burning Crusade Anniversary)
- Fixes an error when guild members look up your data, and adds the option to share with your guild (Classic Era and Burning Crusade Anniversary)
- Fixes an error when the buff frame shows a debuff (Classic Era and Burning Crusade Anniversary)
- Fixes looking up First Aid recipes, which never found anything (Classic Era and Burning Crusade Anniversary)
- Jewelcrafting recipes can be looked up, as in Retail (Burning Crusade Anniversary)
- Fixes the time played message in the chat after logging in, which Armory requests for itself (Classic Era and Burning Crusade Anniversary)
- Fixes an error when checking the mailboxes for items that are about to expire (Classic Era and Burning Crusade Anniversary)
- Shift-click instead of Alt-click copies the name of a chat link into the search box of the inventory and the guild bank, as in Retail; Alt-click on a chat link is left for the search (Classic Era and Burning Crusade Anniversary)
- Alt-click copies the name of an item in your bags into the search box of the guild bank too, as in the inventory (Retail)
- The talent window shows the background of the spec behind the talent tree, and the class, hero and spec tabs in the order of Blizzard's talent window (Retail)
- Searching with /find runs in the background and stops when you close the window, as in Retail, and in Burning Crusade Anniversary it also searches the guild bank (Classic Era and Burning Crusade Anniversary)
- Mail warnings as in Retail: one message per mailbox, or one per item with the new option Detailed mail warnings, and a warning when a character has never opened the mailbox (Classic Era and Burning Crusade Anniversary)
- The total line of the item count in tooltips also shows how many are in the guild bank, as in Retail (Burning Crusade Anniversary)
- The inventory, quest log, spellbook, social, tradeskill, find and lookup windows have the same frame as the main window, as in Retail (Classic Era and Burning Crusade Anniversary)
- Drop-down menus look like Blizzard's menus, with check boxes and radio buttons, as in Retail (Classic Era and Burning Crusade Anniversary)
- Alt-click on Armory's icon shows the summary without delay, as in Retail (Classic Era and Burning Crusade Anniversary)
- Armory's logo is shown in the addon list (Classic Era and Burning Crusade Anniversary)
- Tooltips of profession spells show the profession ranks of your characters, as in Retail (Classic Era and Burning Crusade Anniversary)
- The colors of the tooltip lines can be set in the Tooltip options, as in Retail (Classic Era and Burning Crusade Anniversary)
- Hovering over a reputation bar shows the standing of all your characters with that faction, as in Retail (Classic Era and Burning Crusade Anniversary)
- Fixes the highlight of the selected faction disappearing after hovering over it (Classic Era and Burning Crusade Anniversary)
- Fixes the reputation required for a recipe, which showed Unknown when the faction was under a collapsed header in the reputation window
- Fixes the stored quest log becoming empty when the game had not loaded all quests yet, for example right after logging in
- Saving the reputation, currencies and quest log is retried at most three times in a row when the game has not loaded them completely yet
- A long title next to the character's name at the top of the main window uses a smaller font instead of being cut off right away
- The raid info shows the difficulty, lists expired locks at the bottom and shows the killed bosses when hovering over a lock, as in Retail (Classic Era and Burning Crusade Anniversary)
- Fixes an error when turning off the Raid module in the options (Classic Era and Burning Crusade Anniversary)
- The social window has the Events tab, with your calendar events, raid lockouts and tradeskill cooldowns, and warnings before they start, as in Retail (Classic Era and Burning Crusade Anniversary)
- Fixes an error when turning the Social module on or off in the options (Classic Era and Burning Crusade Anniversary)
- The summary has the columns item level, bags (with the free slots per bag) and events, and shows the difficulty and killed bosses of raid locks, as in Retail (Classic Era and Burning Crusade Anniversary)
- The money tooltips of the summary and the inventory include the money of your personal guild banks, as in Retail (Burning Crusade Anniversary)
- Corrects the stored bank contents when they no longer match what the game reports, for example after visiting the bank with Armory turned off, and marks those counts with a ~ until the bank is visited again, as in Retail (Classic Era and Burning Crusade Anniversary)
- The quest log has a Daily tab with the daily quests your characters completed in the past week, also shown in the summary, as in Retail (Burning Crusade Anniversary)
- Fixes an error when turning off the Quest Log module in the options (Classic Era and Burning Crusade Anniversary)
- Armory's windows open and close in combat and no longer push Blizzard's windows aside, as in Retail (Classic Era and Burning Crusade Anniversary)
- Fixes the command queue re-processing repeated updates, which could cause frame rate drops (e.g. during crafting) (Classic Era and Burning Crusade Anniversary)
- The talent window shows your unspent talent points, as in Burning Crusade Anniversary (Classic Era)
- Shift-click on a recipe in the tradeskill window links the item it makes, as in Retail (Classic Era and Burning Crusade Anniversary)
- Fixes Enchanting not being saved when Extended tradeskills is turned off (Classic Era and Burning Crusade Anniversary)
- Fixes the tradeskill filter Have materials, which ignored the materials in your inventory, and searching recipes by the name of a reagent (Classic Era and Burning Crusade Anniversary)
- Removes the support for Reagent Cost, which no longer worked (Classic Era and Burning Crusade Anniversary)
- Fixes the remaining time of items you mailed to your other characters, which was counted from their last visit to the mailbox instead of from the moment the item was sent (Classic Era and Burning Crusade Anniversary)
- Fixes the channel name in the Share options not being saved when no channel name was set before
- Fixes the pet selection, which switched to another stored pet instead of the summoned one (Retail)
- Fixes the location of an equipped bag in the results of /find, which showed Inventory instead of the bag (Retail)
- Removes the support for oGlow, EnhTooltip, ManyItemTooltips, LinkWrangler and GearScore (Retail)

## Earlier versions
Armory has been around since 2007. Until v20.0.0 every version of World of Warcraft had its own Armory:
- Retail up to v19.4.4, on https://www.curseforge.com/wow/addons/armory
- Classic Era up to v1.17.0, on https://www.curseforge.com/wow/addons/armory-classic
- Burning Crusade Classic and Anniversary up to v3.0.0, on https://www.curseforge.com/wow/addons/armory-bcc

The changes in those versions can be found with their files on these project pages.
