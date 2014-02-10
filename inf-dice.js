function toggle_display(obj){
    el = document.getElementById(obj);

    if(el.style.display == 'none'){
        el.style.display = '';
    }else{
        el.style.display = 'none';
    }
}

function set_ARM_BTS_helper(select_name, label_id){
    select = document.getElementsByName(select_name)[0];

    if(select.value == "Viral" || select.value == "E/M" || select.value == "E/M2"){
        label_id_on = label_id + ".label_bts";
        label_id_off = label_id + ".label_arm";
        sign = -1;
    }else{
        label_id_on = label_id + ".label_arm";
        label_id_off = label_id + ".label_bts";
        sign = 1;
    }

    label_on = document.getElementById(label_id_on);
    label_off = document.getElementById(label_id_off);
    arm_field = document.getElementsByName(label_id)[0];

    label_on.style.display = '';
    label_off.style.display = 'none';
    arm_field.value = sign * Math.abs(arm_field.value);
}

function set_ARM_BTS(){
    set_ARM_BTS_helper("p1.ammo", "p2.arm");
    set_ARM_BTS_helper("p2.ammo", "p1.arm");
}
