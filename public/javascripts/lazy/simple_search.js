var delay = (function () {
    var timer = 0;
    return function (callback, ms) {
        clearTimeout(timer);
        timer = setTimeout(callback, ms);
    };
})();

var search_function = function (event, locationParameters) {
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
        jQuery.get(this.action, jQuery('#simple_search').serialize() + '&' + additionalParams, null, 'script');
        return false;
    }, 1000);
}

function remove_search_term_restriction() {
    jQuery('#simple_search input#search').val('');
    search_function();
}

function download_search_results() {
    location.search = jQuery('#simple_search').serialize() + '&format=csv';
}

jQuery(function () {
    jQuery('#simple_search_table th a, #simple_search_table .pagination a').live('click',
        function () {
            jQuery('#simple_search_table table').css('opacity', '.3');
            jQuery.getScript(this.href);
            return false;
        });

    jQuery('#simple_search select').change(search_function);
    jQuery('#simple_search input').keyup(search_function);
    jQuery('button#clear_search_terms').click(remove_search_term_restriction);
    jQuery('button#download').click(download_search_results);
});

