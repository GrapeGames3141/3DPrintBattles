# Steam Achievements — PrintForge Legends

Create these in **Steamworks → Your App → Achievements**.  
The **API Name** must match the ID column exactly (case-sensitive).

| API Name | Display Name | Description |
|----------|--------------|-------------|
| `FIRST_WIN` | First Victory | Win your first battle. |
| `BATTLES_10` | Seasoned Fighter | Win 10 battles. |
| `BATTLES_50` | Battle Veteran | Win 50 battles. |
| `BATTLES_100` | Forge Champion | Win 100 battles. |
| `BEAT_FORGE_MASTER` | Forge Master Slayer | Defeat the Forge Master trainer. |
| `FIRST_BLUEPRINT` | First Blueprint | Purchase your first blueprint. |
| `FIRST_RARE` | Rare Find | Obtain a Rare blueprint. |
| `FIRST_EPIC` | Epic Discovery | Obtain an Epic blueprint. |
| `FIRST_LEGENDARY` | Legendary Haul | Obtain a Legendary blueprint. |
| `FIRST_PRINT` | Hot Off the Press | Print your first creature. |
| `COLLECTION_5` | Growing Collection | Own 5 printed creatures. |
| `COLLECTION_10` | Print Yard Full | Own 10 printed creatures. |
| `COLLECTION_15` | Complete Set | Own all 15 launch creatures. |
| `FIRST_EQUIPMENT` | Geared Up | Equip your first piece of gear. |
| `FULL_LOADOUT` | Fully Forged | Equip armor, weapon, and accessory on one print. |
| `FIRST_QUEST` | Academy Initiate | Complete your first Academy quest. |
| `THREE_STARS` | Star Student | Earn 3 stars on any Academy quest. |
| `ACADEMY_ALL` | Academy Graduate | Complete all five Academy quest types. |
| `LEVEL_5` | Spool Level 5 | Reach Spool Level 5. |
| `LEVEL_10` | Spool Level 10 | Reach Spool Level 10. |
| `LEVEL_20` | Master Printer | Reach Spool Level 20. |
| `FIRST_DROP` | Lucky Drop | Receive a blueprint from a battle drop. |
| `FORGEDEX_HALF` | Half the Forgedex | Discover 8 creatures in the Forgedex. |
| `FORGEDEX_FULL` | Forgedex Master | Discover all 15 launch creatures. |

Achievement hooks are wired in `SaveManager.gd`, `BattleManager.gd`, and `SteamManager.gd`.
