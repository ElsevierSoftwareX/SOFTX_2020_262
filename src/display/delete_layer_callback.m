%% delete_layer_callback.m
%
% TODO
%
%% Help
%
% *USE*
%
% TODO
%
% *INPUT VARIABLES*
%
% * |main_figure|: TODO
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO: complete header and in-code commenting
%
% *NEW FEATURES*
%
% * 2017-03-22: header and comments (Alex Schimel)
% * 2017-03-21: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function delete_layer_callback(~,~,main_figure,IDs)
%profile on;
layers=get_esp3_prop('layers');

if isempty(layers)
    return;
end
layer=get_current_layer();
lay_ID=layer.Unique_ID;

if isempty(IDs)
    IDs=layer.Unique_ID;
    check_saved_bot_reg(main_figure);
end

if ~iscell(IDs)
    IDs={IDs};
end

for idi=1:numel(IDs)    
    [idx,found]=find_layer_idx(layers,IDs{idi});
    if found==0
        continue;
    end
    str_cell=list_layers(layers(idx),'nb_char',80);
    try
        fprintf('Deleting temp files from %s\n',str_cell{1});
        layers=layers.delete_layers(IDs{idi});
    catch
        fprintf('Could not clean files from %s\n',str_cell{1});
    end
end

if ~isempty(layers)
    
    set_esp3_prop('layers',layers);
 
    if any(contains(IDs,lay_ID))
        layer=layers(nanmin(idx,length(layers)));
        set_current_layer(layer);
        clear_regions(main_figure,{},{});
        loadEcho(main_figure);
    else
        update_tree_layer_tab(main_figure);
    end
    
else
  
    
    layer_obj=layer_cl.empty();
    set_esp3_prop('layers',layers);
    set_current_layer(layer_obj);
    
    update_display_no_layers(main_figure);
    

end
update_map_tab(main_figure);
%profile off;
%profile viewer;


end