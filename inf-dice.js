function toggle_display(obj){
    el = document.getElementById(obj);

    if(el.style.display == "none"){
        el.style.display = "";
    }else{
        el.style.display = "none";
    }
}

function enable_display(obj){
    el = document.getElementById(obj);

    el.style.display = "";
}

function disable_display(obj){
    el = document.getElementById(obj);

    el.style.display = "none";
}

function other_player(player){
    if(player == "p1"){
        return "p2";
    }else{
        return "p1";
    }
}

function set_ammo(player){
    return;

    other = other_player(player);
    ammo_name = player + ".ammo";
    arm_id = other + ".arm";
    dam_id = player + ".dam";

    ammo = document.getElementsByName(ammo_name)[0];

    if(ammo.value == "Smoke"){
        disable_display(arm_id);
        disable_display(dam_id);
    }else{
        if(ammo.value == "Viral" || ammo.value == "E/M" || ammo.value == "E/M2"){
            arm_label_id_on = arm_id + ".label_bts";
            arm_label_id_off = arm_id + ".label_arm";
            sign = -1;
        }else{
            arm_label_id_on = arm_id + ".label_arm";
            arm_label_id_off = arm_id + ".label_bts";
            sign = 1;
        }

        enable_display(arm_label_id_on);
        disable_display(arm_label_id_off);
        enable_display(dam_id);
        enable_display(arm_id);

        arm_field = document.getElementsByName(arm_id)[0];
        arm_field.value = sign * Math.abs(arm_field.value);
    }
}

function set_action(player){
    return;

    other = other_player(player);
    action_name = player + ".action";
    action = document.getElementsByName(action_name)[0];
    label_id = player + ".bs.label_";

    if(action.value == "attack"){
        enable_display(player + ".ammo");
        enable_display(player + ".b");
        enable_display(player + ".dam");
        enable_display(other + ".arm");
        enable_display(player + ".mods.attack");
        disable_display(player + ".mods.dodge");

        label_id_on = label_id + "bs";
        label_id_off = label_id + "ph";
    }else{
        disable_display(player + ".ammo");
        disable_display(player + ".b");
        disable_display(player + ".dam");
        disable_display(other + ".arm");
        disable_display(player + ".mods.attack");
        enable_display(player + ".mods.dodge");

        label_id_on = label_id + "ph";
        label_id_off = label_id + "bs";
    }

    enable_display(label_id_on);
    disable_display(label_id_off);

    set_ammo(player);
}

function init_on_load(){
    set_action("p1");
    set_action("p2");
}

function raw_output(){
    toggle_display("raw_output");
}
