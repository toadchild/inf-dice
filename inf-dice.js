function disable_display(obj){
    var el = document.getElementById(obj);

    el.style.display = "none";
}

function enable_display(obj){
    var el = document.getElementById(obj);

    el.style.display = "";
}

function toggle_display(obj){
    var el = document.getElementById(obj);

    if(el.style.display == "none"){
        el.style.display = "";
    }else{
        el.style.display = "none";
    }
}

function _set_style_recursive(obj, styles){
    if("style" in obj){
        for(var i = 0; i < styles.length; i++){
            obj.style.setProperty(styles[i][0], styles[i][1]);
        }

        var children = obj.childNodes;

        for(var i = 0; i < children.length; i++){
            _set_style_recursive(children[i], styles);
        }
    }
}

function enable_input(id){
    var obj = document.getElementById(id);
    var styles = [
        ["color", "black"],
    ];

    _set_style_recursive(obj, styles);
}

function disable_input(id){
    var obj = document.getElementById(id);
    var styles = [
        ["color", "#555555"],
    ];

    _set_style_recursive(obj, styles);
}

function other_player(player){
    if(player == "p1"){
        return "p2";
    }else{
        return "p1";
    }
}

function set_ammo(player, check_params){
    var other = other_player(player);

    var action_name = player + ".action";
    var action = document.getElementsByName(action_name)[0];

    var ammo;
    if(action.value == "bs" || action.value == "cc" || action.value == "dtw" || action.value == "throw"){
        ammo = document.getElementsByName(player + ".ammo")[0].value;
    }else{
        // Any case where we aren't attacking
        ammo = "None";
    }

    var arm_id = other + ".arm";
    var bts_id = other + ".bts";
    var dam_id = player + ".dam";

    if(ammo == "Smoke" || ammo == "None"){
        disable_input(dam_id);
        disable_input(arm_id);
        disable_input(bts_id);
    }else if(ammo == "Monofilament" || ammo == "K1"){
        disable_input(dam_id);
        disable_input(arm_id);
        disable_input(bts_id);
    }else if(ammo == "Viral" || ammo == "E/M" || ammo == "E/M2" || ammo == "Nanotech"){
        enable_input(dam_id);
        enable_input(bts_id);
        disable_input(arm_id);
    }else{
        enable_input(dam_id);
        enable_input(arm_id);
        disable_input(bts_id);
    }

    // Set B values based on selected weapon and ammo
    var weapon_name = document.getElementsByName(player + ".weapon")[0].value;
    var weapon = weapon_data[weapon_name];
    // TODO there is another ammo lookup earlier in this function
    var ammo_name = document.getElementsByName(player + ".ammo")[0].value;
    var b_list = document.getElementsByName(player + ".b")[0];

    // Get ammo type index so we can look up the corresponding B value
    b_list.length = 0;
    if(weapon){
        for(var i = 0; i < weapon["ammo"].length; i++){
            if(ammo_name == weapon["ammo"][i]){
                for(var b = 1; b <= weapon["b"][i]; b++){
                    b_list.options[b_list.options.length] = new Option(b);

                    if(check_params && b == params[player + ".b"]){
                        b_list.options[b_list.options.length - 1].selected = true;
                    }
                }
                break;
            }
        }
    }else{
        // Custom Weapon
        for(var b = 1; b <= 5; b++){
            b_list.options[b_list.options.length] = new Option(b);

            if(check_params && b == params[player + ".b"]){
                b_list.options[b_list.options.length - 1].selected = true;
            }
        }
    }
}

// helper function for set_action
// berserk works in CC vs. CC, Dodge, or None
function set_berserk(player, other){
    var action_name = player + ".action";
    var action = document.getElementsByName(action_name)[0].value;
    var other_action_name = other + ".action";
    var other_action = document.getElementsByName(other_action_name)[0].value;

    if(action == "cc" && other_action == "cc"){
        enable_input(player + ".berserk");
        enable_input(other + ".berserk");
    }else if(action == "cc" && (other_action == "dodge" || other_action == "none")){
        enable_input(player + ".berserk");
        disable_input(other + ".berserk");
    }else if(other_action == "cc" && (action == "dodge" || action == "none")){
        disable_input(player + ".berserk");
        enable_input(other + ".berserk");
    }else{
        disable_input(player + ".berserk");
        disable_input(other + ".berserk");
    }
}

