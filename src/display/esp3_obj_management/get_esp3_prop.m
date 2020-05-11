function obj=get_esp3_prop(prop_to_get)

obj=[];
esp3_obj=getappdata(groot,'esp3_obj');

if~isempty(esp3_obj)&&isprop(esp3_obj,prop_to_get)
   obj=esp3_obj.(prop_to_get);
end
