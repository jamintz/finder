class HomeController < ApplicationController
  require 'csv'
  require 'human_name_parser'
  
  def upload
    if params['file']
      file = params['file']
      all = []
      
      file_path = file.path
      puts "starting csv"
      CSV.foreach(file_path, headers: false, encoding:'iso-8859-1:utf-8') do |row|
        all << row
      end
      puts "ending csv"
      b = Batch.create
    
      head = all.shift
      head = head.map{|w|w.downcase if w}
      fn = head.index('fullname')
      bus = head.index('business')
      sch = head.index('school')
      jt = head.index('jobtitle')
      cit = head.index('city')
    
      if fn && bus
        all.each do |a|
          r = b.rows.find_or_create_by(name:a[fn],business:a[bus])
          parsed = HumanNameParser.parse(r.name)
          r.firstname = parsed.first.downcase
          r.lastname = parsed.last.downcase
          r.jobtitle = a[jt] if jt
          r.school = a[sch] if sch
          r.city = a[cit] if cit
          r.save!
        end
        HardWorker.perform_async(batch=b.id)
        flash[:notice] = 'File Uploaded'
      else
        debugger
        flash[:notice] = 'Error'
      end
      redirect_to '/'
    end
  end

  def index
    @batches = Batch.all
  end
  
  def download

    respond_to do |format|
      format.html
      format.csv { send_data Batch.to_csv(params)}
     end
  end
  
  def delete
    b = Batch.find(params['batch'])
    b.destroy
    flash[:notice] = 'Batch Destroyed'
    redirect_to '/'
  end
  
end
