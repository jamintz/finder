class HardWorker
  include Sidekiq::Worker
  require 'csv'
  require 'net/http'

  def perform(bid)
    key = '86a28e1d290341a698bc74b295a0b0ec'
    
    # all = []
#     CSV.foreach(file_path, headers: false, encoding:'iso-8859-1:utf-8') do |row|
#       all << row
#     end
#
#     b = Batch.create
#
#     head = all.shift
#     head = head.map{|w|w.downcase}
#     fn = head.index('fullname')
#     bus = head.index('business')
#     sch = head.index('school')
#
#     if fn && bus && sch
#       all.each do |a|
#         b.rows.find_or_create_by(name:a[fn],school:a[sch],business:a[bus])
#       end
#     end
#
b = Batch.find(bid)
    b.rows.each do |r|
      term = "linkedin #{r.name} \"#{r.school}\" #{r.business}"
      url = "https://api.cognitive.microsoft.com/bing/v5.0/search?q=#{URI.encode(term)}"
            
      uri = URI(url)
      req = Net::HTTP::Get.new(uri.request_uri)
      req.add_field("Ocp-Apim-Subscription-Key", key)
      res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https'){|http|http.request(req)}
      body = JSON.parse(res.body, :symbolize_names => true)
          
      results = body[:webPages][:value].select{|x|x[:name].downcase.include?(r.name.downcase)&&x[:displayUrl].include?('linkedin.com')&&!x[:displayUrl].include?('/dir/')}
      profiles = results.map{|x|x[:displayUrl]}
      out = []
      profiles.each do |p|
        broke=(p.split("://").first+"://www.linkedin.com"+p.split("linkedin.com").last).split("in/")
        out << broke.first+broke.last.split("/").first
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
