# From http://snippets.dzone.com/posts/show/4146
class NestedHash < Hash
   def initialize
     blk = lambda {|h,k| h[k] = NestedHash.new(&blk)}
     super(&blk)
   end
end

class Hash
   def Hash.new_nested_hash
     Hash.new{|h,k| h[k]=Hash.new(&h.default_proc) }
   end

  def nested_hash(array)
    node = self
    array.each do |i|
      node[i]=Hash.new if node[i].nil?
      node = node[i]
    end 
    self
  end
end

class SearchController < ApplicationController
  before_filter :login_required

  layout 'application'

  # POST /search.xml
  def index
    query = params[:query]

    includes = []
    conditions = [""]

    # Get our order directive and remove it from the hash    
    order = params[:query].delete(:order)

    failed = catch :error do
      includes, conditions = read_query(query,includes,conditions)

      throw :error, nil
    end

    # If there are no includes/conditions set them to nil, makes them play nice with rails
    includes = nil if includes.empty?
    conditions = nil if conditions[0].blank?

    #Need to get the table name
    table = query.shift[0].classify.constantize rescue nil
  
    # not a valid order field set it to nil.
    if !order.nil? and !table.nil? and !table.column_names.include?(order.split(" ").first)
      order = nil
    end
  
    logger.info ":---: Includes"
    logger.info includes.to_yaml
    logger.info ":---: Conditions"
    logger.info conditions.to_yaml
    logger.info ":---: Order"
    logger.info order.to_yaml
    logger.info ":---: Failed"
    logger.info failed

    if !failed 
      @result = table.all(:include => includes, :conditions => conditions, :order => order) rescue { "error" => "Query Failed", "check" => "Check Table associations" }
    else
      @result = {"error" => failed} 
      logger.info @result.to_yaml
    end

    respond_to do |format|
      format.xml  { render :xml => @result }
      format.csv  { render :csv => @result }
      format.json  { render :json => @result }
    end
  end

  private

  def read_query(query, includes=[], conditions=[], table="", join="and")
    query.each do |k,v|
      # Join statement, set it, add parens
      if ['and','or'].include?(k)

        conditions[0] += join if !conditions[0].blank?
        conditions[0] += " ("
        read_query(v,includes,conditions,table,k)
        conditions[0] += " )"
    
      # Check if the key is a class, Constantize fails hard so rescue
      elsif (k.classify.constantize rescue nil)

        rel = table.split(".").last
        
        if rel.nil?
          table += ".#{k}"
        elsif (rel.classify.constantize.column_names.include?("#{k.singularize.downcase}_id") rescue nil)
          table += ".#{k.singularize}"
        elsif ("#{rel.classify.pluralize}#{k.classify.pluralize}".constantize rescue nil) or ("#{k.classify.pluralize}#{rel.classify.pluralize}".constantize rescue nil)
          table += ".#{k.pluralize}"
        else
         throw :error, "#{rel.to_s} - #{k.to_s} : No relationship"
        end 
     
        read_query(v,includes,conditions,table,join)
          
       # Check if key is field value, Constantize fails hard so rescue
       elsif (table.split('.').last.classify.constantize.column_names.include?(k) rescue nil)
         
         ['<','<=','>','>=','=','!=','in','not in','like'].include?(v['op']) ? op = v['op'] : op = '='

         throw :error, "#{k.to_s} - Did not contain a 'value' child" if v['value'].nil? 
     
         conditions[0] += join if conditions[0].last != "(" and !conditions[0].blank?
         conditions[0] += " #{table.split('.').last.pluralize}.#{k} #{op} (?) "
         conditions << v['value']
    
         includes << Hash.new.nested_hash(table.split('.')[2,table.split('.').length-2].collect { |x| x.to_sym })

      # If we get here the field/table/join was not recognized, exit and let them know the problem.
       else
         logger.info k
         logger.info v
         throw :error, "#{k.to_s} - was not a valid field/table/join"

       end
    end

    return includes, conditions
  end    
end
