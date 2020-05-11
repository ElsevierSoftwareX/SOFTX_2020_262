function set_esp3_prop(prop_to_set,val)
esp3_obj=getappdata(groot,'esp3_obj');

if~isempty(esp3_obj)&&isprop(esp3_obj,prop_to_set)
   esp3_obj.(prop_to_set) = val;
end

end