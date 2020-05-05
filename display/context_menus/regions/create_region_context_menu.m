%% create_region_context_menu.m
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
% * |reg_plot|: TODO: write description and info on variable
% * |main_figure|: TODO: write description and info on variable
% * |ID|: TODO: write description and info on variable
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
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function context_menu=create_region_context_menu(reg_plot,main_figure,ID)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);

switch class(ID)
    case 'matlab.graphics.primitive.Patch'
        isreg=0;
        select_plot=ID;
        ID='select_area';
    otherwise
        isreg=1;
        select_plot=trans_obj.get_region_from_Unique_ID(ID);
end

context_menu=uicontextmenu(main_figure,'Tag','RegionContextMenu','UserData',ID);

for ii=1:length(reg_plot)
    reg_plot(ii).UIContextMenu=context_menu;
end

if isreg>0
    region_menu=uimenu(context_menu,'Label','Region');
    uidisp=uimenu(region_menu,'Label','Display');
    uimenu(uidisp,'Label','Region SV','Callback',{@display_region_callback,main_figure,'2D'});
    uimenu(uidisp,'Label','Region Fish Density','Callback',{@display_region_fishdensity_callback,main_figure});
    uimenu(uidisp,'Label','Frequency differences (with other channels)','Callback',{@freq_diff_callback,main_figure});
    uimenu(uidisp,'Label','Region 3D echoes (TS)','Callback',{@display_region_callback,main_figure,'3D'});
    uimenu(uidisp,'Label','Region 3D Sv','Callback',{@display_region_callback,main_figure,'3D_sv'});
    uimenu(uidisp,'Label','Region 3D Single targets','Callback',{@display_region_callback,main_figure,'3D_ST'});
    uimenu(uidisp,'Label','Region 3D Tracked targets','Callback',{@display_region_callback,main_figure,'3D_tracks'});
    
    uifreq=uimenu(region_menu,'Label','Copy to other channels');
    uimenu(uifreq,'Label','all','Callback',{@copy_region_callback,main_figure,[]});
    uimenu(uifreq,'Label','choose which Channel(s)','Callback',{@copy_region_callback,main_figure,1});
    uimenu(region_menu,'Label','Merge Overlapping Regions','CallBack',{@merge_overlapping_regions_callback,main_figure});
    uimenu(region_menu,'Label','Merge Overlapping Regions (per Tag)','CallBack',{@merge_overlapping_regions_per_tag_callback,main_figure});
    uimenu(region_menu,'Label','Merge Selected Regions','CallBack',{@merge_selected_regions_callback,main_figure});
end



analysis_menu=uimenu(context_menu,'Label','Analysis');
uimenu(analysis_menu,'Label','Display Pdf of values','Callback',{@disp_hist_region_callback,select_plot,main_figure});

if isreg>0
    uimenu(analysis_menu,'Label','Classify region','Callback',{@classify_reg_callback,main_figure});

    export_menu=uimenu(context_menu,'Label','Export');
    uimenu(export_menu,'Label','Export integrated region to .xlsx','Callback',{@export_regions_callback,main_figure});
    uimenu(export_menu,'Label','Export Sv values to .xlsx','Callback',{@export_regions_values_callback,main_figure,'selected','sv'});
    uimenu(export_menu,'Label','Export currently displayed values to .xlsx','Callback',{@export_regions_values_callback,main_figure,'selected','curr_data'});
    sub_export_menu=uimenu(export_menu,'Label','XYZ/VRML');
    uimenu(sub_export_menu,'Label','Export region(s) TS Echoes to XYZ or VRML file (current frequency)','Callback',{@export_regions_xyz_callback,main_figure,'TS'},'Tag','current_freq');
    uimenu(sub_export_menu,'Label','Export region(s) TS Echoes to XYZ or VRML file (all frequencies)','Callback',{@export_regions_xyz_callback,main_figure,'TS'},'Tag','all');
    uimenu(sub_export_menu,'Label','Export region(s) current data to XYZ or VRML file (current frequency)','Callback',{@export_regions_xyz_callback,main_figure,'curr_data'},'Tag','current_freq');
    uimenu(sub_export_menu,'Label','Export region(s) current data to XYZ or VRML file (all frequencies)','Callback',{@export_regions_xyz_callback,main_figure,'curr_data'},'Tag','all');
end

