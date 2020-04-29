
function nodeSelected(src,evt, main_figure)
selNode=src.getSelectedNodes;
%layer_tree_tab_comp=getappdata(main_figure,'Layer_tree_tab');
layers=get_esp3_prop('layers');
layer=get_current_layer();
% fig=ancestor(layer_tree_tab_comp.layer_tree_tab,'figure');
% %
% modifier = get(fig,'SelectionType');
% control = strcmp('open',modifier);
% if ~control
%     return;
% end

if numel(selNode)>1
    return;
end

if ~isempty(selNode)
    selNode=selNode(1);
    userdata=selNode.handle.UserData;
    if isempty(userdata)
        return;
    end
    switch userdata.level
        case 'layer'
            if strcmp(layer.Unique_ID,userdata.ids)
                return;
            end          
            [idx,~]=find_layer_idx(layers,userdata.ids);
            set_esp3_prop('layers',layers);
            set_current_layer(layers(idx));
            check_saved_bot_reg(main_figure);
            loadEcho(main_figure);
    end
end
end