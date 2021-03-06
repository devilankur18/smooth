class Smooth::ActiveRecordBackend < Smooth::Backend
  def initialize(options={})
    @prepared = @processed = true
    super
  end

  def all
    active_record.all
  end

  def active_record
    Smooth::Model.find_active_record_for(model_class)
  end

  def create attributes={}
    model = active_record.create!(attributes)
    model
  end

  def show id
    model = active_record.find(id)
    model
  end

  def update id, attributes
    active_record.find(id)
    model && model.update_attributes(attributes)
    model
  end

  def destroy id
    model = active_record.find(id)
    model && model.destroy
    model
  end
end
