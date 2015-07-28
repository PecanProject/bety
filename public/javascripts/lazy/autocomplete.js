jQuery(function() {
    // initialize any and all autocompletion fields found on the page:

    jQuery('#search_sites').autocomplete({
        source: ROOT_URL + "/sites/autocomplete.json"/*,
        select: function(event, ui) {
            event.preventDefault();
            $("#search_sites").val(ui.item.label);
            PK.render(ui.item.value);
        }*/
    });

    jQuery('#search_sites').on("autocompleteselect", function(e, ui) {

        // Prevent the value of the item selected from displaying after a
        // selection has been made ...
        e.preventDefault();

        // ... and display the *value* of the item selected instead ...
        this.value = ui.item.label;

        // ... but store the value of the item selected in a hidden field.
        jQuery('#input_site_id').val(ui.item.value);
    });
    
});
