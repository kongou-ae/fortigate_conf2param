require 'sinatra'
require 'slim'
require 'sinatra/content_for'

set :environment, :production

get '/' do
  slim :index
end

put '/upload' do
  if @input_file = params[:file]
    slim :upload

    save_file = "./config/" + params[:file][:filename]
    File.open(save_file,'w') do |f|
      f.write(params[:file][:tempfile].read)
    end
  else
    "Error"
  end
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
    p = "filename : #{@input_file[:filename]}"
    p = "type: #{@input_file[:type]}"
    p = "name: #{@input_file[:name]}"
    p = "tempfile: #{@input_file[:tempfile]}"
    p = "head: #{@input_file[:head]}"
