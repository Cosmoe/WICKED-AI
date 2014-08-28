if (isServer) then {

    private ["_pos_x","_pos_y","_pos_z","_aiskin","_unarmed","_current_time","_gain","_mission","_ainum","_aitype","_mission","_aipack","_aicskill","_position","_unitnumber","_skill","_gun","_mags","_backpack","_skin","_gear","_aiweapon","_aigear","_aiskin","_skillarray","_unitGroup","_weapon","_magazine","_weaponandmag","_gearmagazines","_geartools","_unit"];

	_position 			= _this select 0;
	_pos_x 			= _position select 0;
	_pos_y 			= _position select 1;
	_pos_z 			= _position select 2;
	_unitnumber 		= _this select 1;
	_skill 				= _this select 2;
	_gun 				= _this select 3;
	_mags 				= _this select 4;
	_backpack 			= _this select 5;
	_skin 				= _this select 6;
	_gear 				= _this select 7;
	_aitype				= _this select 8;
	
	if (typeName _aitype == "ARRAY") then {
		_gain 		= _aitype select 1;
		_aitype 	= _aitype select 0;
	};
	
	if (count _this > 9) then {
		_mission = _this select 9;
	} else {
		_mission = nil;
	};

	_aiweapon 			= [];
	_aigear 			= [];
	_aiskin 			= "";
	_aicskill 			= [];
	_aipack 			= "";
	_current_time		= time;
	_unarmed			= false;

	if(_aitype == "Hero") then {
		_unitGroup	= createGroup RESISTANCE;
	} else {
		_unitGroup	= createGroup EAST;
	};

	if(_pos_z == 0) then {
		if(floor(random 2) == 1) then { 
			_pos_x = _pos_x - (5 + random(20));
		} else {
			_pos_x = _pos_x + (5 + random(20));
		};			

		if(floor(random 2) == 1) then { 
			_pos_y = _pos_y - (5 + random(20));
		} else {
			_pos_y = _pos_y + (5 + random(20));
		};
	};

	for "_x" from 1 to _unitnumber do {

		switch (_gun) do {
			case 0 : {_aiweapon = ai_wep_assault;};
			case 1 : {_aiweapon = ai_wep_machine;};
			case 2 : {_aiweapon = ai_wep_sniper;};
			case "Unarmed" : {_unarmed = true;};
			case "Random" : {_aiweapon = ai_wep_random call BIS_fnc_selectRandom;};
		};

		if (!_unarmed) then {
			_weaponandmag 	= _aiweapon call BIS_fnc_selectRandom;
			_weapon 		= _weaponandmag select 0;
			_magazine 		= _weaponandmag select 1;
		};

		switch (_gear) do {
			case 0 : {_aigear = ai_gear0;};
			case 1 : {_aigear = ai_gear1;};
			case "Random" : {_aigear = ai_gear_random call BIS_fnc_selectRandom;};
		};
		
		_gearmagazines = _aigear select 0;
		_geartools = _aigear select 1;

		call {
			if (_skin == "Hero") 	exitWith { _aiskin = ai_hero_skin call BIS_fnc_selectRandom; };
			if (_skin == "Bandit") 	exitWith { _aiskin = ai_bandit_skin call BIS_fnc_selectRandom; };
			if (_skin == "Random") 	exitWith { _aiskin = ai_all_skin call BIS_fnc_selectRandom; };
			if (_skin == "Special") exitWith { _aiskin = ai_special_skin call BIS_fnc_selectRandom; };
			_aiskin = _skin;
		};

		_unit = _unitGroup createUnit [_aiskin,[_pos_x,_pos_y,_pos_z],[],10,"FORM"];
		[_unit] joinSilent _unitGroup;

		call {
			if (_aitype == "Hero") 		exitWith { _unit setVariable ["Hero",true]; _unit setVariable ["humanity", ai_remove_humanity]; };
			if (_aitype == "Bandit") 	exitWith { _unit setVariable ["Bandit",true]; _unit setVariable ["humanity", ai_add_humanity]; };
			if (_aitype == "Special") 	exitWith { _unit setVariable ["Special",true]; _unit setVariable ["humanity", ai_special_humanity]; };
		};
		if (!isNil "_gain") then { _unit setVariable ["humanity", _gain]; };

		call {
			if (_backpack == "Random") 	exitWith { _aipack = ai_packs call BIS_fnc_selectRandom; };
			if (_backpack == "None") 	exitWith { };
			_aipack = _backpack;
		};
		
		_unit enableAI "TARGET";
		_unit enableAI "AUTOTARGET";
		_unit enableAI "MOVE";
		_unit enableAI "ANIM";
		_unit enableAI "FSM";

		if(_aitype == "Hero") then {
			_unit setCombatMode ai_hero_combatmode;
			_unit setBehaviour ai_hero_behaviour;
		} else {
			_unit setCombatMode ai_bandit_combatmode;
			_unit setBehaviour ai_bandit_behaviour;
		};
		
		removeAllWeapons _unit;
		removeAllItems _unit;

		if (sunOrMoon != 1) then {
			_unit addweapon "NVGoggles";
		};

		if (!_unarmed) then {

			_unit addweapon _weapon;

			for "_i" from 1 to _mags do {
				_unit addMagazine _magazine;
			};
		};

		if(_aipack != "none") then {
			_unit addBackpack _aipack;
		};

		{
			_unit addMagazine _x
		} foreach _gearmagazines;

		{
			_unit addweapon _x
		} foreach _geartools;
		
		switch (_skill) do {
			case "easy"		: { _aicskill = ai_skill_easy; };
			case "medium" 	: { _aicskill = ai_skill_medium; };
			case "hard" 	: { _aicskill = ai_skill_hard; };
			case "extreme" 	: { _aicskill = ai_skill_extreme; };
			case "Random" 	: { _aicskill = ai_skill_random call BIS_fnc_selectRandom; };
			default { _aicskill = ai_skill_random call BIS_fnc_selectRandom; };
		};

		{
			_unit setSkill [(_x select 0),(_x select 1)]
		} foreach _aicskill;
		
		ai_ground_units = (ai_ground_units + 1);

		_unit addEventHandler ["Killed",{[_this select 0, _this select 1, "ground"] call on_kill;}];

		if (!isNil "_mission") then {
			_ainum = (wai_mission_data select _mission) select 0;
			wai_mission_data select _mission set [0, (_ainum + 1)];
			_unit setVariable ["missionclean", "ground"];
			_unit setVariable ["mission", _mission, true];
		};

	};

	if (wai_use_rpg && !unarmed) then {
		removeAllWeapons _unit;
		_unit addWeapon "RPG7V";
		_unit addMagazine "PG7V";
		_unit addMagazine "PG7V";
	};

	_unitGroup setFormation "ECH LEFT";
	_unitGroup selectLeader ((units _unitGroup) select 0);

	if(pos_z == 0) then {
		[_unitGroup,[_pos_x,_pos_y,_pos_z],_mission,_skill] spawn group_waypoints;
	};

	diag_log format ["WAI: Spawned a group of %1 AI (%3) at %2",_unitnumber,_position,_aitype];
	
	_unitGroup
};
