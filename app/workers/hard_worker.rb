class HardWorker
  include Sidekiq::Worker
  require 'csv'
  require 'net/http'
  require 'fuzzy_match'
  
  def get_links(url,r)
    key = '86a28e1d290341a698bc74b295a0b0ec'
    
    uri = URI(url)
    req = Net::HTTP::Get.new(uri.request_uri)
    req.add_field("Ocp-Apim-Subscription-Key", key)
    res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https'){|http|http.request(req)}
    body = JSON.parse(res.body, :symbolize_names => true)
    results = []
    if body[:webPages] && body[:webPages][:value]
      results = body[:webPages][:value].select{|x|x[:name] && x[:name].downcase.include?(r.name.downcase) && x[:displayUrl] && x[:displayUrl].include?('linkedin.com')&&!x[:displayUrl].include?('/dir/')}
      if results.empty?
        results = body[:webPages][:value].select{|x|x[:name] && x[:name].downcase.include?(r.lastname.downcase) && x[:displayUrl] && x[:displayUrl].include?('linkedin.com')&&!x[:displayUrl].include?('/dir/')}
        if !results.empty?
          results.each do |res|
            rec = res[:name]
            pp rec
            pp score
            pp ""
            score = 0
            down = rec.downcase
            fn = down.split(r.lastname).first.strip
            score += 5 if FuzzyMatch.new([fn]).find(r.firstname)
            score += 3 if down.include?(r.business.downcase)
            score += 2 if down.include?(r.jobtitle.downcase)
            results.delete(res) if score < 5 
          end     
        end
      end
    end
    
    profiles = results.map{|x|x[:displayUrl]}
    out = []
    profiles.each do |p|
      broke=(p.split("://").first+"://www.linkedin.com"+p.split("linkedin.com").last).split("in/")
      out << broke.first+"in/"+broke.last.split("/").first
    end
    return out.uniq
  end

  def perform(bid)
    b = Batch.find(bid)
    b.rows.each do |r|
      terms = [
        ["www.linkedin.com #{r.name} #{r.business} \"#{r.school}\" #{r.jobtitle}",'all'],
        ["www.linkedin.com #{r.name} #{r.business} \"#{r.school}\"",'name/biz/school'],
        ["www.linkedin.com #{r.name} #{r.business} #{r.jobtitle}",'name/biz/jobtitle'],
        ["www.linkedin.com #{r.name} #{r.business} #{r.city}",'name/biz/city']]
        
        allout = []
        
        output = nil
        reason = nil
        terms.each_with_index do |t,i|
          
          if i == 0 && (r.school.nil? || r.jobtitle.nil?)
            allout << []
            next
          end
          if i == 1 && r.school.nil?
            allout << []
            next
          end
          if i == 2 && r.jobtitle.nil?
            allout << []
            next
          end
          if i == 3 && r.city.nil?
            allout << []
            next
          end
            
          url = "https://api.cognitive.microsoft.com/bing/v5.0/search?q=#{URI.encode(t.first)}"
          out = get_links(url,r)
          out.compact.uniq!
          
          allout << out    
          if out.count == 1
            output = out
            reason = t.last
            break
          end
        end
        
        if !output && !allout.empty?
          h = Hash.new(0)
          allout2 = allout.flatten.compact
          allout2.each{|x|h[x]+=1}
          sort = h.sort_by{|_,v|v}
          max = sort.last.last
          top = h.select{|_,v|v==max}
          
          if top.count == 1
            output = top.keys
            reason = 'most common across all'
          else
            allout.each_with_index do |x,i|
              if !x.empty?
                output = x
                reason = "#{terms[i].last} best multiple"
              end
            end
          end
        end

      r.checked = true
      if output.count == 1
        r.unique = true
      elsif output.count > 1
        r.unique = false
      else
        r.unique = nil
      end
      r.pro_path = reason
      r.profiles = output
      r.save!
    end
      
    
  end
end
