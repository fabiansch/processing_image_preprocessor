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

    compared_path = "tmp/images/diff-highlighted-orig-lowlighted-black-thread-#{thread_id.to_s}.png"
    compare = MiniMagick::Tool::Compare.new
    compare << "-highlight-color" << "#fff0" << "-lowlight-color" << "#000" << image.path << image_old.path << compared_path
    begin
      compare.call
    rescue
    end

    converted_path = "tmp/images/diff-highlighted-orig-lowlighted-transparent-thread-#{thread_id.to_s}.png"
    convert = MiniMagick::Tool::Convert.new
    convert << "-transparent" << "#000" << compared_path << converted_path
    convert.call

    puts "preprocessing time: " + (Time.now - begin_preprocessing).to_s

    begin_postprocessing = Time.now

    payload = build_payload converted_path
    response = send_post_request(params['image_processor_url'], payload)

    puts "postprocessing with networkdelay time: " + (Time.now - begin_postprocessing).to_s

    render json: response.body
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

    def build_payload image_path
      file_content = open(image_path) { |f| f.read }
      payload = {"base64": Base64.strict_encode64(file_content)}
    end

    def send_post_request uri_string, payload
      uri = URI.parse(uri_string)
      uri.host = "host.docker.internal" if uri.host == 'localhost'
      header = {'Content-Type': 'application/json'}
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri, header)
      request.body = payload.to_json
      http.request(request)
    end
end
