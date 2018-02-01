class Batch < ApplicationRecord
  has_many :rows, dependent: :destroy
  
  def self.to_csv params
    b = Batch.find(params['batch'])
    
    head = ['name','school','business','profiles']
    CSV.generate({}) do |csv|
      csv << head
      b.rows.each do |r|
           h = []
           head.each do |x|
             h << r[x]
           end
           csv << h
      end
    end
    
    
  end
    
end
