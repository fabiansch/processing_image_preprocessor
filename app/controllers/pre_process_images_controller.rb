require 'net/http'

class PreProcessImagesController < ApplicationController

  def create
    begin_preprocessing = Time.now

    data_url = params['base64'];
    data_url = remove_mime_type(data_url);

    image = MiniMagick::Image.read(Base64.decode64(data_url))
    image.format 'png'
    # image.write "app/image.png"

    # data_url2 = params['base64_old'];
    # data_url2 = remove_mime_type(data_url2);

    # image2 = MiniMagick::Image.read(Base64.decode64(data_url2))
    # image2.format 'png'
    # image2.write "app/image_old.png"

    #TODO use old image of payload to become stateless
    image_old = MiniMagick::Image.open("app/image-temp.png")
    image.write "app/image-temp.png"

    #TODO clean up, write to unique tempfile
    compare = MiniMagick::Tool::Compare.new
    compare << "-compose" << "src" << "-highlight-color" << "#AAAAAA" << "-lowlight-color" << "White" << "-background" << "White" << "-transparent-color"<< "White" << image.path << image_old.path << "app/compared.png"
    begin
      compare.call
    rescue
    end

    transparent = MiniMagick::Image.open("app/compared.png")
    transparent.transparent "#AAAAAA"

    #TODO write to unique tempfile
    composite = MiniMagick::Tool::Composite.new
    composite << "-alpha" << "on" << transparent.path << image.path << "app/result.png"
    composite.call

    transparent2 = MiniMagick::Image.open("app/result.png")
    transparent2.transparent "White"
    # transparent2.write "app/transparent.png"

    puts "preprocessing time: " + (Time.now - begin_preprocessing).to_s


    begin_postprocessing = Time.now

    #TODO extract request to private method
    file_content = open(transparent2.path) { |f| f.read }
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
