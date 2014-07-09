jQuery(function () {
    jQuery("#guest-login").click(function(event) {
        jQuery("input#login").val("guestuser");
        jQuery("input#password").val("guestuser");
        jQuery("#loginform").submit();
        event.preventDefault();
    });
});

