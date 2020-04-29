function clear_curves_callback(~,~,main_figure)
layer=get_current_layer();

if isempty(layer)
return;
end
    

layer.clear_curves();

end