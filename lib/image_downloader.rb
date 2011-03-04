# -*- coding: utf-8 -*-

class ImageDownloader < CarrierWave::Uploader::Base
  attr_accessor :cache_dir, :cache_name
  storage :file
  def self.download! image_url, image_path
    image = ImageDownloader.new
    image.cache_dir = "./"
    image.cache_name = image_path
    image.download!(image_url)
  end
end