function set_action(player){
    var other = other_player(player);
    var action_name = player + ".action";
    var action = document.getElementsByName(action_name)[0];
    var other_action_name = other + ".action";
    var other_action = document.getElementsByName(other_action_name)[0];

    if(action.value == "bs" || action.value == "throw"){
        // stat block
        if(action.value == "bs"){
            enable_input(player + ".bs");
            disable_input(player + ".ph");
        }else if(action.value == "throw"){
            disable_input(player + ".bs");
            enable_input(player + ".ph");
        }
        disable_input(player + ".cc");
        disable_input(player + ".wip");
        enable_input(player + ".b");
        enable_input(player + ".ammo");

        // modifiers
        enable_input(player + ".range");
        enable_input(player + ".link");
        enable_input(player + ".viz");
        disable_input(player + ".dodge_unit");

        // cc modifiers
        disable_input(player + ".gang_up");
        disable_input(other + ".ikohl");
        set_berserk(player, other);

        // defensive abilities
        enable_input(other + ".cover");
        enable_input(other + ".ch");
        disable_input(player + ".hyperdynamics");
    }else if(action.value == "dtw"){
        // stat block
        disable_input(player + ".bs");
        disable_input(player + ".ph");
        disable_input(player + ".cc");
        disable_input(player + ".wip");
        enable_input(player + ".b");
        enable_input(player + ".ammo");

        // modifiers
        disable_input(player + ".range");
        enable_input(player + ".link");
        disable_input(player + ".viz");
        disable_input(player + ".dodge_unit");

        // cc modifiers
        disable_input(player + ".gang_up");
        disable_input(other + ".ikohl");
        set_berserk(player, other);

        // defensive abilities
        enable_input(other + ".cover");
        disable_input(other + ".ch");
        disable_input(player + ".hyperdynamics");
    }else if(action.value == "cc"){
        // stat block
        disable_input(player + ".bs");
        disable_input(player + ".ph");
        enable_input(player + ".cc");
        disable_input(player + ".wip");
        disable_input(player + ".b");
        enable_input(player + ".ammo");

        // modifiers
        disable_input(player + ".range");
        disable_input(player + ".link");
        disable_input(player + ".viz");
        disable_input(player + ".dodge_unit");

        // cc modifiers
        enable_input(player + ".gang_up");
        enable_input(other + ".ikohl");
        set_berserk(player, other);

        // defensive abilities
        disable_input(other + ".cover");
        disable_input(other + ".ch");
        disable_input(player + ".hyperdynamics");
    }else if(action.value == "dodge"){
        // stat block
        disable_input(player + ".bs");
        enable_input(player + ".ph");
        disable_input(player + ".cc");
        disable_input(player + ".wip");
        disable_input(player + ".b");
        disable_input(player + ".ammo");

        // modifiers
        disable_input(player + ".range");
        disable_input(player + ".link");
        disable_input(player + ".viz");
        enable_input(player + ".dodge_unit");

        // cc modifiers
        enable_input(player + ".gang_up");
        disable_input(other + ".ikohl");
        set_berserk(player, other);

        // defensive abilities
        disable_input(other + ".cover");
        disable_input(other + ".ch");
        enable_input(player + ".hyperdynamics");
    }else if(action.value == "none"){
        // stat block
        disable_input(player + ".bs");
        disable_input(player + ".ph");
        disable_input(player + ".cc");
        disable_input(player + ".wip");
        disable_input(player + ".b");
        disable_input(player + ".ammo");

        // modifiers
        disable_input(player + ".range");
        disable_input(player + ".link");
        disable_input(player + ".viz");
        disable_input(player + ".dodge_unit");

        // cc modifiers
        disable_input(player + ".gang_up");
        disable_input(other + ".ikohl");
        set_berserk(player, other);

        // defensive abilities
        disable_input(other + ".cover");
        disable_input(other + ".ch");
        disable_input(player + ".hyperdynamics");
    }
    populate_weapons(player);
}

