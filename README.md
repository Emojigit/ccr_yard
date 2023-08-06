# C&C Rail Yard - Intergrated

These LuaATC codes controls a interlocking-based rail yard which serves multiple purposes:

1. To store and repair existing trains; or
2. To couple trains.

A example can be [downloaded](https://downloads-th2.1f616emo.xyz/advtrains_Lua_Yard.zip).

## Setting up

### 1. Set up the interlocking sections and signals

Each tracks in the yard MUST have one interlocking section. Signal of the yard entry point MUST be configured with two routes per track:

1. The normal one. It starts from the entry point to the end of the track's section. It MUST be named as `T<TrackID>`.
2. The shunting one. It starts form the entry point to the start of the track's section. It MUST be named as `T<TrackID>-SHUNT`.

All the routes in the signal of the yard entry point MUST NOT contain any ARS rules. The passive component name of the signal MUST be `<YardID>-EntrySig`.

Signals of track exit point MUST contain one route which MUST be named as `C` (stands for Continue). The passive component name of the signals MUST be `<YardID>-T<TrackID>`.

### 2. Configure the LuaATC environment

Copy the codes starting from `-- Yard code START --` to `-- Yard code END --` to your LuaATC environment. Also copy `F.has_rc` and `F.get_rc_safe` if they are not avaliable in your environment.

Check for the interlocking section IDs (which is an integer) of each tracks. Replace `F.YARD.YARDDATA["CcrY-CcF"]` with your own data:

1. The key of `F.YARD.YARDDATA`, `CcrY-CcF` MUST be replaced to a unique Yard ID. It will be used in all LuaATC components to refer to the yard.
2. In the table -
  1. For each track, the Track ID (`string`) MUST be the key, and the interlocking section iD (`number`) MUST be the value.
  2. `search_order` MUST be a number-indexed table in the order of empty slots searching. It SHOULD contain all the avaliable routes.
  3. `panel_pos` MAY contain the coordinate to the LuaATC Controller/Panel of the monitoring panel. It MUST be `nil` if the panel will not be used.

### 3. Set up LuaATC Tracks

Find a reasonable point for the entry LuaATC Track. Trains apart from those wanted to enter the yard MUST NOT circulate on that LuaATC Track. The LuaATC Track's arrow MUST be pointing at the direction of the yard. Copy and paste the contents of `track_entry.lua` into it, and change the `YardID` to your own.

For each of the tracks in the yards, place a LuaATC track in front of the signal influence point of its exit signal. Copy and paste the contents of `track_start.lua` to them, and change the `YardID` and `TrackID` to the appropriate ones.

Find a reasonable point for the leaving LuaATC Track. All trains leaving the yard MUST circulate on that LuaATC Track. Copy and paste the contents of `track_leaving.lua` to it, and change the `YardID` to your own.

## Usage

This system is operated by routing codes (RCs). The following RC(s) have functions:

1. `<YardID>-T<TrackID>`: Disable auto slot finding and set the train to be entering this track. This is REQUIRED for trains with `CcrOpt-AllowShunt` set.
2. `CcrOpt-AllowShunt`: Allows the train to go into tracks where other trains were there. This disables auto slot finding.
3. `CcrOpt-YardAutoCpl`: Couple with existing trains on the track. This will raise an warning if no other trains is on the track.
