# encoding： UTF-8

require "sinatra/base"
require "rdiscount"
require "erb"
require "sequel"
require "sinatra/flash"
require "./parserSetence.rb"

Sinatra::Base.set :markdown, :layout_engine => :erb
class TreeEditer < Sinatra::Base
	register Sinatra::Flash

  set :root, File.dirname(__FILE__)
  set :public_folder, Proc.new {File.join(root, "public")}
  set :views, Proc.new {File.join(root, "views")}
  set :current_setence=>""
  set :current_index=>0
  set :setence_index=>[]
  set :current_file=>""
  set :setence_hash=>{}
  set :files=>[]
  set :text_area=>""
  set :graph_area=>""

  view_path = root + "/views/"
  public_path = root + "/public/"
  layout 'background'

  configure do
  	settings.files = Dir["TreeBank/*\.fid"]
  end

  helpers do
  	def setence_segment content
  		setence_index = {}
  		index = 0
  		setence_regex = Regexp.new("<S[ ]*ID=([0-9]*)>([^<]*)<\/S>", Regexp::MULTILINE)
  		content.scan(setence_regex).each do |setence_item|
  			setence_index.store index, setence_item[1]
  			index += 1
  		end
  		setence_index
  	end
  	
  	def loadfile filename
  		content = File.read(filename)
  		settings.setence_hash = setence_segment content
  		settings.current_file = filename
  		settings.setence_index = settings.setence_hash.keys
  		settings.current_index = 0
  	end
  end
  
  get "/" do
  	@files = settings.files
  	if settings.current_file == "" then
  		settings.current_file = settings.files[0]
  		loadfile settings.current_file
  		settings.current_setence = settings.setence_hash[settings.current_index]
  	end
  	@index = settings.setence_index
  	@current_index = settings.current_index
  	@current_file = settings.current_file
  	
  	begin
  		settings.text_area, settings.graph_area = parserSetence settings.current_setence
  	rescue => e
  		puts e.message
  		puts e.backtrace
  	end	
  	
  	@setence = settings.text_area
  	@graph_area = settings.graph_area
  	erb :index, :layout => :background
  end
  
  post '/choose' do
  	if settings.current_file != params[:treeBankFileName] then
  		loadfile params[:treeBankFileName]
  	end
  	
  	if params[:index] == nil then
  		settings.current_index = 0
  	else
  		settings.current_index = params[:index].to_i
  	end
  	settings.current_setence = settings.setence_hash[settings.current_index]
  	redirect "/"
  end
  
  post '/nextfile' do
  	if settings.current_file == "" then
  		settings.current_file = settings.files[0]
  	end
	 temp = settings.files.find_index(settings.current_file) + 1
	 if temp < settings.files.size then
	 	loadfile settings.files[temp]
	 	@hasNextFile = ""
	 else
	 	@hasNextFile = "disabled"
	 end
	 redirect "/"
  end  
  
  post '/prefile' do
  	  if settings.current_file == "" then
  		settings.current_file = settings.files[0]
  	end
	 temp = settings.files.find_index(settings.current_file) - 1
	 if temp >= 0 then
	 	loadfile settings.files[temp]
	 	@hasPreFile = ""
	 else
	 	@hasPreFile = "disabled"
	 end
	 redirect "/"
  end
  
  post '/presetence' do
  	if settings.current_index - 1 < 0 then
  		@hasPreSetence = "disabled"
  	else
  		@hasPreSetence = ""
  		settings.current_index -= 1
   		settings.current_setence = settings.setence_hash[settings.current_index]
  	end
	 redirect "/"
  end
  
  post '/nextsetence' do
  	if settings.current_index + 1 >= settings.setence_hash.size then
  		@hasPreSetence = "disabled"
  	else
  		@hasPreSetence = ""
  		settings.current_index += 1
   		settings.current_setence = settings.setence_hash[settings.current_index]
  	end
	 redirect "/"
  end
  
  post '/edit_tree' do
  	settings.current_setence = params[:content]
  	redirect "/"
  end
  
  post '/write_file' do
  	settings.setence_hash[settings.current_index] = settings.current_setence
  	redirect "/"
  end
  
  not_found do
    markdown File.read("#{public_path}not_found.md"), :layout => :background
  end

  run!
end

