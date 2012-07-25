require 'yaml'

=begin
  TODO Is there another way to create a file
=end
class AssetsFileManager
  def initialization controller, action
    @view_pn = Pathname.new "app/views/#{controller}/#{action}"
    @js_assets = YAML::load(File.open('asset.yml'))['javascripts'][[controller, action].join('_')]
    
    init_view_file
    init_js_file
  end

  def create_view_file
    @view_pn.parent.mkpath unless @view_pn.parent.exist?
    @view_pn.open('w') do |view|
      view.write ''
    end
  end
  
  def init_view_file
    create_view_file unless @view_pn.exist?
  end
  
  def init_js_file
    @js_assets.each do |js|
      js_pn = Pathname.new js
      js_pn.parent.mkpath unless js_pn.parent.exist?
      js_pn.open('w') do |js_file|
        js_file.write ''
      end
    end
  end
end

AssetsFileManager.new(ARGV[0], ARGV[1])
