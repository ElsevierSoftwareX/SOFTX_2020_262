%% change_layer_callback.m
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
% * |id|: TODO
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
function change_layer_callback(~,~,main_figure,id)

layers=get_esp3_prop('layers');
if isempty(layers)
    return;
end
layer=get_current_layer();

if isempty(layer)||~isvalid(layer)
    layer=layers(1);
    set_current_layer(layer);
    return;
end

curr_ids=layer.Unique_ID;
layer_tree_tab_comp=getappdata(main_figure,'Layer_tree_tab');


node_out=find_child(layer_tree_tab_comp.root_node,curr_ids);

if isempty(node_out)
    return;
end

switch id
    case 'next'
       node=node_out.getNextSibling;
    case 'prev'
       node=node_out.getPreviousSibling;
end

if isempty(node)
    node_parent=node_out.getParent;
    switch id
        case 'next'
            node_p=node_parent.getNextSibling;
            if ~isempty(node_p)
                node=node_p.getFirstChild;
            end
        case 'prev'
            node_p=node_parent.getPreviousSibling;
            if ~isempty(node_p)
                node=node_p.getLastChild;
            end
    end
end

if ~isempty(node)
    layer_tree_tab_comp.tree_h.setSelectedNode(node);
    userdata=node.handle.UserData;
    if isempty(userdata)
        return;
    end
    switch userdata.level
        case 'layer'
            if strcmp(layer.Unique_ID,userdata.ids)
                return;
            end
            [idx,~]=layers.find_layer_idx(userdata.ids);
            set_esp3_prop('layers',layers);
            set_current_layer(layers(idx));

            check_saved_bot_reg(main_figure);
            loadEcho(main_figure);
    end
end


end


function node_out=find_child(node,id)
node_out=[];
if node.isLeaf
    return;
end
    
ic=node.getChildCount;

for in=1:ic 
    node_child=node.getChildAt(in-1);
    usrdata=node_child.handle.UserData;
    if iscell(usrdata.ids)
        if any(strcmp(usrdata.ids,id))
            node_out=find_child(node_child,id);
        end
    elseif ischar(usrdata.ids)
        if strcmp(usrdata.ids,id)
            node_out=node_child;
            return;
        end
    end    
end


end