function set_weapon(player, check_params){
    // Set ammo types based on the selected weapon
    var ammo_list = document.getElementsByName(player + ".ammo")[0];
    var dam_list = document.getElementsByName(player + ".dam")[0];
    var weapon_name = document.getElementsByName(player + ".weapon")[0].value;
    var weapon = weapon_data[weapon_name];

    if(weapon){
        // Ammo types
        ammo_list.length = 0;
        for(var i = 0; i < weapon["ammo"].length; i++){
            ammo_list.options[ammo_list.options.length] = new Option(weapon["ammo"][i]);

            if(check_params && weapon["ammo"][i] == params[player + ".ammo"]){
                ammo_list.options[ammo_list.options.length - 1].selected = true;
            }
        }

        dam_list.length = 0;
        dam_list.options[0] = new Option(weapon["dam"]);
    }else{
        // Custom weapon
        // set default values
        for(var i = 0; i < ammos.length; i++){
            ammo_list.options[ammo_list.options.length] = new Option(ammos[i]);

            if(check_params && ammos[i] == params[player + ".ammo"]){
                ammo_list.options[ammo_list.options.length - 1].selected = true;
            }
        }

        dam_list.length = 0;
        for(var i = 0; i < damages.length; i++){
            dam_list.options[dam_list.options.length] = new Option(damages[i]);

            if(check_params && dam_list.options[i].value == params[player + ".dam"]){
                dam_list.options[i].selected = true;
            }
        }
    }

    set_ammo(player, check_params);
}

function populate_weapons(player, check_params){
    var weapon_list = document.getElementsByName(player + ".weapon")[0];
    var action = document.getElementsByName(player + ".action")[0].value;
    var unit = get_unit_data(player);

    var attack_filter = "att_" + action;

    weapon_list.length = 0;

    if(unit){
        for(var i = 0; i < unit.weapons.length; i++){
            // TODO dual weaponry (2)
            var weapon = weapon_data[unit.weapons[i]];
            if(weapon && weapon[attack_filter]){
                weapon_list.options[weapon_list.options.length] = new Option(weapon["name"]);

                if(check_params && weapon["name"] == params[player + ".weapon"]){
                    weapon_list.options[weapon_list.options.length - 1].selected = true;
                }
            }
        }
    }

    weapon_list.options[weapon_list.options.length] = new Option("Custom Weapon");

    if(check_params && "Custom Weapon" == params[player + ".weapon"]){
        weapon_list.options[weapon_list.options.length - 1].selected = true;
    }

    set_weapon(player, check_params);
}

function get_unit_data(player){
    var faction_name = player + ".faction";
    var faction = document.getElementsByName(faction_name)[0].value;

    var unit_name = player + ".unit";
    var selected_unit = document.getElementsByName(unit_name)[0].value;

    for(var i = 0; i < unit_data[faction].length; i++){
        if(unit_data[faction][i]["name"] == selected_unit){
            return unit_data[faction][i];
        }
    }
}

function append_skill(skills, flag, name){
    if(flag){
        if(skills.innerHTML.length > 0){
            skills.innerHTML += ", ";
        }
        skills.innerHTML += name;
    }
}

function append_leveled_skill(skills, level, name){
    if(level){
        append_skill(skills, 1, name + " L " + level);
    }
}

function append_named_skill(skills, key, lookup){
    if(key){
        append_skill(skills, 1, lookup[key]);
    }
}

var immunity_names = {
    "bio": "Bioimmunity",
    "total": "Total Immunity",
    "shock": "Shock Immunity",
};

var ch_names = {
    1: "CH: Mimetism",
    2: "CH: Camouflage",
    3: "CH: TO Camo",
};

var odd_names = {
    1: "ODD",
    2: "ODF",
};

function ch_mod(unit){
    if(unit["ch"] == 1){
        return -3;
    }else if(unit["ch"] == 2){
        return -3;
    }else if(unit["ch"] == 3){
        return -6;
    }else if(unit["odd"]){
        return -6;
    }
    return 0;
}

