function set_current_layer(lay_obj)
esp3_obj=getappdata(groot,'esp3_obj');

if~isempty(esp3_obj)
   esp3_obj.set_layer(lay_obj);
end

end