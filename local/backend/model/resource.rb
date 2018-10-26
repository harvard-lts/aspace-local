Resource.class_eval do

def validate
  super
  validates_presence(:ead_id, :message => "You must provide an eadid")
end

end
