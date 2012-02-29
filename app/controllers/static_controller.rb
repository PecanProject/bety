class StaticController < ApplicationController

  #caches_page :index
  #layout 'application'

  # Allows us to show the documentation without wrapping by adding '?min' to the end of the url
  layout Proc.new { |controller| controller.request.query_string == 'min' ? nil : 'application' }


# Notes:
# calling "render :file" will cause some sort of caching
# even in development mode
# use "File.open + render :inline" to avoid caching
# "render :text" doesn't interpret ERB statements

  def index

    if !params[:refresh].nil?
      expire_fragment('main_index')
      logger.info 'Main page refreshed'
    end


    # 'static' documents are in app/views/static
    # path is relative from template home ( app/views )
    path = 'static'

    # set path from params if available
    path = 'static/' + params[:path].join('/') unless params[ :path ].nil?
# DEBUG
#@path = path
   
    # file_path is relative from Rails home
    file_path = 'app/views/' + path
    full_path = RAILS_ROOT + '/app/views/' + path
    
    # if the file_path is a directory, but the URL doesn't end with a slash
    # (this helps with relative paths for URLs contained in the document)
    if File.directory?( file_path ) && ! /\/$/.match( request.path )
      redirect_to( request.path + '/' )
      return
    end

    file_to_render = nil
    case
    # if the file_path is a directory
    when File.directory?( file_path )

      file_to_render = full_path + '/index.html.erb'
    # if the file_path is a plain file and ends with .html
    when File.file?( file_path ) && /\.html$/.match( file_path )
      file_to_render = full_path
    # if the file_path with .html appended is a plain file
    when File.file?( file_path + '.html' )
      file_to_render = full_path + '.html'
    # if the file_path with .html.erb appended is a plain file
    when File.file?( file_path + '.html.erb' )
      file_to_render = full_path + '.html.erb'
    end

   logger.info file_path

    unless file_to_render.nil?
      file = File.open( file_to_render )
      file_contents = file.read
      file.close
      render :inline => file_contents, :layout => true
    else
      render :file => RAILS_ROOT + '/app/views/static/404.html', :layout => true, :status => 404
# DEBUG
#      raise ::ActionController::RoutingError,
#            "Recognition failed for #{request.path.inspect} #{ path }"
    end

  end

end
