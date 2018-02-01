class HomeController < ApplicationController
  require 'csv'
  
  def upload
    if params['file']
      file = params['file']
      HardWorker.perform_async(file_path=file.path)
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
