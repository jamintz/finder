class HomeController < ApplicationController
  require 'csv'
  
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
      head = head.map{|w|w.downcase}
      fn = head.index('fullname')
      bus = head.index('business')
      sch = head.index('school')
    
      if fn && bus && sch
        all.each do |a|
          b.rows.find_or_create_by(name:a[fn],school:a[sch],business:a[bus])
        end
      end
      
      HardWorker.perform_async(batch=b.id)
      flash[:notice] = 'File Uploaded'
    else
      flash[:notice] = 'Error'
    end
    redirect_to '/'
    
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
