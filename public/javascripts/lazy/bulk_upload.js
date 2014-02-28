jQuery(function() {

    var sites = new Bloodhound({
        datumTokenizer: function(d) {  return Bloodhound.tokenizers.whitespace(d.name); },
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        limit: 10,
        local: [
            { name: 'test'}
        ],
        prefetch: {
            url: 'http://localhost:3000/sites.json',
            filter: function(list) {
                return jQuery.map(jQuery.grep(list, function(item) { return (item["value"] != "" && item["value"] !== null); }), function(site) { return { name: site["value"] }; });
            }
        }
    });
    
    sites.initialize();
    
    // instantiate the typeahead UI
    jQuery('#autocomplete_site').typeahead(null, {
        name: 'sites',
        displayKey: 'name',
        source: sites.ttAdapter()
    });

});
