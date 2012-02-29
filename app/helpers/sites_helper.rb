module SitesHelper

    def params_for_javascript(params) #options_for_javascript doesn't works fine
        
        '{' + params.map {|k, v| "#{k}: #{ 
            case v
              when Hash then params_for_javascript( v )
              when String then "'#{v}'"          
            else v   #Isn't neither Hash or String
            end }"}.sort.join(', ') + '}'
    end
    
    
    
    def link_to_prototype_dialog( name, content, dialog_kind = 'alert', options = { :windowParameters => {} } , html_options = {} )
    
        #dialog_kind: 'alert' (default), 'confirm' or 'info' (info dialogs should be destroyed with a javascript function call 'win.destroy')
        #options for this helper depending the dialog_kind: http://prototype-window.xilinus.com/documentation.html#alert (#confirm or #info)
    
        js_code ="Dialog.#{dialog_kind}( '#{content}',  #{params_for_javascript(options) } ); "
        content_tag(
               "a", name, 
               html_options.merge({ 
                 :href => html_options[:href] || "#", 
                 :onclick => (html_options[:onclick] ? "#{html_options[:onclick]}; " : "") + js_code }))
    end
    
    
    
    def link_to_prototype_window( name, window_id, options = { :windowParameters => {} } , html_options = {} )
        
        #window_id must be unique and it's destroyed on window close.
        #options for this helper: http://prototype-window.xilinus.com/documentation.html#initialize

        js_code = "var win = new Window( 'site-map_#{window_id}', #{params_for_javascript(options) } );  win.show(); win.setDestroyOnClose();"

        content_tag(
               "a", name,
               html_options.merge({
                 :href => html_options[:href] || "#",
                 :onclick => (html_options[:onclick] ? "#{html_options[:onclick]}; " : "") + js_code }))
        
    end



end
