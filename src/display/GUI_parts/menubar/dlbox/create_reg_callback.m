%% Create Region button callback
function create_reg_callback(~,~,reg_fig_comp,main_figure,reg_fig)

layer = get_current_layer();

curr_disp=get_esp3_prop('curr_disp');

[trans_obj,idx_freq]=layer.get_trans(curr_disp);
if isempty(trans_obj)
    return;
end


ref = get(reg_fig_comp.tog_ref,'String');
ref_idx = get(reg_fig_comp.tog_ref,'value');

data_type = get(reg_fig_comp.data_type,'String');
data_type_idx = get(reg_fig_comp.data_type,'value');

h_units = get(reg_fig_comp.cell_h_unit,'String');
h_units_idx = get(reg_fig_comp.cell_h_unit,'value');

w_units = get(reg_fig_comp.cell_w_unit,'String');
w_units_idx = get(reg_fig_comp.cell_w_unit,'value');

y_min = str2double(get(reg_fig_comp.y_min,'string'));
y_max = str2double(get(reg_fig_comp.y_max,'string'));

if y_max<=y_min
    warning('Incorrect Parameters (y_max<y_min)')
    return;
end

% create the WC region in trans object
reg_wc = trans_obj.create_WC_region(...
    'y_min',y_min,...
    'y_max',y_max,...
    'Type',data_type{data_type_idx},...
    'Ref',ref{ref_idx},...
    'Cell_w',str2double(get(reg_fig_comp.cell_w,'string')),...
    'Cell_h',str2double(get(reg_fig_comp.cell_h,'string')),...
    'Cell_w_unit',w_units{w_units_idx},...
    'Cell_h_unit',h_units{h_units_idx});

trans_obj.add_region(reg_wc);

close(reg_fig);


display_regions('both');

curr_disp=get_esp3_prop('curr_disp');

curr_disp.setActive_reg_ID({});

end