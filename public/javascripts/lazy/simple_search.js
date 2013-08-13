var delay = (function () {
    var timer = 0;
    return function (callback, ms) {
        clearTimeout(timer);
        timer = setTimeout(callback, ms);
    };
})();

var search_function = function () {
        delay(function () {
            var iteration = parseInt(jQuery('#simple_search_table').attr('class').match(/\d+/)[0]) + 1;
            jQuery('#simple_search_table').removeClass();
            jQuery('#simple_search_table table').css('opacity', '.3');
            jQuery('#simple_search_table').addClass('simple_search_table_' + iteration);
            jQuery.get(this.action, jQuery('#simple_search').serialize() + '&iteration=' + iteration, null, 'script');
            return false;
        }, 250);
    }

jQuery(function () {
    jQuery('#simple_search_table th a, #simple_search_table .pagination a').live('click',
        function () {
            jQuery('#simple_search_table table').css('opacity', '.3');
            jQuery.getScript(this.href);
            return false;
        });

    jQuery('#simple_search input').keyup(search_function);
});

