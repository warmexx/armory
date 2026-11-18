-- New English strings for the CurseForge localization of Armory (project 5195, namespace Armory),
-- not yet imported there. Import them as enUS phrases before building a release; remove a line
-- here once CurseForge has it.
-- dev/install.py adds the lines whose key is missing to the installed Locales\enUS.lua, so they
-- can be tested before the import.

L["ARMORY_CMD_SET_USEREALMFILTER_TEXT"] = "enable realm filter"
L["ARMORY_CMD_SET_USEREALMFILTER_MENUTEXT"] = "Realm filter"
L["ARMORY_CMD_SET_USEREALMFILTER_TOOLTIP"] = [=[If enabled, only characters on the current and connected realms will be shown. This will also affect tooltip information.
Note that for item counts there is a separate realm setting.]=]
L["ARMORY_CMD_SET_FACTIONFILTER_TEXT"] = "enable faction filter"
L["ARMORY_CMD_SET_FACTIONFILTER_MENUTEXT"] = "Faction filter"
L["ARMORY_CMD_SET_FACTIONFILTER_TOOLTIP"] = [=[If enabled, only characters belonging to the current faction will be shown. This will also affect tooltip information.
Note that for item counts there is a separate faction setting.]=]
L["ARMORY_CMD_SET_COUNTSORT_TEXT"] = "sort item counts"
L["ARMORY_CMD_SET_COUNTSORT_TOOLTIP"] = "Sets the order of the item counts in tooltips. Characters first lists your characters, then your guild banks and then the Warband bank."
L["ARMORY_ITEMCOUNT_SORT_TYPE"] = "Characters first"
L["ARMORY_ITEMCOUNT_SORT_NAME"] = "By name"
L["ARMORY_ITEMCOUNT_SORT_COUNT"] = "Most first"
L["ARMORY_ITEMCOUNT_SORT_COUNTASC"] = "Fewest first"
-- Only used in Classic; Retail and Forever use Blizzard's COMBINED_BAG_TITLE
L["ARMORY_INVENTORY_COMBINEDBAG"] = "Combined Backpack"
L["ARMORY_CMD_SET_SHOWSLOTITEMLEVELS_TEXT"] = "show item level of other characters in slot tooltips"
L["ARMORY_CMD_SET_SHOWSLOTITEMLEVELS_MENUTEXT"] = "Show item level of other characters"
L["ARMORY_CMD_SET_SHOWSLOTITEMLEVELS_TOOLTIP"] = "If enabled, the tooltip of an equipment slot in the paper doll lists the item level of your other characters in that slot. Armor slots only list characters that wear the same armor type."
L["ARMORY_SLOT_ITEMLEVELS"] = "Item level of your other characters"