uimenu(analysis_menu,'Label','Spectral Analysis (noise)','Callback',{@noise_analysis_callback,select_plot,main_figure});


freq_analysis_menu=uimenu(context_menu,'Label','Frequency Analysis');
uimenu(freq_analysis_menu,'Label','Display TS Frequency response','Callback',{@freq_response_reg_callback,select_plot,main_figure,'sp',0});
uimenu(freq_analysis_menu,'Label','Display Sv Frequency response','Callback',{@freq_response_reg_callback,select_plot,main_figure,'sv',0});
uimenu(freq_analysis_menu,'Label','Display Sliced Sv Frequency response','Callback',{@freq_response_reg_callback,select_plot,main_figure,'sv',1});

if strcmp(trans_obj.Mode,'FM')
    uimenu(freq_analysis_menu,'Label','Create Frequency Matrix Sv','Callback',{@freq_response_mat_callback,select_plot,main_figure});
    uimenu(freq_analysis_menu,'Label','Create Frequency Matrix TS','Callback',{@freq_response_sp_mat_callback,select_plot,main_figure});
end


algo_menu=uimenu(context_menu,'Label','Apply Algorithm ...');
uimenu(algo_menu,'Label','Bottom Detection V1','Callback',{@apply_bottom_detect_cback,select_plot,main_figure,'v1'});
uimenu(algo_menu,'Label','Bottom Detection V2','Callback',{@apply_bottom_detect_cback,select_plot,main_figure,'v2'});

uimenu(algo_menu,'Label','Bottom Features','Callback',{@apply_bottomfeatures_cback,select_plot,main_figure});
uimenu(algo_menu,'Label','Bad Pings Detection','Callback',{@find_bt_cback,select_plot,main_figure,'v2'});
uimenu(algo_menu,'Label','Spikes removal','Callback',{@find_spikes_cback,select_plot,main_figure});
uimenu(algo_menu,'Label','School Detection','Callback',{@apply_school_detect_cback,select_plot,main_figure});
uimenu(algo_menu,'Label','Single Targets Detection','Callback',{@apply_st_detect_cback,select_plot,main_figure});
uimenu(algo_menu,'Label','Target Tracking','Callback',{@apply_track_target_cback,select_plot,main_figure});
uimenu(algo_menu,'Label','Dropouts detection','Callback',{@find_bt_cback,select_plot,main_figure,'dropouts'});

uimenu(context_menu,'Label','Shift Bottom ...','Callback',{@shift_bottom_callback,select_plot,main_figure});
if isreg==0 
    uimenu(context_menu,'Label','Clear Spikes','Callback',{@clear_spikes_cback,select_plot,main_figure});
end

%
% if isreg==0&&~isdeployed()
%     algo_menu=uimenu(context_menu,'Label','"Sliding" Algorithms');
%     uimenu(algo_menu,'Label','Bottom Detection V1','Callback',{@change_userdata_cback,select_plot,'bot_detec_v1'});
%     uimenu(algo_menu,'Label','Bottom Detection V2','Callback',{@change_userdata_cback,select_plot,'bot_detec_v2'});
%     %uimenu(algo_menu,'Label','Bad transmits','Callback',{@change_userdata_cback,select_plot,'bad_transmits'});
%     uimenu(algo_menu,'Label','Disable "Sliding" Algorithm','Callback',{@change_userdata_cback,select_plot,''});
% end


end
function clear_spikes_cback(~,~,select_plot,main_figure)
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~]=layer.get_trans(curr_disp);

switch class(select_plot)
    case 'region_cl'
        reg_obj=trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
    otherwise
        idx_pings=round(nanmin(select_plot.XData)):round(nanmax(select_plot.XData));
        idx_r=round(nanmin(select_plot.YData)):round(nanmax(select_plot.YData));
        reg_obj=region_cl('Name','Select Area','Idx_r',idx_r,'Idx_pings',idx_pings,'Unique_ID','select_area');
end
idx_r = reg_obj.Idx_r;
idx_pings = reg_obj.Idx_pings;

trans_obj.Data.replace_sub_data_v2('spikesmask',false(numel(idx_r),numel(idx_pings)),idx_r,idx_pings);
set_alpha_map(main_figure,'update_under_bot',0,'update_cmap',0);

end

