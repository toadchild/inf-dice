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

function set_ammo(player){
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
    set_ammo(player);
}

function set_unit(player){
    var faction_name = player + ".faction";
    var faction = document.getElementsByName(faction_name)[0].value;

    var unit_name = player + ".unit";
    var selected_unit = document.getElementsByName(unit_name)[0].value;

    // If they selected custom unit
    if(selected_unit == "Custom Unit"){
        enable_display(player + ".attributes");
        return;
    }else{
        disable_display(player + ".attributes");
    }

    var unit;
    for(var i = 0; i < units[faction].length; i++){
        if(units[faction][i]["name"] == selected_unit){
            unit = units[faction][i];
            break;
        }
    }

    // set all attributes from this unit
    if(unit){
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
        document.getElementsByName(player + ".ch")[0].value = unit["ch"];

        document.getElementsByName(player + ".nwi")[0].checked = unit["nwi"];
        document.getElementsByName(player + ".shasvastii")[0].checked = unit["shasvastii"];
    }
}

function set_faction(player, check_params){
    var faction_name = player + ".faction";
    var faction = document.getElementsByName(faction_name)[0].value;

    var unit_name = player + ".unit";
    var unit_list = document.getElementsByName(unit_name)[0];

    unit_list.options.length = 0;

    var type = "";
    var selected = false;

    for(var i = 0; i < units[faction].length; i++){
        var unit = units[faction][i];
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

    set_unit(player);
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
