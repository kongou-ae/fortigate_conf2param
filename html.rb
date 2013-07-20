require 'sinatra'
require 'slim'
require 'sinatra/content_for'
require './config2parameter'

set :environment, :production

get '/' do
  slim :index
end

put '/upload' do
  if @input_file = params[:file]
    save_file = "./config/" + params[:file][:filename]
    File.open(save_file,'w') do |f|
      f.write(params[:file][:tempfile].read)
    end
    @parameter_sheet = conf2param(save_file)
    #attachment "./param/#{parameter_sheet}"
    slim :upload    
  else
    "Error"
  end
end

get '/param/:filename' do |download_file|
  send_file("./param/#{download_file}")

end

__END__
@@ index
html
  body
    p = "FortiGate config to parameter"
    form action='/upload' method='POST' enctype='multipart/form-data'
      input type='file' name='file'
      input type='submit' value='upload'
      input type='hidden' name='_method' value='put'

@@ upload
html
  body
    p = "completed to generate parameter file"
    a href="./param/#{@parameter_sheet}" title='parameter sheet' Get the parameter sheet!!!
