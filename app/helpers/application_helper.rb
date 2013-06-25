module ApplicationHelper

  def object_options_for_select(object)
    objects = object.to_s.capitalize.constantize.all
    objects_array = objects.map { |object| [object.name, object.id] }
    options_for_select(objects_array)
  end

end
