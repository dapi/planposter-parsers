# -*- coding: utf-8 -*-

class ImageUploader < CarrierWave::Uploader::Base
  attr_accessor :cache_dir, :cache_name
  storage :file
end
