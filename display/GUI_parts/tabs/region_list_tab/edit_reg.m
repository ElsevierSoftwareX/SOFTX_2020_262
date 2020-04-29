%% edit_reg.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |src|: TODO: write description and info on variable
% * |evt|: TODO: write description and info on variable
% * |main_figure|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-03-28: header (Alex Schimel)
% * 2017-03-28: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function edit_reg(src,evt,main_figure)

if isempty(evt.Indices)
    return;
end

layer=get_current_layer();

if isempty(layer)
    return;
end

uid=src.Data{evt.Indices(1,1),10};

fields={'ID' 'Cell_w' 'Cell_h'};
col_num=[2 6 8];

for ifi=1:numel(fields)
    id=src.Data{evt.Indices(1,1),col_num(ifi)};
    if ~isnan(id)&&id>=0
        layer.set_field_to_region_with_uid(uid,fields{ifi},id);
    elseif evt.Indices(1,2)==col_num(ifi)
        src.Data{evt.Indices(1,1),col_num(ifi)}=evt.PreviousData;
    end   
end

fields={'Name' 'Tag' 'Type' 'Reference' 'Cell_w_unit' 'Cell_h_unit'};
col_num=[1 3 4 5 7 9];

for ifi=1:numel(fields)
    id=src.Data{evt.Indices(1,1),col_num(ifi)};
    layer.set_field_to_region_with_uid(uid,fields{ifi},id);
end

display_regions(main_figure,'all');

activate_region_callback(uid,main_figure);

if ~isempty(layer.Curves)
    idx=find(contains({layer.Curves(:).Unique_ID},uid));
    if ~isempty(idx)
        for ic=idx
            layer.Curves(ic).Tag=src.Data{evt.Indices(1,1),3};
        end
        update_curves_and_table(main_figure,'sv_f',uid);
        update_curves_and_table(main_figure,'ts_f',uid);
    end
end
order_stacks_fig(main_figure);

end
