#http://weblog.redlinesoftware.com/2008/1/30/willpaginate-and-remote-links
# RAILS3 Changed to extend WillPaginate::ViewHelpers::LinkRenderer instead of WillPaginate::LinkRenderer
class RemoteLinkRenderer < WillPaginate::ViewHelpers::LinkRenderer
 def prepare(collection, options, template)    
   @remote = options.delete(:remote) || {}
   super
 end

 # RAILS3 This needs to be implemented for some reason..why isn't the superclass taking care of it?...getting NotImplementedError in pages
 #def to_html
 #
 #end

protected
 def page_link(page, text, attributes = {})
   @template.link_to_remote(text, {:url => url_for(page), :method => :post}.merge(@remote))
 end
end

