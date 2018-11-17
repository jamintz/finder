class HardWorker
  include Sidekiq::Worker
  require 'csv'
  require 'net/http'
  require 'fuzzy_match'
  require 'httparty'
  
  BAD_STARTS = ['sales','info','help','contact','support']
  BAD_ENDS = ['finance.yahoo.com']
  
  def get_links(url,r)
    key = '10208e071a144c28a5a650c29206de61'
    
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
          results.uniq!
          scores = []
          results.each do |res|
            rec = res[:name]
            score = 0
            down = rec.downcase
            fn = down.split(r.lastname).first.strip
            score += 5 if FuzzyMatch.new([fn]).find(r.firstname)
            score += 3 if r.business && down.include?(r.business.downcase)
            score += 2 if r.jobtitle && down.include?(r.jobtitle.downcase)
            scores << score
          end     
          ts = scores.max
          results.each_with_index{|x,i|results.delete(x) if scores[i] < ts}
        end
      end
    end
    
    profiles = results.map{|x|x[:displayUrl]}
    profiles.reject!{|x|!x.include?('//www.linkedin.com')} if profiles.any?{|x|x.include?('//www.linkedin.com')}
    out = []
    profiles.each do |p|
      broke=(p.split("://").first+"://www.linkedin.com"+p.split("linkedin.com").last).split("in/")
      out << broke.first+"in/"+broke.last.split("/").first
    end
    return out.uniq
  end
  
  def get_email first,last,company
      key = '2d25df043bdd7f08b70ed1fdcbcb827667fa759d'
      company = URI.encode(company)
      url = "https://api.hunter.io/v2/email-finder?company=#{company}&first_name=#{URI.encode(first)}&last_name=#{URI.encode(last)}&api_key=#{key}"
      resp = HTTParty.get(url)
      if resp['data'] && resp['data']['score'] && resp['data']['score'] > 85
        return resp
      end
  end
  
  def check_valid email
    return nil if BAD_STARTS.include?(email.split('@').first)
    return nil if BAD_ENDS.include?(email.split('@').last)
    
    zerokey = '97adac03bf7f40d89ffc742a188e5266'
    
    checkURL = "https://api.zerobounce.net/v1/getcredits?apikey=#{zerokey}"
    resp = HTTParty.get(checkURL)
    credits = JSON.parse(resp.body)['Credits'].to_i
    
    valURL = "https://api.zerobounce.net/v1/validate?apikey=#{zerokey}&email=#{URI.encode(email)}"
    resp = HTTParty.get(valURL)
    valid = JSON.parse(resp.body)['status']
    
    return valid
  end

  def perform(bid)
    b = Batch.find(bid)
    b.rows.each do |r|
      
      if r.business && r.firstname && r.lastname
        em = get_email(r.firstname,r.lastname,r.business)
        if em
          email = em['data']['email']
          if email
            check = check_valid(email)
            if check == 'Valid'
              r.email = email
            end
          end
        end
      end
      
      terms = [
        ["linkedin #{r.name} #{r.business} \"#{r.school}\" #{r.jobtitle}",'all'],
        ["linkedin #{r.name} #{r.business} \"#{r.school}\"",'name/biz/school'],
        ["linkedin #{r.name} #{r.business} #{r.jobtitle}",'name/biz/jobtitle'],
        ["linkedin #{r.name} #{r.business} #{r.city}",'name/biz/city']]
                
        allout = []
        
        output = []
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
            
          url = "https://api.cognitive.microsoft.com/bing/v7.0/search?q=#{URI.encode(t.first)}"
          out = get_links(url,r)
          out.compact.uniq!
          
          allout << out    
          if out.count == 1
            output = out
            reason = t.last
            break
          end
        end
        
        if output.empty? && !allout.flatten.compact.empty?
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