function freq_diff_callback(~,~,main_figure)
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,idx_freq]=layer.get_trans(curr_disp);
IDs=curr_disp.Active_reg_ID;

reg_curr=trans_obj.get_region_from_Unique_ID(IDs);
layer.copy_region_across(idx_freq,reg_curr,[]);

frequencies=layer.Frequencies;
n=length(layer.Frequencies);

output_reg=cell(numel(IDs),n);
CIDs=layer.ChannelID;
for i=1:n
    trans=layer.Transceivers(i);
    
    for j=1:numel(IDs)
        reg=trans.get_region_from_Unique_ID(reg_curr(j).Unique_ID);
        output_reg{j,i}=trans.integrate_region(reg,'keep_bottom',1,'keep_all',1);
    end
end


for j=1:numel(numel(IDs))
    output_reg_1=output_reg{j,idx_freq};
    for i=1:n       
        if i==idx_freq
            continue;
        end
        
        output_reg_2=output_reg{j,i};
        output_diff  = substract_reg_outputs( output_reg_1,output_reg_2);
        CID=layer.Transceivers(i).Config.ChannelID;
        freq=frequencies(strcmpi(CIDs,CID));
        
        if ~isempty(output_diff)
            sv=pow2db_perso(output_diff.Sv_mean_lin(:));
            cax_min=prctile(sv,5);
            cax_max=prctile(sv,95);
            cax=curr_disp.getCaxField('sv');
            
            switch reg_curr.Reference
                case 'Line'
                    line_obj=layer.get_first_line();
                otherwise
                    line_obj=[];
            end
            
            reg_curr(j).display_region(output_diff,'main_figure',main_figure,...
                'alphadata',double(pow2db_perso(output_reg_1.Sv_mean_lin)>cax(1)),...
                'Cax',[cax_min cax_max],...
                'Name',sprintf('%s, %dkHz-%dkHz',reg_curr(j).print,curr_disp.Freq/1e3,freq/1e3),...
                'line_obj',line_obj);
        else
            fprintf('Cannot compute differences %dkHz-%dkHz\n',curr_disp.Freq/1e3,freq/1e3);
        end
    end
end


end




function reg_integrated_callback(~,~,main_figure)
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
[trans_obj,~]=layer.get_trans(curr_disp);

reg_curr=trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
for i=1:numel(reg_curr)
    regCellInt=trans_obj.integrate_region(reg_curr(i));
    if isempty(regCellInt)
        return;
    end
    
    display_region_stat_fig(main_figure,regCellInt);
end
end



function disp_hist_region_callback(src,evt,select_plot,main_figure)
layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');


switch class(select_plot)
    case 'region_cl'
        [trans_obj,~]=layer.get_trans(curr_disp);
        reg_obj=trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
    otherwise
        idx_pings=round(nanmin(select_plot.XData)):round(nanmax(select_plot.XData));
        idx_r=round(nanmin(select_plot.YData)):round(nanmax(select_plot.YData));
        reg_obj=region_cl('Name','Select Area','Idx_r',idx_r,'Idx_pings',idx_pings,'Unique_ID','select_area');
end

trans=layer.get_trans(curr_disp);

for i=1:length(reg_obj)
    reg_curr=reg_obj(i);
    [data,~,~,bad_data_mask,bad_trans_vec,~,below_bot_mask,~]=trans.get_data_from_region(reg_curr,...
        'field',curr_disp.Fieldname);
        
    data(bad_data_mask|below_bot_mask)=nan;
    data(:,bad_trans_vec)=nan;
    
    if ~any(~isnan(data))
        return;
    end
    
    [pdf,x]=pdf_perso(data,'bin',50);
    
    tt=reg_curr.print();
    switch lower(deblank(curr_disp.Fieldname))
        case{'alongangle','acrossangle'}
            xlab=sprintf('Angle (deg)');
        case{'alongphi','acrossphi'}
            xlab='Phase (deg)';
        otherwise
            xlab=sprintf('%s (dB)',curr_disp.Type);
    end
    
    new_echo_figure(main_figure,'Name',sprintf('Region %d Histogram: %s',reg_curr.ID,curr_disp.Type),'Tag',sprintf('histo%s',reg_curr.Unique_ID));
    hold on;
    title(tt);
    bar(x,pdf);
    grid on;
    ylabel('Pdf');
    xlabel(xlab);
    
end

end

