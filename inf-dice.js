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
    if(action.value == "bs" || action.value == "cc" || action.value == "dtw"){
        ammo = document.getElementsByName(player + ".ammo")[0].value;
    }else{
        // Any case where we aren't attacking
        ammo = "None";
    }

    var dam_id = player + ".dam";

    if(ammo == "Smoke" || ammo == "None"){
        disable_input(dam_id);
    }else{
        enable_input(dam_id);
    }

    // Set B values based on selected weapon and ammo
    var weapon_name = document.getElementsByName(player + ".weapon")[0].value;
    var weapon = weapon_data[weapon_name];
    var b_list = document.getElementsByName(player + ".b")[0];

    // Get ammo type index so we can look up the corresponding B value
    var max_b = 5;
    if(weapon){
        for(var i = 0; i < weapon["ammo"].length; i++){
            if(ammo == weapon["ammo"][i]){
                max_b = weapon["b"][i];
                break;
            }
        }
    }

    // select a default B value
    var selected_b = 1;
    if(check_params && params[player + ".b"]){
        selected_b = params[player + ".b"];
    }else if(player == "p1" && action.value != "cc"){
        if(weapon){
            // Default to the highest burst for Player 1
            selected_b = max_b;
        }else{
            // Custom weapon inherits their prior selection
            selected_b = b_list.value;
        }
    }

    b_list.length = 0;
    for(var b = 1; b <= max_b; b++){
        b_list.options[b_list.options.length] = new Option(b);

        if(b == selected_b){
            b_list.options[b_list.options.length - 1].selected = true;
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

    if(action.value == "bs"){
        // weapon
        enable_input(player + ".b");
        enable_input(player + ".ammo");

        // modifiers
        enable_input(player + ".range");
        enable_input(player + ".link");
        enable_input(player + ".viz");
        disable_input(player + ".motorcycle");

        // cc modifiers
        disable_input(player + ".gang_up");
        disable_input(other + ".ikohl");
        set_berserk(player, other);

        // defensive abilities
        enable_input(other + ".cover");
        enable_input(other + ".ch");
        enable_input(other + ".odf");
        disable_input(player + ".hyperdynamics");

        // ability sections
        enable_display(player + ".sec_weapon");
        enable_display(player + ".sec_shoot");
        disable_display(player + ".sec_cc");
        disable_display(player + ".sec_hack");
        enable_display(other + ".sec_defense");
    }else if(action.value == "dtw"){
        // weapon
        enable_input(player + ".b");
        enable_input(player + ".ammo");

        // modifiers
        disable_input(player + ".range");
        enable_input(player + ".link");
        disable_input(player + ".viz");
        disable_input(player + ".motorcycle");

        // cc modifiers
        disable_input(player + ".gang_up");
        disable_input(other + ".ikohl");
        set_berserk(player, other);

        // defensive abilities
        enable_input(other + ".cover");
        disable_input(other + ".ch");
        disable_input(other + ".odf");
        disable_input(player + ".hyperdynamics");

        // ability sections
        enable_display(player + ".sec_weapon");
        enable_display(player + ".sec_shoot");
        disable_display(player + ".sec_cc");
        disable_display(player + ".sec_hack");
        enable_display(other + ".sec_defense");
    }else if(action.value == "cc"){
        // weapon
        disable_input(player + ".b");
        enable_input(player + ".ammo");

        // modifiers
        disable_input(player + ".range");
        disable_input(player + ".link");
        disable_input(player + ".viz");
        disable_input(player + ".motorcycle");

        // cc modifiers
        enable_input(player + ".gang_up");
        enable_input(other + ".ikohl");
        set_berserk(player, other);

        // defensive abilities
        disable_input(other + ".cover");
        disable_input(other + ".ch");
        disable_input(other + ".odf");
        disable_input(player + ".hyperdynamics");

        // ability sections
        enable_display(player + ".sec_weapon");
        disable_display(player + ".sec_shoot");
        enable_display(player + ".sec_cc");
        disable_display(player + ".sec_hack");
        disable_display(other + ".sec_defense");
    }else if(action.value == "dodge"){
        // weapon
        disable_input(player + ".b");
        disable_input(player + ".ammo");

        // modifiers
        disable_input(player + ".range");
        disable_input(player + ".link");
        disable_input(player + ".viz");
        enable_input(player + ".motorcycle");

        // cc modifiers
        enable_input(player + ".gang_up");
        disable_input(other + ".ikohl");
        set_berserk(player, other);

        // defensive abilities
        disable_input(other + ".cover");
        disable_input(other + ".ch");
        disable_input(other + ".odf");
        enable_input(player + ".hyperdynamics");

        // ability sections
        disable_display(player + ".sec_weapon");
        disable_display(player + ".sec_shoot");
        disable_display(player + ".sec_cc");
        disable_display(player + ".sec_hack");
        disable_display(other + ".sec_defense");
    }else if(action.value == "hack_imm" || action.value == "hack_ahp" || action.value == "hack_def" || action.value == "hack_pos"){
        // weapon
        disable_input(player + ".b");
        disable_input(player + ".ammo");

        // modifiers
        disable_input(player + ".range");
        disable_input(player + ".link");
        disable_input(player + ".viz");
        disable_input(player + ".motorcycle");

        // cc modifiers
        disable_input(player + ".gang_up");
        disable_input(other + ".ikohl");
        set_berserk(player, other);

        // defensive abilities
        disable_input(other + ".cover");
        disable_input(other + ".ch");
        disable_input(other + ".odf");
        disable_input(player + ".hyperdynamics");

        // ability sections
        disable_display(player + ".sec_weapon");
        disable_display(player + ".sec_shoot");
        disable_display(player + ".sec_cc");
        enable_display(player + ".sec_hack");
        disable_display(other + ".sec_defense");
    }else if(action.value == "none"){
        // weapon
        disable_input(player + ".b");
        disable_input(player + ".ammo");

        // modifiers
        disable_input(player + ".range");
        disable_input(player + ".link");
        disable_input(player + ".viz");
        disable_input(player + ".motorcycle");

        // cc modifiers
        disable_input(player + ".gang_up");
        disable_input(other + ".ikohl");
        set_berserk(player, other);

        // defensive abilities
        disable_input(other + ".cover");
        disable_input(other + ".ch");
        disable_input(other + ".odf");
        disable_input(player + ".hyperdynamics");

        // ability sections
        disable_display(player + ".sec_weapon");
        disable_display(player + ".sec_shoot");
        disable_display(player + ".sec_cc");
        disable_display(player + ".sec_hack");
        disable_display(other + ".sec_defense");
    }
    populate_weapons(player);
}

function set_weapon(player, check_params){
    // Set ammo types based on the selected weapon
    var stat_list = document.getElementsByName(player + ".stat")[0];
    var ammo_list = document.getElementsByName(player + ".ammo")[0];
    var dam_list = document.getElementsByName(player + ".dam")[0];
    var range_list = document.getElementsByName(player + ".range")[0];
    var weapon_name = document.getElementsByName(player + ".weapon")[0].value;
    var action = document.getElementsByName(player + ".action")[0].value;
    var weapon = weapon_data[weapon_name];

    // default selected values
    var selected_ammo = ammo_list.value;
    if(check_params){
        selected_ammo = params[player + ".ammo"];
    }
    var selected_damage = dam_list.value;
    if(check_params){
        selected_damage = params[player + ".dam"];
    }
    var selected_stat = stats.value;
    if(check_params){
        selected_stat = params[player + ".stat"];
    }
    var selected_range = range_list.value;
    if(check_params){
        selected_range = params[player + ".range"];
    }

    var my_ammo = ammos;
    var my_stat = stats;
    var my_dam = damages;
    var my_range = ranges;

    if(weapon){
        my_ammo = weapon["ammo"];
        my_stat = [weapon["stat"]];
        my_dam = [weapon["dam"]];
        my_range = weapon["ranges"];
    }

    // Ammo types
    ammo_list.length = 0;
    for(var i = 0; i < my_ammo.length; i++){
        ammo_list.options[i] = new Option(my_ammo[i]);

        if(my_ammo[i] == selected_ammo){
            ammo_list.options[i].selected = true;
        }
    }

    // Stat used
    stat_list.length = 0;
    if(action == "cc"){
        stat_list.options[0] = new Option("CC");
    }else if(action == "dtw" || action == "dodge"){
        stat_list.options[0] = new Option("--");
    }else{
        for(var i = 0; i < my_stat.length; i++){
            stat_list.options[i] = new Option(my_stat[i]);

            if(my_stat[i] == selected_stat){
                stat_list.options[i].selected = true;
            }
        }
    }

    // Damage
    dam_list.length = 0;
    for(var i = 0; i < my_dam.length; i++){
        dam_list.options[i] = new Option(my_dam[i]);

        if(dam_list.options[i].value == selected_damage){
            dam_list.options[i].selected = true;
        }
    }

    // Range bands
    range_list.length = 0;
    if(action == "bs"){
        var value_match = 1;
        for(var i = 0; i < my_range.length; i++){
            range_list.options[i] = new Option(my_range[i]);

            if(range_list.options[i].value == selected_range){
                range_list.options[i].selected = true;
                value_match = 0;
            }
        }

        // Match on modifier value if they don't match the range spec
        if(value_match){
            var slash_index = selected_range.lastIndexOf("/");
            var range_mod;
            if(slash_index == -1){
                range_mod = parseInt(selected_range, 10);
            }else{
                range_mod = parseInt(selected_range.substring(slash_index + 1), 10);
            }

            for(var i = 0; i < my_range.length; i++){
                slash_index = my_range[i].lastIndexOf("/");
                var cur_mod;
                if(slash_index == -1){
                    // Both are bare values
                    cur_mod = parseInt(my_range[i], 10);
                }else{
                    // Extract mod value
                    cur_mod = parseInt(my_range[i].substring(slash_index + 1), 10);
                }
                if(cur_mod == range_mod){
                    range_list.options[i].selected = true;
                    break;
                }
            }
        }
    }else{
        range_list[0] = new Option("--");
    }

    set_ammo(player, check_params);
}

function populate_weapons(player, check_params){
    var weapon_list = document.getElementsByName(player + ".weapon")[0];
    var action = document.getElementsByName(player + ".action")[0].value;
    var unit = get_unit_data(player);

    var attack_filter = "att_" + action;

    var selected_weapon = weapon_list.value;
    if(check_params){
        selected_weapon = params[player + ".weapon"];
    }

    var weapons;
    if(unit){
        weapons = unit.weapons;
    }else{
        weapons = Object.keys(weapon_data);
    }

    weapon_list.length = 0;

    for(var i = 0; i < weapons.length; i++){
        var weapon = weapon_data[weapons[i]];
        if(weapon && weapon[attack_filter]){
            weapon_list.options[weapon_list.options.length] = new Option(weapon["name"]);

            if(weapon["name"] == selected_weapon){
                weapon_list.options[weapon_list.options.length - 1].selected = true;
            }
        }
    }

    weapon_list.options[weapon_list.options.length] = new Option("--");
    weapon_list.options[weapon_list.options.length - 1].disabled = true;

    if(action == "bs" || action == "cc" || action == "dtw"){
        weapon_list.options[weapon_list.options.length] = new Option("Custom Weapon");

        if("Custom Weapon" == selected_weapon){
            weapon_list.options[weapon_list.options.length - 1].selected = true;
        }
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

function full_stat_dropdown(player, stat, min, max, check_params){
    var list = document.getElementsByName(player + "." + stat)[0];
    var selected = list.value;
    if(check_params){
        selected = params[player + "." + stat];
    }

    list.length = 0;

    for(var s = min; s <= max; s++){
        list.options[list.options.length] = new Option(s);

        if(s == selected){
            list.options[list.options.length - 1].selected = true;
        }
    }
}

function full_stat_dropdown_list(player, stat, stat_list, check_params){
    var list = document.getElementsByName(player + "." + stat)[0];
    var selected = list.value;
    if(check_params){
        selected = params[player + "." + stat];
    }

    list.length = 0;

    for(var s = 0; s < stat_list.length; s++){
        list.options[list.options.length] = new Option(stat_list[s]);

        if(stat_list[s] == selected){
            list.options[list.options.length - 1].selected = true;
        }
    }
}

function selected_stat_dropdown(player, stat, unit){
    var list = document.getElementsByName(player + "." + stat)[0];
    list.length = 0;

    list.options[0] = new Option(unit[stat]);
}

function set_w_taken(player, check_params, max_w_taken){
    var w_taken_list = document.getElementsByName(player + ".w_taken")[0];

    // wounds taken value
    var selected_w_taken = w_taken_list.value;
    if(check_params && params[player + ".w_taken"]){
        selected_w_taken = params[player + ".w_taken"];
    }

    w_taken_list.length = 0;
    for(var w_taken = 0; w_taken <= max_w_taken; w_taken++){
        w_taken_list.options[w_taken_list.options.length] = new Option(w_taken);

        if(w_taken == selected_w_taken){
            w_taken_list.options[w_taken_list.options.length - 1].selected = true;
        }
    }
}

function set_unit(player, check_params){
    var unit = get_unit_data(player);

    // set all attributes from this unit
    if(unit){
        disable_display(player + ".attributes");
        enable_display(player + ".skills");

        // stat block
        selected_stat_dropdown(player, "cc", unit);
        selected_stat_dropdown(player, "bs", unit);
        selected_stat_dropdown(player, "ph", unit);
        selected_stat_dropdown(player, "wip", unit);
        selected_stat_dropdown(player, "arm", unit);
        selected_stat_dropdown(player, "bts", unit);
        selected_stat_dropdown(player, "w", unit);
        selected_stat_dropdown(player, "w_type", unit);
        selected_stat_dropdown(player, "type", unit);

        // list of skills
        var skills = document.getElementById(player + ".statline_skills");
        skills.innerHTML = unit["spec"].join(", ");

        // wounds previously taken
        var max_w_taken = unit['w'] - 1;
        if(unit['nwi']){
            max_w_taken++;
        }
        set_w_taken(player, check_params, max_w_taken);

        // abilities
        document.getElementsByName(player + ".ikohl")[0].value = unit["ikohl"];
        document.getElementsByName(player + ".immunity")[0].value = unit["immunity"];
        document.getElementsByName(player + ".hyperdynamics")[0].value = unit["hyperdynamics"];
        document.getElementsByName(player + ".ch")[0].value = ch_mod(unit);
        document.getElementsByName(player + ".msv")[0].value = unit["msv"];
        document.getElementsByName(player + ".symbiont")[0].value = unit["symbiont"];
        document.getElementsByName(player + ".operator")[0].value = unit["operator"] || 0;
        document.getElementsByName(player + ".hacker")[0].value = unit["hacker"] || 0;

        document.getElementsByName(player + ".nwi")[0].checked = unit["nwi"];
        document.getElementsByName(player + ".shasvastii")[0].checked = unit["shasvastii"];
        document.getElementsByName(player + ".motorcycle")[0].checked = unit["motorcycle"];
    }else{
        // If they selected custom unit
        enable_display(player + ".attributes");
        disable_display(player + ".skills");

        // wounds previously taken
        set_w_taken(player, check_params, 3);

        // stat block
        full_stat_dropdown(player, "cc", 1, stat_max, check_params);
        full_stat_dropdown(player, "bs", 1, stat_max, check_params);
        full_stat_dropdown(player, "ph", 1, stat_max, check_params);
        full_stat_dropdown(player, "wip", 1, stat_max, check_params);
        full_stat_dropdown(player, "arm", 1, arm_max, check_params);
        full_stat_dropdown(player, "w", 1, w_max, 1, check_params);
        full_stat_dropdown_list(player, "bts", bts_list, check_params);
        full_stat_dropdown_list(player, "w_type", w_types, check_params);
        full_stat_dropdown_list(player, "type", unit_types, check_params);
    }

    populate_actions(player, check_params);
    populate_weapons(player, check_params);
}

function populate_actions(player, check_params){
    var action_list = document.getElementsByName(player + ".action")[0];
    var unit = get_unit_data(player);

    var selected_action = action_list.value;
    if(check_params){
        selected_action = params[player + ".action"];
    }

    action_list.length = 0;
    for(var a = 0; a < master_action_list.length; a++){
        action = master_action_list[a];

        if(action["filter"] && !action["filter"](unit)){
            continue;
        }

        action_list.options[action_list.options.length] = new Option(action["label"], action["value"]);

        if(action["value"] == selected_action){
            action_list.options[action_list.options.length - 1].selected = true;
        }
    }

    set_action(player);
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
        if(!selected && (!check_params || !params[player + ".unit"])){
            unit_list.options[unit_list.options.length - 1].selected = true;
            selected = true;
        }

        if(!selected && unit["name"] == params[player + ".unit"]){
            unit_list.options[unit_list.options.length - 1].selected = true;
            selected = true;
        }
    }

    unit_list.options[unit_list.options.length] = new Option("-- Custom");
    unit_list.options[unit_list.options.length - 1].disabled = true;
    unit_list.options[unit_list.options.length] = new Option("Custom Unit");

    if(!selected){
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

    set_faction("p1", true);
    set_faction("p2", true);
}

function raw_output(){
    toggle_display("raw_output");
}

function action_weapon_filter(unit, action){
    if(!unit){
        return 1;
    }

    var attack_filter = "att_" + action;

    for(var i = 0; i < unit.weapons.length; i++){
        var weapon = weapon_data[unit.weapons[i]];
        if(weapon && weapon[attack_filter]){
            return 1;
        }
    }

    return 0;
}

function action_bs_filter(unit){
    return action_weapon_filter(unit, "bs");
}

function action_cc_filter(unit){
    return action_weapon_filter(unit, "cc");
}

function action_dtw_filter(unit){
    return action_weapon_filter(unit, "dtw");
}

function action_hack_n_filter(unit, n){
    if(!unit){
        return 1;
    }

    if(unit["hacker"] >= n){
        return 1;
    }

    return 0;
}

function action_hack_1_filter(unit){
    return action_hack_n_filter(unit, 1);
}

function action_hack_2_filter(unit){
    return action_hack_n_filter(unit, 2);
}

var damages = ["PH-2", "PH", 10, 11, 12, 13, 14, 15];
var stats = ["BS", "PH", "WIP"];
var w_types = ["W", "STR"];
var unit_types = ["LI", "MI", "HI", "SK", "WB", "TAG", "REM"];
var bts_list = [0, -3, -6, -9];
var ranges = ["+3", "0", "-3", "-6"];
var stat_max = 22;
var arm_max = 10;
var w_max = 3;
var master_action_list = [
    { 
        "label": "Attack - Shoot",
        "value": "bs",
        "filter": action_bs_filter,
    },
    { 
        "label": "Attack - Direct Template Weapon",
        "value": "dtw",
        "filter": action_dtw_filter,
    },
    { 
        "label": "Attack - Close Combat",
        "value": "cc",
        "filter": action_cc_filter,
    },
    { 
        "label": "Dodge",
        "value": "dodge",
    },
    { 
        "label": "Hacking - Immobilize HI/REM/TAG",
        "value": "hack_imm",
        "filter": action_hack_2_filter,
    },
    { 
        "label": "Hacking - Possess TAG",
        "value": "hack_pos",
        "filter": action_hack_2_filter,
    },
    { 
        "label": "Hacking - Anti-Hacker Protocols",
        "value": "hack_ahp",
        "filter": action_hack_2_filter,
    },
    { 
        "label": "Hacking - Defensive Hacking",
        "value": "hack_def",
        "filter": action_hack_1_filter,
    },
    { 
        "label": "No Action",
        "value": "none",
    },
];
