function lay=get_current_layer()

esp3_obj=getappdata(groot,'esp3_obj');

if~isempty(esp3_obj)
   lay=esp3_obj.get_layer();
else
    lay=layer_cl.empty();
end

end