function set_unit(player, check_params){
    var unit = get_unit_data(player);

    // set all attributes from this unit
    if(unit){
        disable_display(player + ".attributes");
        enable_display(player + ".statline");

        document.getElementsByName(player + ".bs")[0].value = unit["bs"];
        document.getElementsByName(player + ".ph")[0].value = unit["ph"];
        document.getElementsByName(player + ".cc")[0].value = unit["cc"];
        document.getElementsByName(player + ".wip")[0].value = unit["wip"];
        document.getElementsByName(player + ".arm")[0].value = unit["arm"];
        document.getElementsByName(player + ".bts")[0].value = unit["bts"];
        document.getElementsByName(player + ".w")[0].value = unit["w"];
        document.getElementsByName(player + ".w_type")[0].value = unit["w_type"];
        document.getElementsByName(player + ".ikohl")[0].value = unit["ikohl"];
        document.getElementsByName(player + ".immunity")[0].value = unit["immunity"];
        document.getElementsByName(player + ".hyperdynamics")[0].value = unit["hyperdynamics"];
        document.getElementsByName(player + ".dodge_unit")[0].value = unit["dodge_unit"];
        document.getElementsByName(player + ".ch")[0].value = ch_mod(unit);

        document.getElementsByName(player + ".nwi")[0].checked = unit["nwi"];
        document.getElementsByName(player + ".shasvastii")[0].checked = unit["shasvastii"];
        document.getElementsByName(player + ".msv")[0].value = unit["msv"];

        // Update the mini statline display
        document.getElementById(player + ".statline_type").innerHTML = unit["type"];
        document.getElementById(player + ".statline_cc").innerHTML = unit["cc"];
        document.getElementById(player + ".statline_bs").innerHTML = unit["bs"];
        document.getElementById(player + ".statline_ph").innerHTML = unit["ph"];
        document.getElementById(player + ".statline_wip").innerHTML = unit["wip"];
        document.getElementById(player + ".statline_arm").innerHTML = unit["arm"];
        document.getElementById(player + ".statline_bts").innerHTML = unit["bts"];
        document.getElementById(player + ".statline_w").innerHTML = unit["w"];
        document.getElementById(player + ".statline_w_type").innerHTML = unit["w_type"];

        // list of skills
        var skills = document.getElementById(player + ".statline_skills");
        skills.innerHTML = "";
        append_leveled_skill(skills, unit["ikohl"] / -3, "I-Kohl");
        append_leveled_skill(skills, unit["hyperdynamics"] / 3, "Hyperdynamics");
        append_leveled_skill(skills, unit["msv"], "Multispectral Visor");
        append_skill(skills, unit["nwi"], "V: No Wound Incapacitation");
        append_skill(skills, unit["shasvastii"], "Shasvastii");
        append_named_skill(skills, unit["immunity"], immunity_names);
        append_named_skill(skills, unit["ch"], ch_names);
        append_named_skill(skills, unit["odd"], odd_names);
    }else{
        // If they selected custom unit
        enable_display(player + ".attributes");
        disable_display(player + ".statline");
    }

    populate_weapons(player, check_params);
}

function set_faction(player, check_params){
    var faction_name = player + ".faction";
    var faction = document.getElementsByName(faction_name)[0].value;

    var unit_name = player + ".unit";
    var unit_list = document.getElementsByName(unit_name)[0];

    unit_list.options.length = 0;

    var type = "";
    var selected = false;

    for(var i = 0; i < unit_data[faction].length; i++){
        var unit = unit_data[faction][i];
        if(type != unit["type"]){
            type = unit["type"];
            unit_list.options[unit_list.options.length] = new Option("-- " + type);
            unit_list.options[unit_list.options.length - 1].disabled = true;
        }

        unit_list.options[unit_list.options.length] = new Option(unit["name"]);
        if(!selected){
            unit_list.options[unit_list.options.length - 1].selected = true;
            selected = true;
        }

        if(check_params && unit["name"] == params[player + ".unit"]){
            unit_list.options[unit_list.options.length - 1].selected = true;
        }
    }

    unit_list.options[unit_list.options.length] = new Option("-- Custom");
    unit_list.options[unit_list.options.length - 1].disabled = true;
    unit_list.options[unit_list.options.length] = new Option("Custom Unit");

    if(check_params && "Custom Unit" == params[player + ".unit"]){
        unit_list.options[unit_list.options.length - 1].selected = true;
    }

    set_unit(player, check_params);
}

var params = {};
function parse_params(){
    var query = document.location.search;
    query = query.split("+").join(" ");

    var tokens, re = /[?&]?([^=]+)=([^&]*)/g;

    while (tokens = re.exec(query)) {
        params[decodeURIComponent(tokens[1])] = decodeURIComponent(tokens[2]);
    }
}

function init_on_load(){
    parse_params();

    set_action("p1");
    set_action("p2");

    set_faction("p1", true);
    set_faction("p2", true);
}

function raw_output(){
    toggle_display("raw_output");
}

// TODO need a good way to keep this in sync with perl
var damages = ['PH-2', 'PH', 10, 11, 12, 13, 14, 15];

