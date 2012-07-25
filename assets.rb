#!/usr/bin/env ruby
require 'yaml'
require 'pathname'
require 'tempfile'

Rails_App_Path = "#{File.expand_path File.dirname(__FILE__)}/.."

# TODO => Is there another way to create a file
class AssetsFileManager
  def initialize controller, action, operation = 'g'
    @controller = controller
    @action = action
    if @controller.nil? || @action.nil?
      puts "\033[1;31m Error\033[0m Controller Or Action Can't Be NIL" 
    else
      @asset_node = [@controller, @action].join('_')
      @view_pn = Pathname.new "#{Rails_App_Path}/app/views/#{@controller}/#{@action}.html.erb"
      @js_assets = YAML::load(File.open("#{Rails_App_Path}/config/assets.yml"))['javascripts'][@asset_node]
    
      if operation == "d"
        remove_action
        remove_route
        remove_view_file
        remove_js_files
      else
        add_action
        add_route
        create_view_file
        create_js_files
      end
    end
  end

  def create_view_file
    unless @view_pn.exist?
      @view_pn.parent.mkpath unless @view_pn.parent.exist?
      @view_pn.open('w') do |view|
        view.write ''
      end
      puts "\033[32m Create\033[0m \t\t#{@view_pn.to_s}"
    else
      puts "\033[1;31m Existed\033[0m \t\t#{@view_pn.to_s}"
    end
    original_content = @view_pn.read
    # TODO => Is there another way to detect a file?
    unless original_content.include? @asset_node
      @view_pn.open('w') do |view|
        view.write "<%= include_javascripts :#{@asset_node} %>\n" + original_content
      end
      puts "\033[32m Dependence Prepended\033[0m \t#{@view_pn.to_s}"
    else
      puts "\033[32m Dependence Existetd\033[0m \t#{@view_pn.to_s}"
    end
  end
  
  def create_js_files
    @js_assets.each do |js|
      js_pn = Pathname.new "#{Rails_App_Path}/#{js}"
      unless js_pn.exist?
        js_pn.parent.mkpath unless js_pn.parent.exist?
        js_pn.open('w') do |js_file|
          js_file.write ''
        end
        puts "\033[32m Create\033[0m \t\t#{js_pn.to_s}"
      else
        puts "\033[1;31m Existed\033[0m \t\t#{js_pn.to_s}"
      end
    end
  end
  
  def remove_view_file
    if @view_pn.exist?
      @view_pn.delete
      puts "\033[31m Remove\033[0m \t#{@view_pn.to_s}"
    else
      puts "\033[1;31m Not Existed\033[0m \t#{@view_pn.to_s}"
    end
  end
  
  def remove_js_files
    @js_assets.each do |js|
      js_pn = Pathname.new "#{Rails_App_Path}/#{js}"
      if js_pn.exist?
        js_pn.delete
        puts "\033[31m Remove\033[0m \t#{js_pn.to_s}"
      else
        puts "\033[1;31m Not Existed\033[0m \t#{js_pn.to_s}"
      end
    end
  end
  
  def add_action
    controller = File.new("#{Rails_App_Path}/app/controllers/#{@controller}_controller.rb")
    temp_controller = Tempfile.new "#{@controller}_controller.rb"
    action_existed = false
    controller.each_line do |line|
      action_existed = true if line.include?("def #{@action}")
      if !action_existed && (line.include?('private') || line.include?('public'))  # replace it with regular expression
        temp_controller << "  # GET /#{@controller}/#{@action}\n"
        temp_controller << "  def #{@action}\n"
        temp_controller << "  end\n\n"
      end
      
      temp_controller << line
    end
    
    FileUtils.mv(temp_controller.path, controller.path)
    puts "\033[32m Action Create\033[0m"
  end
  
  # ONLY remove unmodified action
  def remove_action
    controller = File.new("#{Rails_App_Path}/app/controllers/#{@controller}_controller.rb")
    temp_controller = Tempfile.new "#{@controller}_controller.rb"
    action_found = false
    skipped = 0
    controller.each_line do |line|
      action_found = true if line.include?("# GET /#{@controller}/#{@action}\n")
      (action_found && skipped < 3) ? skipped += 1 : temp_controller << line
    end
    
    FileUtils.mv(temp_controller.path, controller.path)
    puts "\033[31m Action Removed\033[0m"
  end
  
  def add_route
    temp_routes = Tempfile.new 'routes.rb'
    routes = File.new("#{Rails_App_Path}/config/routes.rb")
    reached_scope = false
    new_scope = false
    extended_routes = false
    routes.each_line do |line|
      if line.include? "resources :#{@controller}"
        reached_scope = true
      elsif !extended_routes && line.include?('resources :databases')
        new_scope = true
        temp_routes << "  resources :#{@controller} do\n"
        temp_routes << "    collection do\n"
        temp_routes << "      get '#{@action}'\n"
        temp_routes << "    end\n"
        temp_routes << "  end\n\n"
      end
      
      temp_routes << line
      if reached_scope && line.include?('collection do')
        temp_routes << "      get '#{@action}'\n"
        reached_scope = false
        extended_routes = true
      end
    end
    
    FileUtils.mv temp_routes.path, "#{Rails_App_Path}/config/routes.rb"
    puts "\033[32m Route Create\033[0m"
  end
  
  def remove_route
    temp_routes = Tempfile.new 'routes.rb'
    routes = File.new("#{Rails_App_Path}/config/routes.rb")
    routes.each_line do |line|
      temp_routes << line unless line.include?("get '#{@action}'")
    end
    
    FileUtils.mv temp_routes.path, "#{Rails_App_Path}/config/routes.rb"
    puts "\033[31m Route Removed\033[0m"
  end
end

AssetsFileManager.new(ARGV[0], ARGV[1], ARGV[2])
