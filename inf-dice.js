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
        ["color", "#2c3c44"],
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
    var action = document.getElementsByName(action_name)[0].value;

    var ammo;
    if(action == "bs" || action == "cc" || action == "dtw" || action == "deploy" || action == "spec" || action == "supp"){
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
    if(action == "supp"){
        max_b = 3;
    }else{
        if(weapon){
            for(var i = 0; i < weapon["ammo"].length; i++){
                if(ammo == weapon["ammo"][i]){
                    max_b = weapon["b"][i];
                    break;
                }
            }
        }
    }

    // select a default B value
    var selected_b = 1;
    if(check_params && params[player + ".b"]){
        selected_b = params[player + ".b"];
    }else if(action == "supp"){
        selected_b = 3;
    }else if(player == "p1" && action != "cc"){
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

    // Set template flag based on ammo type
    var template_box = document.getElementsByName(player + ".template")[0];
    var template = template_box.checked;;

    if(check_params && params[player + ".template"]){
        template = params[player + ".template"];
    }else{
        if(weapon){
            for(var i = 0; i < weapon["ammo"].length; i++){
                if(ammo == weapon["ammo"][i]){
                    template = weapon["template"][i];
                    break;
                }
            }
        }
    }

    template_box.checked = template;
}

function set_sapper_foxhole(){
    var action_1 = document.getElementsByName("p1.action")[0].value;
    var action_2 = document.getElementsByName("p2.action")[0].value;

    var sapper_1 = document.getElementsByName("p1.sapper")[0].checked;
    var sapper_2 = document.getElementsByName("p2.sapper")[0].checked;

    if(sapper_1 && (action_2 == "bs" || action_2 == "spec" || action_2 == "supp")){
        enable_input("p1.foxhole");
    }else{
        disable_input("p1.foxhole");
    }

    if(sapper_2 && (action_1 == "bs" || action_1 == "spec" || action_1 == "supp")){
        enable_input("p2.foxhole");
    }else{
        disable_input("p2.foxhole");
    }
}

function set_berserk(){
    var action_1 = document.getElementsByName("p1.action")[0].value;
    var action_2 = document.getElementsByName("p2.action")[0].value;

    var berserk_1 = document.getElementsByName("p1.has_berserk")[0].checked;
    var berserk_2 = document.getElementsByName("p2.has_berserk")[0].checked;

    if(berserk_1 && action_1 == "cc"){
        enable_input("p1.berserk");
    }else{
        disable_input("p1.berserk");
    }

    if(berserk_2 && action_2 == "cc"){
        enable_input("p2.berserk");
    }else{
        disable_input("p2.berserk");
    }
}

function set_action(player){
    var other = other_player(player);
    var action_name = player + ".action";
    var action = document.getElementsByName(action_name)[0];
    var other_action_name = other + ".action";
    var other_action = document.getElementsByName(other_action_name)[0];

    if(action.value == "bs" || action.value == "supp"){
        // action
        disable_display(player + ".intuitive");

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

        // defensive abilities
        enable_input(other + ".cover");
        disable_input(other + ".firewall");
        enable_input(other + ".ch");
        disable_input(player + ".hyperdynamics");

        // ability sections
        enable_display(player + ".sec_weapon");
        enable_display(player + ".sec_shoot");
        disable_display(player + ".sec_cc");
        disable_display(player + ".sec_hack");
        enable_display(other + ".sec_defense");
        enable_display(player + ".sec_other");
    }else if(action.value == "spec"){
        // action
        disable_display(player + ".intuitive");

        // weapon
        enable_input(player + ".b");
        enable_input(player + ".ammo");

        // modifiers
        enable_input(player + ".range");
        disable_input(player + ".link");
        disable_input(player + ".viz");
        disable_input(player + ".motorcycle");

        // cc modifiers
        disable_input(player + ".gang_up");
        disable_input(other + ".ikohl");

        // defensive abilities
        enable_input(other + ".cover");
        disable_input(other + ".firewall");
        disable_input(other + ".ch");
        disable_input(player + ".hyperdynamics");

        // ability sections
        enable_display(player + ".sec_weapon");
        enable_display(player + ".sec_shoot");
        disable_display(player + ".sec_cc");
        disable_display(player + ".sec_hack");
        enable_display(other + ".sec_defense");
        enable_display(player + ".sec_other");
    }else if(action.value == "dtw"){
        // action
        enable_display(player + ".intuitive");

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

        // defensive abilities
        disable_input(other + ".cover");
        disable_input(other + ".firewall");
        disable_input(other + ".ch");
        disable_input(player + ".hyperdynamics");

        // ability sections
        enable_display(player + ".sec_weapon");
        enable_display(player + ".sec_shoot");
        disable_display(player + ".sec_cc");
        disable_display(player + ".sec_hack");
        enable_display(other + ".sec_defense");
        disable_display(player + ".sec_other");
    }else if(action.value == "deploy"){
        // action
        disable_display(player + ".intuitive");

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

        // defensive abilities
        disable_input(other + ".cover");
        disable_input(other + ".firewall");
        disable_input(other + ".ch");
        disable_input(player + ".hyperdynamics");

        // ability sections
        enable_display(player + ".sec_weapon");
        enable_display(player + ".sec_shoot");
        disable_display(player + ".sec_cc");
        disable_display(player + ".sec_hack");
        enable_display(other + ".sec_defense");
        disable_display(player + ".sec_other");
    }else if(action.value == "cc"){
        // action
        disable_display(player + ".intuitive");

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

        // defensive abilities
        disable_input(other + ".cover");
        disable_input(other + ".firewall");
        disable_input(other + ".ch");
        disable_input(player + ".hyperdynamics");

        // ability sections
        enable_display(player + ".sec_weapon");
        disable_display(player + ".sec_shoot");
        enable_display(player + ".sec_cc");
        disable_display(player + ".sec_hack");
        disable_display(other + ".sec_defense");
        enable_display(player + ".sec_other");
    }else if(action.value == "dodge" || action.value == "change_face"){
        // action
        disable_display(player + ".intuitive");

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

        // defensive abilities
        disable_input(other + ".cover");
        disable_input(other + ".firewall");
        disable_input(other + ".ch");
        enable_input(player + ".hyperdynamics");

        // ability sections
        disable_display(player + ".sec_weapon");
        disable_display(player + ".sec_shoot");
        disable_display(player + ".sec_cc");
        disable_display(player + ".sec_hack");
        disable_display(other + ".sec_defense");
        enable_display(player + ".sec_other");
    }else if(action.value == "reset"){
        // action
        disable_display(player + ".intuitive");

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

        // defensive abilities
        disable_input(other + ".cover");
        enable_input(other + ".firewall");
        disable_input(other + ".ch");
        disable_input(player + ".hyperdynamics");

        // ability sections
        disable_display(player + ".sec_weapon");
        disable_display(player + ".sec_shoot");
        disable_display(player + ".sec_cc");
        disable_display(player + ".sec_hack");
        enable_display(other + ".sec_defense");
        enable_display(player + ".sec_other");
    }else if(action.value == "hack"){
        // action
        disable_display(player + ".intuitive");

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

        // defensive abilities
        disable_input(other + ".cover");
        enable_input(other + ".firewall");
        disable_input(other + ".ch");
        disable_input(player + ".hyperdynamics");

        // ability sections
        disable_display(player + ".sec_weapon");
        disable_display(player + ".sec_shoot");
        disable_display(player + ".sec_cc");
        enable_display(player + ".sec_hack");
        enable_display(other + ".sec_defense");
        enable_display(player + ".sec_other");
    }else if(action.value == "none"){
        // action
        disable_display(player + ".intuitive");

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

        // defensive abilities
        disable_input(other + ".cover");
        disable_input(other + ".firewall");
        disable_input(other + ".ch");
        disable_input(player + ".hyperdynamics");

        // ability sections
        disable_display(player + ".sec_weapon");
        disable_display(player + ".sec_shoot");
        disable_display(player + ".sec_cc");
        disable_display(player + ".sec_hack");
        disable_display(other + ".sec_defense");
        disable_display(player + ".sec_other");
    }

    set_sapper_foxhole();
    set_berserk();

    populate_weapons(player);
}

function set_xvisor(player){
    set_weapon(player, false);
}

function set_weapon(player, check_params){
    // Set ammo types based on the selected weapon
    var stat_list = document.getElementsByName(player + ".stat")[0];
    var ammo_list = document.getElementsByName(player + ".ammo")[0];
    var dam_list = document.getElementsByName(player + ".dam")[0];
    var range_list = document.getElementsByName(player + ".range")[0];
    var weapon_name = document.getElementsByName(player + ".weapon")[0].value;
    var action = document.getElementsByName(player + ".action")[0].value;
    var xvisor = document.getElementsByName(player + ".xvisor")[0].value;
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

    if(action == "supp"){
        my_range = supp_ranges;
    }

    // Ammo types
    ammo_list.length = 0;
    for(var i = 0; i < my_ammo.length; i++){
        if(action == "supp"){
            // Skip ammos with B < 3
            if(weapon && weapon["b"][i] < 3){
                continue;
            }
        }
        ammo_list.options[i] = new Option(my_ammo[i]);

        if(my_ammo[i] == selected_ammo){
            ammo_list.options[i].selected = true;
        }
    }

    // Stat used
    stat_list.length = 0;
    if(action == "cc"){
        stat_list.options[0] = new Option("CC");
    }else if(action == "dtw" || action == "deploy" || action == "dodge" || action == "change_face"){
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
    if(action == "bs" || action == "spec" || action == "supp"){
        var value_match = 1;
        for(var i = 0; i < my_range.length; i++){
            // X Visor sets mod of -3 to 0 and -6 to -3
            // X-2 Visor sets both -3 and -6 to 0
            if(weapon && xvisor == 1){
                var r = my_range[i];
                var slash_index = r.lastIndexOf("/");
                var mod = r.substring(slash_index + 1);
                if(mod == "-3"){
                    r = r.substring(0, slash_index) + "/0";
                }else if(mod == "-6"){
                    r = r.substring(0, slash_index) + "/-3";
                }
                range_list.options[i] = new Option(r);
            }else if(weapon && xvisor == 2){
                var r = my_range[i];
                var slash_index = r.lastIndexOf("/");
                var mod = r.substring(slash_index + 1);
                if(mod == "-3" || mod == "-6"){
                    r = r.substring(0, slash_index) + "/0";
                }
                range_list.options[i] = new Option(r);
            }else{
                range_list.options[i] = new Option(my_range[i]);
            }

            if(range_list.options[i].value == selected_range){
                range_list.options[i].selected = true;
                value_match = 0;
            }
        }

        // Match on modifier value if they don't match the range spec
        if(value_match && selected_range){
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
        while(weapon){
            if(weapon[attack_filter]){
                weapon_list.options[weapon_list.options.length] = new Option(weapon["display_name"], weapon["name"]);

                if(weapon["name"] == selected_weapon){
                    weapon_list.options[weapon_list.options.length - 1].selected = true;
                }
            }

            // Next profile for multi-profile weapons
            if(weapon["alt_profile"]){
                weapon = weapon_data[weapon["alt_profile"]];
            }else{
                weapon = undefined;
            }
        }
    }

    weapon_list.options[weapon_list.options.length] = new Option("--");
    weapon_list.options[weapon_list.options.length - 1].disabled = true;

    if(action == "bs" || action == "cc" || action == "dtw" || action == "deploy" || action == "spec" || action == "supp"){
        weapon_list.options[weapon_list.options.length] = new Option("Custom Weapon");

        if("Custom Weapon" == selected_weapon){
            weapon_list.options[weapon_list.options.length - 1].selected = true;
        }
    }

    set_weapon(player, check_params);
}

function populate_ma(player, check_params){
    var ma_list = document.getElementsByName(player + ".ma")[0];
    var unit = get_unit_data(player);

    var selected_ma = ma_list.value;
    if(check_params){
        selected_ma = params[player + ".ma"];
    }

    var ma_max = 5;
    if(unit){
        ma_max = unit["ma"] || 0;
    }

    ma_list.length = 0;

    for(var i = 0; i <= ma_max; i++){
        ma_list.options[i] = new Option(ma_labels[i], i);

        if(i == selected_ma){
            ma_list.options[i].selected = true;
        }
    }
}

function set_hacker(player, check_params){
    var program_list = document.getElementsByName(player + ".hack_program")[0];
    var hacker_level = document.getElementsByName(player + ".hacker")[0].value;
    var unit = get_unit_data(player);

    var selected_program = program_list.value;
    if(check_params){
        selected_program = params[player + ".hack_program"];
    }

    var master_programs = [];
    master_programs = get_hacking_programs(hacker_level);

    program_list.length = 0;

    for(var i = 0; i < master_programs.length; i++){
        // Skip unimplmented programs
        if(hacking_burst[master_programs[i]["program"]]){
            program_list.options[program_list.length] = new Option(master_programs[i]["group"] + ": " + master_programs[i]["program"], master_programs[i]["program"]);

            if(master_programs[i]["program"] == selected_program){
                program_list.options[program_list.length - 1].selected = true;
            }
        }
    }

    set_hack_program(player, check_params);
}

function set_hack_program(player, check_params){
    // Set b value for hack attack
    var program = document.getElementsByName(player + ".hack_program")[0].value;
    var max_b = hacking_burst[program];
    var b_list = document.getElementsByName(player + ".hack_b")[0];

    // select a default B value
    var selected_b = 1;
    if(check_params && params[player + ".hack_b"]){
        selected_b = params[player + ".hack_b"];
    }else if(player == "p1"){
        // Default to the highest burst for Player 1
        selected_b = max_b;
    }

    b_list.length = 0;
    for(var b = 1; b <= max_b; b++){
        b_list.options[b_list.options.length] = new Option(b);

        if(b == selected_b){
            b_list.options[b_list.options.length - 1].selected = true;
        }
    }
}

function get_hacking_programs(hd_level){
    var programs = [];
    var hd_data;

    if(hd_level == 1){
        hd_data = hacking_devices["Defensive Hacking Device"];
    }else if(hd_level == 2){
        hd_data = hacking_devices["Hacking Device"];
    }else if(hd_level == 3){
        hd_data = hacking_devices["Hacking Device Plus"];
    }else if(hd_level == 4){
        hd_data = hacking_devices["Assault Hacking Device"];
    }else if(hd_level == 5){
        hd_data = hacking_devices["EI Assault Hacking Device"];
    }else if(hd_level == 6){
        hd_data = hacking_devices["EI Hacking Device"];
    }else if(hd_level == 7){
        hd_data = hacking_devices["Hacking Device: UPGRADE: Stop!"];
    }

    if(hd_data){
        // Get each program from each group
        for(var i = 0; i < hd_data["groups"].length; i++){
            var group = hd_data["groups"][i];
            for(var j = 0; j < hacking_groups[group].length; j++){
                programs[programs.length] = {
                    "group": group,
                    "program": hacking_groups[group][j]
                };
            }
        }

        // Get each program upgrade
        for(var i = 0; i < hd_data["upgrades"].length; i++){
            programs[programs.length] = {
                "group": "UPGRADE",
                "program": hd_data["upgrades"][i]
            };
        }
    }

    return programs;
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
        document.getElementsByName(player + ".ikohl")[0].value = unit["ikohl"] || 0;
        document.getElementsByName(player + ".immunity")[0].value = unit["immunity"] || '';
        document.getElementsByName(player + ".hyperdynamics")[0].value = unit["hyperdynamics"] || 0;
        document.getElementsByName(player + ".ch")[0].value = ch_mod(unit);
        document.getElementsByName(player + ".msv")[0].value = unit["msv"] || 0;
        document.getElementsByName(player + ".symbiont")[0].value = unit["symbiont"] || 0;
        document.getElementsByName(player + ".operator")[0].value = unit["operator"] || 0;
        document.getElementsByName(player + ".hacker")[0].value = unit["hacker"] || 0;
        document.getElementsByName(player + ".marksmanship")[0].value = unit["marksmanship"] || 0;
        document.getElementsByName(player + ".xvisor")[0].value = unit["xvisor"] || 0;

        document.getElementsByName(player + ".nwi")[0].checked = unit["nwi"];
        document.getElementsByName(player + ".shasvastii")[0].checked = unit["shasvastii"];
        document.getElementsByName(player + ".motorcycle")[0].checked = unit["motorcycle"];
        document.getElementsByName(player + ".nbw")[0].checked = unit["nbw"];
        document.getElementsByName(player + ".has_berserk")[0].checked = unit["berserk"];
        document.getElementsByName(player + ".sapper")[0].checked = unit["sapper"];
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
        full_stat_dropdown(player, "arm", 0, arm_max, check_params);
        full_stat_dropdown(player, "w", 1, w_max, 1, check_params);
        full_stat_dropdown_list(player, "bts", bts_list, check_params);
        full_stat_dropdown_list(player, "w_type", w_types, check_params);
        full_stat_dropdown_list(player, "type", unit_types, check_params);
    }

    populate_actions(player, check_params);
    populate_weapons(player, check_params);
    populate_ma(player, check_params);
    set_hacker(player, check_params);
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

        if(!selected){
            if(!check_params){
                unit_list.options[unit_list.options.length - 1].selected = true;
                selected = true;
            }else if(unit["name"] == params[player + ".unit"]){
                unit_list.options[unit_list.options.length - 1].selected = true;
                selected = true;
            }
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
    disable_display("mod_output");
}

function mod_output(){
    toggle_display("mod_output");
    disable_display("raw_output");
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

function action_supp_filter(unit){
    return action_weapon_filter(unit, "supp");
}

function action_cc_filter(unit){
    return action_weapon_filter(unit, "cc");
}

function action_dtw_filter(unit){
    return action_weapon_filter(unit, "dtw");
}

function action_deploy_filter(unit){
    return action_weapon_filter(unit, "deploy");
}

function action_spec_filter(unit){
    return action_weapon_filter(unit, "spec");
}

function action_hack_filter(unit){
    if(!unit){
        return 1;
    }

    if(unit["hacker"] >= 0){
        return 1;
    }

    return 0;
}

var damages = ["PH-2", "PH", 10, 11, 12, 13, 14, 15];
var stats = ["BS", "PH", "WIP"];
var w_types = ["W", "STR"];
var unit_types = ["LI", "MI", "HI", "SK", "WB", "TAG", "REM"];
var bts_list = [0, -3, -6, -9];
var ranges = ["+6", "+3", "0", "-3", "-6"];
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
        "label": "Attack - Suppressive Fire",
        "value": "supp",
        "filter": action_supp_filter,
    },
    { 
        "label": "Attack - Direct Template Weapon",
        "value": "dtw",
        "filter": action_dtw_filter,
    },
    { 
        "label": "Attack - Deployable",
        "value": "deploy",
        "filter": action_deploy_filter,
    },
    { 
        "label": "Attack - Speculative Shot",
        "value": "spec",
        "filter": action_spec_filter,
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
        "label": "Change Facing",
        "value": "change_face",
    },
    { 
        "label": "Reset",
        "value": "reset",
    },
    { 
        "label": "Hacking",
        "value": "hack",
        "filter": action_hack_filter,
    },
    { 
        "label": "No Action",
        "value": "none",
    },
];

var ma_labels = [
    'None',
    'Level 1',
    'Level 2',
    'Level 3',
    'Level 4',
    'Level 5',
];

var supp_ranges = [
    "0-8/0",
    "8-16/0",
    "16-24/-3",
];

var hacking_devices = {
    "Hacking Device": {
        "groups": [
            "CLAW-1",
            "SWORD-1",
            "SHIELD-1",
            "GADGET-1",
            "GADGET-2"
        ],
        "upgrades": []
    },
    "EI Hacking Device": {
        "groups": [
            "CLAW-1",
            "SWORD-1",
            "SHIELD-1",
            "GADGET-1",
            "GADGET-2"
        ],
        "upgrades": [
            "Sucker Punch"
        ]
    },
    "Defensive Hacking Device": {
        "groups": [
            "SHIELD-1",
            "SHIELD-2",
            "SHIELD-3",
            "GADGET-1"
        ],
        "upgrades": [],
    },
    "Hacking Device Plus": {
        "groups": [
            "CLAW-1",
            "CLAW-2",
            "SWORD-1",
            "SHIELD-1",
            "SHIELD-2",
            "GADGET-1",
            "GADGET-2"
        ],
        "upgrades": [
            "Cybermask",
            "Sucker Punch",
            "White Noise"
        ]
    },
    "Assault Hacking Device": {
        "groups": [
            "CLAW-1",
            "CLAW-2",
            "CLAW-3"
        ],
        "upgrades": [ ]
    },
    "EI Assault Hacking Device": {
        "groups": [
            "CLAW-1",
            "CLAW-2",
            "CLAW-3"
        ],
        "upgrades": [
            "Stop!"
        ]
    },
    "Hacking Device: UPGRADE: Stop!": {
        "groups": [
            "CLAW-1",
            "SWORD-1",
            "SHIELD-1",
            "GADGET-1",
            "GADGET-2"
        ],
        "upgrades": [
            "Stop!"
        ]
    },
};

var hacking_groups = {
    "CLAW-1": [
        "Blackout",
        "Gotcha!",
        "Overlord",
        "Spotlight"
    ],
    "CLAW-2": [
        "Expel",
        "Oblivion"
    ],
    "CLAW-3": [
        "Basilisk",
        "Carbonite",
        "Total Control"
    ],
    "SWORD-1": [
        "Brain Blast"
    ],
    "SHIELD-1": [
        "Exorcism",
        "Hack Transport Aircraft",
        "U-Turn"
    ],
    "SHIELD-2": [
        "Breakwater"
    ],
    "SHIELD-3": [
        "Counterstrike",
        "Zero Pain"
    ],
    "GADGET-1": [
        "Fairy Dust",
        "Lockpicker",
        "Controlled Jump"
    ],
    "GADGET-2": [
        "Assissted Fire",
        "Enhanced Reaction"
    ]
};

// Burst values of hacking programs
// Hacking programs implemented by the backend
var hacking_burst = {
    // CLAW-1
    "Blackout": 1,
    "Gotcha!": 2,
    "Overlord": 1,
    "Spotlight": 1,
    // CLAW-2
    "Expel": 1,
    "Oblivion": 1,
    // CLAW-3
    "Basilisk": 3,
    "Carbonite": 2,
    "Total Control": 1,
    // SWORD-1
    "Brain Blast": 2,
    // SHIELD-1
    "Exorcism": 2,
    // SHIELD-2
    "Breakwater": 1,
    // SHIELD-3
    "Zero Pain": 2,
    // UPGRADES
    "Sucker Punch": 1,
    "Stop!": 2,
};
