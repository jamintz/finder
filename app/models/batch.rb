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
             if x == 'profiles'
               h << JSON.parse(r[x])
             else
               h << r[x]
             end
           end
           csv << h.flatten
      end
    end
    
    
  end
    
end