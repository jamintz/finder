class HardWorker
  include Sidekiq::Worker
  require 'csv'
  require 'net/http'
  
  def get_links(url,r)
    key = '86a28e1d290341a698bc74b295a0b0ec'
    
    uri = URI(url)
    req = Net::HTTP::Get.new(uri.request_uri)
    req.add_field("Ocp-Apim-Subscription-Key", key)
    res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https'){|http|http.request(req)}
    body = JSON.parse(res.body, :symbolize_names => true)
    results = []
    
    results = body[:webPages][:value].select{|x|x[:name] && x[:name].downcase.include?(r.name.downcase) && x[:displayUrl] && x[:displayUrl].include?('linkedin.com')&&!x[:displayUrl].include?('/dir/')} if body[:webPages] && body[:webPages][:value]

    profiles = results.map{|x|x[:displayUrl]}
    out = []
    profiles.each do |p|
      broke=(p.split("://").first+"://www.linkedin.com"+p.split("linkedin.com").last).split("in/")
      out << broke.first+"in/"+broke.last.split("/").first
    end
    return out
  end

  def perform(bid)
    b = Batch.find(bid)
    b.rows.each do |r|
      term = "linkedin #{r.name} \"#{r.school}\" #{r.business}"
      url = "https://api.cognitive.microsoft.com/bing/v5.0/search?q=#{URI.encode(term)}"
            
      out = get_links(url,r)
      if r.business && out.count != 1
        term = "linkedin #{r.name} \"#{r.school}\""
        url = "https://api.cognitive.microsoft.com/bing/v5.0/search?q=#{URI.encode(term)}"
        out += get_links(url,r)
      end
      
      out.uniq!
      
      r.checked = true
      if out.count == 1
        r.unique = true
      elsif out.count > 1
        r.unique = false
      else
        r.unique = nil
      end
      
      r.profiles = out
      r.save!
    end
      
    
  end
end
