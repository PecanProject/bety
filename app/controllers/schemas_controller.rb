class SchemasController < ApplicationController

  def index
  @partial='index_table'
  if params[:partial].present?
    @partial=params[:partial].strip
  end
    respond_to do |format|
      format.html # index.html.erb
    end
  end


end
