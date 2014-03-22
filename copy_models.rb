# This lib should create a file (or string) from all relations inside a rails app, 
# and should use that input string/file for creating those relations
# Example (will change obsiously)

# Relations
# hm => Has Many
# ho => Has One
# bt => Belongs To
# habtm => Has And Belongs To Many

# {
#   model_0 => 
#     relations => {'hm' => [model_1, model_2], 'bt' => [model_3]}, 
#     delete_data_before_create => true/false,
#     delete_when_collision_found => true/false,
#     exclude_columns => ['created_at', 'updated_at'],
#     reuse_if_found => true/false,
# }

relations = {
  admin_users: {
    exclude_columns: ['created_at', 'updated_at'],
    relations: {
      bt: [:users]
    }
  },
  agents: {
    exclude_columns: ['created_at', 'updated_at'],
    relations: {
      bt: [:admin_users, :natural_people]
    }
  }
}

def create_backup(relations, file_route = nil)
  backup = {relations_hash: relations, data: {}}
  relations.each do |relation_model,relation_data|
    relation_model.to_s.singularize.camelcase.constantize.all.each do |mod|
      attribs = mod.attributes
      attribs.delete_if{|a,v| a.in? relation_data[:exclude_columns]} if relation_data[:exclude_columns]
      backup[:data][relation_model] ||= []
      backup[:data][relation_model] << attribs
    end
  end
  related_models = relations.map{|k,v| v[:relations].collect{|kind,models| models } if v[:relations] }.flatten.uniq
  related_models.reject!{|model| model.in? relations.keys }
  related_models.each do |model|
    model.to_s.singularize.camelcase.constantize.all.each do |mod|
      backup[:data][model] ||= []
      backup[:data][model] << mod.attributes
    end
  end
  backup
end

def apply_backup(input)
  relations = input[:relations]
  data = input[:data]
  relations.each do |relation_model, relation_data|
    model = relation_model.to_s.singularize.camelcase.constantize
    data[relation_model].each do |model_data|
      m = model.new
      m.attributes = model_data
      m.save(validate:false)
    end
  end
end

def get_fk(model, relation)
  case relation
  when :hm, :ho, :habtm
    "#{model}_id"
  end
end



