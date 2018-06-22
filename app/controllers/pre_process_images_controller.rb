require 'net/http'

class PreProcessImagesController < ApplicationController

  def create
    begin_preprocessing = Time.now

    image_url     = params['base64'];
    image_old_url = params['base64_old'];
    image_url     = remove_mime_type(image_url);
    image_old_url = remove_mime_type(image_old_url);
    image     = MiniMagick::Image.read(Base64.decode64(image_url))
    image_old = MiniMagick::Image.read(Base64.decode64(image_old_url))
    image.format     'png'
    image_old.format 'png'

    thread_id = Thread.current.object_id


    #TODO clean up
    compared_path = "tmp/images/compared-#{thread_id.to_s}.png"
    compare = MiniMagick::Tool::Compare.new
    compare << "-compose" << "src" << "-highlight-color" << "#AAAAAA" << "-lowlight-color" << "White" << "-background" << "White" << "-transparent-color"<< "White" << image.path << image_old.path << compared_path
    begin
      compare.call
    rescue
    end


    transparent_highlighted = MiniMagick::Image.open(compared_path)
    transparent_highlighted.transparent "#AAAAAA"

    composited_path = "tmp/images/composited-#{thread_id}.png"
    composite = MiniMagick::Tool::Composite.new
    composite << "-alpha" << "on" << transparent_highlighted.path << image.path << composited_path
    composite.call

    transparent_lowlighted = MiniMagick::Image.open(composited_path)
    transparent_lowlighted.transparent "White"

    puts "preprocessing time: " + (Time.now - begin_preprocessing).to_s


    begin_postprocessing = Time.now

    #TODO extract request to private method
    file_content = open(transparent_lowlighted.path) { |f| f.read }
    payload = {"base64": Base64.strict_encode64(file_content)}

    #TODO needs to be set during startup
    uri = URI.parse("http://host.docker.internal:3000/process_image")
    header = {'Content-Type': 'application/json'}
    # Create the HTTP objects
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = payload.to_json

    response = http.request(request)
    render json: response.body
    puts "postprocessing with networkdelay time: " + (Time.now - begin_postprocessing).to_s
  end

  private
    def remove_mime_type data
      start = data.index ';base64,'
      if start
        data[(start+8)..-1]
      else
        data
      end
    end
end
