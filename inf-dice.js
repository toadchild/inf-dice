function toggle_display(obj){
    el = document.getElementById(obj);

    if(el.style.display == "none"){
        el.style.display = "";
    }else{
        el.style.display = "none";
    }
}

function _set_style_recursive(obj, styles){
    if("style" in obj){
        for(i = 0; i < styles.length; i++){
            obj.style.setProperty(styles[i][0], styles[i][1]);
        }

        children = obj.childNodes;

        for(i = 0; i < children.length; i++){
            _set_style_recursive(children[i], styles);
        }
    }
}

function enable_input(id){
    obj = document.getElementById(id);
    styles = [
        ["text-decoration", "none"],
        ["color", "black"],
    ];

    _set_style_recursive(obj, styles);
}

function disable_input(id){
    obj = document.getElementById(id);
    styles = [
        ["text-decoration", "line-through"],
        ["color", "grey"],
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
    other = other_player(player);

    action_name = player + ".action";
    action = document.getElementsByName(action_name)[0];

    if(action.value == "bs" || action.value == "cc"){
        ammo_name = player + ".ammo";
        ammo_obj = document.getElementsByName(ammo_name)[0];
        ammo = ammo_obj.value;
    }else{
        // Any case where we aren't attacking
        ammo = "None";
    }

    arm_id = other + ".arm";
    bts_id = other + ".bts";
    dam_id = player + ".dam";

    if(ammo == "Smoke" || ammo == "None"){
        disable_input(dam_id);
        disable_input(arm_id);
        disable_input(bts_id);
    }else if(ammo == "Monofilament" || ammo == "K1"){
        disable_input(dam_id);
        disable_input(arm_id);
        disable_input(bts_id);
    }else if(ammo == "Viral" || ammo == "E/M" || ammo == "E/M2"){
        enable_input(dam_id);
        enable_input(bts_id);
        disable_input(arm_id);
    }else{
        enable_input(dam_id);
        enable_input(arm_id);
        disable_input(bts_id);
    }
}

function set_action(player){
    other = other_player(player);
    action_name = player + ".action";
    action = document.getElementsByName(action_name)[0];

    if(action.value == "bs"){
        // stat block
        enable_input(player + ".stat");
        enable_input(player + ".b");
        enable_input(player + ".ammo");

        // modifiers
        enable_input(player + ".range");
        enable_input(player + ".link");
        enable_input(player + ".viz");
        disable_input(player + ".dodge_unit");
        disable_input(player + ".gang_up");

        // defensive abilities
        enable_input(other + ".cover");
        enable_input(other + ".ch");
        disable_input(other + ".ikohl");
    }else if(action.value == "cc"){
        // stat block
        enable_input(player + ".stat");
        disable_input(player + ".b");
        enable_input(player + ".ammo");

        // modifiers
        disable_input(player + ".range");
        disable_input(player + ".link");
        disable_input(player + ".viz");
        disable_input(player + ".dodge_unit");
        enable_input(player + ".gang_up");

        // defensive abilities
        disable_input(other + ".cover");
        disable_input(other + ".ch");
        enable_input(other + ".ikohl");
    }else if(action.value == "dodge"){
        // stat block
        enable_input(player + ".stat");
        disable_input(player + ".b");
        disable_input(player + ".ammo");

        // modifiers
        disable_input(player + ".range");
        disable_input(player + ".link");
        disable_input(player + ".viz");
        enable_input(player + ".dodge_unit");
        enable_input(player + ".gang_up");

        // defensive abilities
        disable_input(other + ".cover");
        disable_input(other + ".ch");
        disable_input(other + ".ikohl");
    }else if(action.value == "none"){
        // stat block
        disable_input(player + ".stat");
        disable_input(player + ".b");
        disable_input(player + ".ammo");

        // modifiers
        disable_input(player + ".range");
        disable_input(player + ".link");
        disable_input(player + ".viz");
        disable_input(player + ".dodge_unit");
        disable_input(player + ".gang_up");

        // defensive abilities
        disable_input(other + ".cover");
        disable_input(other + ".ch");
        disable_input(other + ".ikohl");
    }
    set_ammo(player);
}

function init_on_load(){
    set_action("p1");
    set_action("p2");
}

function raw_output(){
    toggle_display("raw_output");
}
