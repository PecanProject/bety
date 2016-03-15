# Set default per page

WillPaginate.per_page = 25

#https://gist.github.com/3142686
# RAILS3 Moved class from app/helpers/remote_link_renderer to this initializer so it gets loaded properly
# Changed to extend WillPaginate::ActionView::LinkRenderer instead of WillPaginate::LinkRenderer

module WillPaginate::ActionView
  class RemoteLinkRenderer < LinkRenderer
    def link(text, target, attributes = {})
      attributes['data-remote'] = true
      super
    end
  end
end

