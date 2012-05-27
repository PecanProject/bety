// Use on trait new/edit page to update max/min values when variable is changed
function traits_get_variable_max_min(id){
  jQuery.ajax({ dataType: "json",
                url: "/bety/variables/"+id,
                success: function(data) {
                  jQuery('span#variable_max').html(data.variable.max);
                  jQuery('span#variable_min').html(data.variable.min);
                  jQuery('span#variable_name').html(data.variable.name);
                }});
}

