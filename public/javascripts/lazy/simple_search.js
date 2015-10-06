var delay = (function () {
    var timer = 0;
    return function (callback, ms) {
        clearTimeout(timer);
        timer = setTimeout(callback, ms);
    };
})();


// Handler for 'keyup' event in search box and 'select records per
// page' control.  Also called by handlers for the 'Clear Map' button
// and the 'Show/Hide Map' button, and by the 'search_by_location'
// function.
var search_function = function (event, locationParameters) {
    if (event && is_ignored(event)) return;

    if (!locationParameters) {
        var locationParameters = {};
    }
    delay(function () {
        var iteration = parseInt(jQuery('#simple_search_table').attr('class').match(/\d+/)[0]) + 1;
        jQuery('#simple_search_table').removeClass();
        jQuery('#simple_search_table table').css('opacity', '.3');
        jQuery('#simple_search_table').addClass('simple_search_table_' + iteration);
        jQuery.extend(locationParameters, { iteration: iteration });
        var additionalParams = jQuery.param(locationParameters); // parameters that aren't from the search form
        jQuery.get(jQuery('form').attr('action'), jQuery('#simple_search').serialize() + '&' + additionalParams, null, 'script');
        return false;
    }, 1000);
}

// Auxiliary function used by "search_function".  Returns true if
// "event" is a keyup event on a key we are not interested in.  Since
// this is only used in deciding what key presses trigger a search, we
// don't have to be too fussy.  The main thing is to ignore keys like
// TAB and arrow keys.  See http://unixpapa.com/js/key.html for
// information about key codes.
function is_ignored(event) {
    if (event.type == "keyup") {
        var keyCode = event.which;

        var dontIgnore = false;

        // Don't ignore alphabetic keys:
        if (65 <= keyCode && keyCode <= 90) {
            dontIgnore = true;
        }

        // Don't ignore backspace or delete button
        if (keyCode == 8 || keyCode == 46) {
            dontIgnore = true;
        }

        // Don't ignore numbers, spaces, or certain symbols
        if (48 <= keyCode && keyCode <= 57 // number keys
            || 96 <= keyCode && keyCode <= 105 // number keys on keypad
            || keyCode == 187 || keyCode == 107 || keyCode == 61 // + sign
            || keyCode == 189 || keyCode == 109 || keyCode == 45 // - sign; underscore
            || keyCode == 190 || keyCode == 110 || keyCode == 46 // period
            || keyCode == 188 || keyCode == 44 // comma
            || keyCode == 191 || keyCode == 111 || keyCode == 47 // forward slash/division sign
            || keyCode == 32) /* space */ {
            dontIgnore = true;
        }

       return !dontIgnore;
    }
    return false;
}
        

// Handler for 'Clear Map' button
function remove_search_term_restriction() {
    jQuery('#simple_search input#search').val('');
    search_function();
}

// Handler for 'Download' button
function download_search_results() {
    location.search = jQuery('#simple_search').serialize() + '&format=csv';
}

jQuery(function () {
    // Attach delegated handlers to elements that are within the
    // portion of the page being replaced:

    // Force table sorting and pagination links to work via AJAX:
    jQuery('#simple_search_table').on('click', 'th a, .pagination a',
        function () {
            jQuery('#simple_search_table table').css('opacity', '.3');
            jQuery.getScript(this.href);
            return false;
        });

    jQuery('#simple_search_table').on('change', 'select[name="DataTables_Table_0_length"]', search_function);
    jQuery('#simple_search_table').on('change', 'input[name="include_unchecked"]', search_function);
    jQuery('#simple_search_table').on('keyup', 'input', search_function);
    jQuery('#simple_search_table').on('click', 'button#clear_search_terms',remove_search_term_restriction);


    
    // Attach direct handlers to elements outside the portion of the
    // page being replaced:
    jQuery('button#download').click(download_search_results);

    // Set focus in the search box upon loading:
    jQuery('#search').focus();
});

