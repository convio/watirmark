if  File.exists?("cache/DataModels")
  file = File.open("cache/DataModels", "rb")
  DataModels = Marshal::load(file.read)
  DataModels.each_key { |k| DataModels.delete(k) unless DataModels[k].cache? == true }
  warn "=========="
  warn "USING CACHED MODELS:"
  DataModels.each_pair { |k, v| warn "  #{k}: #{v.to_h}" }
  warn "=========="
end
