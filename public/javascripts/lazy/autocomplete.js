// We use this creation function to create the select function so that
// the value of "autocompletion_widget_id" used in the function is the
// value at the time the function was defined rather than the value at
// the time it is run.  That is, we want a closure.
function create_select_function(autocompletion_widget_id) {
    return function(event, ui) {
        // Prevent the value (the id number) of the item selected from
        // displaying after a selection has been made ...
        event.preventDefault();

        // ... and display the *label* of the item selected instead ...
        jQuery(this).val(ui.item.label);

        // ... but store the value of the item selected in a hidden field.
        jQuery('#' + completion_fields[autocompletion_widget_id].hidden_field_id).val(ui.item.value);
    }
}

jQuery(function() {
    // initialize any and all autocompletion fields found on the page:
    for (autocompletion_widget_id in completion_fields) {
        
        jQuery('#' + autocompletion_widget_id).autocomplete({
            source: ROOT_URL + "/" + completion_fields[autocompletion_widget_id].controller + "/autocomplete.json",
            select: create_select_function(autocompletion_widget_id),
            focus: function(event, ui) {
                // Prevent the value (the id number) of an item selected from
                // displaying when using the arrow keys ...
                event.preventDefault();
                
                // ... and display the *label* of the item focused on instead.
                jQuery(this).val(ui.item.label);
            }
        });
    }

});
