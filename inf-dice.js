function toggle_display(obj){
    var el = document.getElementById(obj);

    if(el.style.display == 'none'){
        el.style.display = '';
    }else{
        el.style.display = 'none';
    }
}
