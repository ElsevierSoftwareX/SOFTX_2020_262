%% generate_output_v2.m
%
% Key function for integration of surveys. Everything happens here. It
% needs cleaning, commenting and the output needs to be optimized.
%
%% Helpge
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |surv_obj|: TODO: write description and info on variable
% * |layers|: TODO: write description and info on variable
% * |PathToResults|: TODO: write description and info on variable
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
% * 2017-04-02: header (Alex Schimel).
% * YYYY-MM-DD: first version (Yoann Ladroit). TODO: complete date and comment
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function generate_output_v2(surv_obj,layers,varargin)

p = inputParser;

addRequired(p,'surv_obj',@(obj) isa(obj,'survey_cl'));
addRequired(p,'layers',@(obj) isa(obj,'layer_cl')||isempty(obj));
addParameter(p,'PathToResults',pwd,@ischar);
addParameter(p,'load_bar_comp',[]);
addParameter(p,'fid_log_file',1);
addParameter(p,'gui_main_handle',handle(groot),@ishandle);
parse(p,surv_obj,layers,varargin{:});


surv_input_obj = surv_obj.SurvInput;

fid_error  = p.Results.fid_log_file;

str_strat = sprintf('Integration process for script %s started at %s\n',surv_obj.SurvInput.Infos.Title,datestr(now));
print_errors_and_warnings(fid_error,'',str_strat);
load_bar_comp = p.Results.load_bar_comp;

str_fname = fullfile(p.Results.PathToResults,surv_input_obj.Infos.Title);

war_num = 0;
err_num = 0;
vert_slice = surv_input_obj.Options.Vertical_slice_size;
horz_slice = surv_input_obj.Options.Horizontal_slice_size;

algos_xml = surv_input_obj.Algos;

classified_by_cell = false;

if ~isempty(algos_xml)
    idx_al = find(cellfun(@(x) strcmpi(x.Name,'Classification'),algos_xml),1);
    if ~isempty(idx_al)&&isfield(algos_xml{idx_al}.Varargin,'classification_file')
        try
            class_tree_obj=decision_tree_cl(algos_xml{idx_al}.Varargin.classification_file);
            classified_by_cell = strcmpi(class_tree_obj.ClassificationType,'Cell by cell');
        catch
            warning('Cannot parse specified classification file: %s',algos_xml{idx_al}.Varargin.classification_file);
        end     
    end
end

output = layers.list_layers_survey_data();

[snaps,types,strat,trans,regs_trans,cell_trans] = surv_input_obj.merge_survey_input_for_integration();

strat_grp = findgroups(snaps,types,strat);
trans_grp = findgroups(snaps,types,strat,trans);

reg_nb_vec = cellfun(@length,regs_trans);
surv_out_obj = survey_output_cl(numel(unique(strat_grp)),numel(unique(trans_grp)),nansum(reg_nb_vec));

nb_trans = numel(unique(trans_grp));
snap_temp = [surv_input_obj.Snapshots{:}];
folders = {snap_temp.Folder};
reg_descr_table = [];
idx_lay_processed = [];
i_trans = 0;
i_reg = 0;

if ~isempty(load_bar_comp)
    set(load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',nb_trans,'Value',0);
    load_bar_comp.progress_bar.setText('Integration');
end
block_len = get_block_len(100,'cpu');
disp_str = sprintf('----------------Integration-----------------');
print_errors_and_warnings(fid_error,'',disp_str);
for isn = 1:length(snaps)
    
    try
        snap_num = snaps(isn);
        type_t = types{isn};
        strat_name = strat{isn};
        trans_num = trans(isn);
        regs_tmp = regs_trans{isn};
        cells_tmp = cell_trans{isn};
        
        disp_str = sprintf('Integrating Snapshot %.0f Type %s Stratum %s Transect %d',snap_num,type_t,strat_name,trans_num);
        if ~isempty(load_bar_comp)
            load_bar_comp.progress_bar.setText(disp_str);
        end
        print_errors_and_warnings(fid_error,'',disp_str);
        i_trans = i_trans+1;
       
        att = {'Snapshot' 'Stratum' 'Type' 'Transect'};
        att_val = {snap_num strat_name type_t trans_num};
        idx_lay_bool = cellfun(@(x) any(strcmpi(x,fullfile(folders,'\'))),fullfile(output.Folder,'\'));
        
        for iatt = 1:numel(att_val)
            if ~isempty(att_val{iatt})
                if ischar((att_val{iatt}))
                    if ~isempty(deblank((att_val{iatt})))
                        switch att{iatt}
                            case 'Type'   
                                idx_lay_bool = idx_lay_bool&contains(deblank(output.(att{iatt})),deblank(strsplit(att_val{iatt},';')));
                            otherwise
                                idx_lay_bool = idx_lay_bool&strcmpi(output.(att{iatt}),att_val{iatt});
                        end
                    end
                else
                    if (att_val{iatt})~= 0
                        idx_lay_bool = idx_lay_bool&output.(att{iatt}) == att_val{iatt};
                    end
                end
            end
        end
        
        idx_lay = find(idx_lay_bool);
       [tb,~] = layers(output.Layer_idx(idx_lay)).get_time_bounds;
       [~,idx_lay_sort] = sort(tb);
       idx_lay = idx_lay(idx_lay_sort);
        
        if isempty(idx_lay)
            war_str = sprintf('Could not find layers for Snapshot %.0f Type %s Stratum %s Transect %d\n',snap_num,type_t,strat_name,trans_num);
            print_errors_and_warnings(fid_error,'warning',war_str);
            war_num = war_num+1;
            continue;
        end
        
        idx_lay = setdiff(idx_lay,idx_lay_processed,'stable');
        idx_lay_processed = union(idx_lay_processed,idx_lay);
        
        if isempty(idx_lay)
            fprintf('     Already integrated\n');
            continue;
        end
        
        nb_bad_trans = 0;
        nb_ping_tot = 0;
        
        for i_test_bt = idx_lay
            layer_obj_tr = layers(output.Layer_idx(i_test_bt));

            trans_obj = layer_obj_tr.get_trans(struct('ChannelID',surv_input_obj.Options.Channel,'Freq',surv_input_obj.Options.Frequency));
            [perc_temp,nb_ping_temp] = trans_obj.get_badtrans_perc();
            nb_bad_trans = nb_bad_trans+nb_ping_temp*perc_temp/100;
            nb_ping_tot = nb_ping_tot+nb_ping_temp;
        end
        
        if nb_bad_trans/nb_ping_tot>surv_input_obj.Options.BadTransThr/100
            war_str = sprintf('Too many bad pings on Snapshot %.0f Type %s Stratum %s Transect %d\n',snap_num,type_t,strat_name,trans_num);
            print_errors_and_warnings(fid_error,'warning',war_str);
            war_num = war_num+1;
            continue;
        end
        Output_echo = [];
        
       
        dist_tot = 0;
        timediff_tot = 0;
        nb_good_pings = 0;
        mean_bot_w = 0;
        mean_bot = nan(1,length(idx_lay));
        av_speed = nan(1,length(idx_lay));
        idx_good_pings = [];
        nb_pings_tot = 0;
        iping0 = 0;
        
        
        for i = 1:length(idx_lay)
            layer_obj_tr = layers(output.Layer_idx(idx_lay(i)));
            trans_obj = layer_obj_tr.get_trans(struct('ChannelID',surv_input_obj.Options.Channel,'Freq',surv_input_obj.Options.Frequency));
            tag_add = trans_obj.Bottom.Tag;
            bot_depth_add = trans_obj.get_bottom_depth();
            gps_add = trans_obj.GPSDataPing;
            gps_add.Long(gps_add.Long>180) = gps_add.Long(gps_add.Long>180)-360;
            if i>1
                gps_tot = concatenate_GPSData(gps_tot,gps_add);
            else
                gps_tot = gps_add;
            end
            

            idx_pings = 1:length(gps_add.Time);
            idx_in_transect = find(gps_add.Time(:)>= nanmin(output.StartTime(idx_lay(i)))&gps_add.Time(:)<= nanmax(output.EndTime(idx_lay(i))));
            idx_good_pings_add = intersect(idx_pings,idx_in_transect);
            idx_good_pings_add = intersect(idx_good_pings_add,find(tag_add>0));
            idx_good_pings_dist = intersect(idx_good_pings_add,find(~isnan(gps_add.Lat)));
            
            if ~isempty(idx_good_pings_dist)
                [dist_km,timediff] = gps_add.get_tot_dist_and_time_diff(idx_good_pings_dist);    
                %[dist_km,timediff] = gps_add.get_straigth_dist_and_time_diff(idx_good_pings_dist); 
                dist_add = dist_km/1.852;
            else
                dist_add = 0;
                timediff = 0;
            end
            
            dist_tot = dist_tot+dist_add;
            timediff_tot = timediff_tot+timediff;
            nb_pings_tot = nb_pings_tot+numel(idx_in_transect);
            nb_good_pings = nb_good_pings+length(idx_good_pings_add);
            mean_bot(i) = nanmean(bot_depth_add);
            mean_bot_w = mean_bot_w+mean_bot(i)*length(idx_good_pings_add);
            av_speed(i) = dist_add/timediff;
            idx_good_pings = union(idx_good_pings,idx_good_pings_add+iping0);
            iping0 = iping0+length(idx_pings);
        end
        
        if isempty(idx_good_pings)
            war_str = sprintf('No good pings in Snapshot %.0f Type %s Stratum %s Transect %d\n',snap_num,type_t,strat_name,trans_num);
            print_errors_and_warnings(fid_error,'warning',war_str);
            war_num = war_num+1;
            continue;
        end
        
        av_speed_tot = dist_tot/timediff_tot;
        
        good_bot_tot = mean_bot_w/nb_good_pings;
        
        ir = 0;
        for ilay = idx_lay
            ir = ir+1;
           layer_obj_tr = layers(output.Layer_idx(ilay));
           [trans_obj_tr,idx_freq_main] = layer_obj_tr.get_trans(struct('ChannelID',surv_input_obj.Options.Channel,'Freq',surv_input_obj.Options.Frequency));
           if ~isempty(surv_input_obj.Options.ChannelsToLoad)
                [idx_freq_sec,found] = layer_obj_tr.find_cid_idx(surv_input_obj.Options.ChannelsToLoad);
           else
                [idx_freq_sec,found] = layer_obj_tr.find_freq_idx(surv_input_obj.Options.FrequenciesToLoad);
           end
            idx_freq_sec(found == 0) = [];
            idx_freq_sec = union(idx_freq_sec,idx_freq_main);
            
            gps = trans_obj_tr.GPSDataPing;
            gps.Long(gps.Long>180) = gps.Long(gps.Long>180)-360;
            
            if isnan(good_bot_tot)
                depth = trans_obj_tr.get_transceiver_depth([],[]);
                good_bot_tot = nanmax(depth(:));
            end
            
            if isempty(cells_tmp)
                reg_tot = trans_obj_tr.get_reg_specs_to_integrate(regs_tmp);
                
                if isempty(reg_tot)
                    reg_tot = struct('name','','id',nan,'unique_id',nan,'startDepth',nan,'finishDepth',nan,'startSlice',nan,'finishSlice',nan);
                end
                
                if ~isempty(~strcmp({reg_tot(:).id},''))
                    idx_reg = trans_obj_tr.find_regions_Unique_ID({reg_tot(:).id});
                else
                    idx_reg = [];
                end
            else
                idx_reg = 1:numel(trans_obj_tr.Regions);
            end
            
            
            if ~classified_by_cell
                layer_obj_tr.multi_freq_slice_transect2D(...
                    'survey_options',surv_input_obj.Options,...
                    'idx_main_freq',idx_freq_main,...
                    'idx_sec_freq',idx_freq_sec,...
                    'block_len',block_len,...
                    'timeBounds',[output.StartTime(ilay),output.EndTime(ilay)],...%'load_bar_comp',p.Results.load_bar_comp
                    'idx_regs',idx_reg);
            end

            output_2D_t = layer_obj_tr.EchoIntStruct.output_2D;
            output_2D_type_t = layer_obj_tr.EchoIntStruct.output_2D_type;
            regs_t = layer_obj_tr.EchoIntStruct.regs_tot;
            regCellInt_t = layer_obj_tr.EchoIntStruct.regCellInt_tot;
            reg_descr_table_n = layer_obj_tr.EchoIntStruct.reg_descr_table;
            shadow_height_est_t = layer_obj_tr.EchoIntStruct.shz_height_est;
            idx_freq_out_tot = layer_obj_tr.EchoIntStruct.idx_freq_out;
            
            %%%%%%%%%%
            %         profile off;
            %         profile viewer;
            
            idx_f = idx_freq_main == idx_freq_out_tot;
            
            output_2D = output_2D_t{idx_f};
            output_2D_type = output_2D_type_t{idx_f};
            
            regCellInt = regCellInt_t{idx_f};
            regs = regs_t{idx_f};
            shadow_height_est = shadow_height_est_t{idx_f};
            
            if all(cellfun(@isempty,output_2D))
                war_str = sprintf('Nothing to integrate in Snapshot %.0f Stratum %s Type %s Transect %s in layer %d\n',snap_num,type_t,strat_name,trans_num,ilay);
                print_errors_and_warnings(fid_error,'warning',war_str);
                war_num = war_num+1;
                continue;
            end
            
            if istall(output_2D{1}.eint)
                output_2D = cellfun(@(x) structfun(@gather,x,'un',0),output_2D,'un',0);
                regCellInt = cellfun(@(x) structfun(@gather,x,'un',0),regCellInt,'un',0);
                shadow_height_est = gather(shadow_height_est);
            end
            
            num_slice = size(output_2D{1}.eint,2);
            
            
            slice_int = zeros(1,num_slice);
            good_pings = 0;
            slice_int_sh = zeros(1,num_slice);
            
            for iout = 1:numel(output_2D)
                if ~isempty(cells_tmp)
                   idx_tag_keep = ismember(output_2D{iout}.Tags,cells_tmp);
                   output_2D{iout}.eint(~idx_tag_keep) = 0;
                   output_2D{iout}.sv_mean(~idx_tag_keep) = 0;
                   output_2D{iout}.Sv_dB_std(~idx_tag_keep) = 0;
                   output_2D{iout}.ABC(~idx_tag_keep) = 0;
                   output_2D{iout}.NASC(~idx_tag_keep) = 0;
                end
                
                
                if any(output_2D{iout}.eint(:)>0)&&~isdeployed()&&0
                    disp_str = sprintf('Snapshot %.0f Type %s Stratum %s Transect %d',snap_num,type_t,strat_name,trans_num);
                    reg_tmp = region_cl('Reference',output_2D_type{iout},'Cell_w',vert_slice,...
                        'Cell_w_unit','meters','Cell_h_unit','meters','Cell_h',horz_slice);
                    f_tmp = reg_tmp.display_region(output_2D{iout},'main_figure',p.Results.gui_main_handle);
                    f_tmp.Name = disp_str;
                    pause(1);
                end
                
                if ~strcmpi(output_2D_type{iout},'shadow')
                    slice_int = slice_int+nansum(output_2D{iout}.eint);
                else
                    slice_int_sh = nansum(output_2D{iout}.eint).*shadow_height_est/surv_input_obj.Options.Shadow_zone_height;
                end
                good_pings = nanmax(good_pings,nanmax(output_2D{iout}.Nb_good_pings,[],1));
            end
            

            %reg_descr_table = [reg_descr_table;reg_descr_table_n];
            reg_descr_table = [reg_descr_table;reg_descr_table_n];
            
            if  surv_input_obj.Options.ExportSlicedTransects>0               
                for iout = 1:numel(output_2D_type)
                    if ~isempty(output_2D{iout})  
                        outputFileXLS = generate_valid_filename(sprintf('%s_transect_snap_%d_type_%s_strat_%s_trans_%d_%d_%s%s',str_fname,snap_num,type_t,strat_name,trans_num,ir,output_2D_type{iout},'.csv'));
                    end
                end
                if ~isempty(output_2D{iout})
                    if exist(outputFileXLS,'file')>0
                        delete(outputFileXLS);
                    end
                    
                    sliced_output_table = reg_output_to_table(output_2D{iout});
                    try
                        writetable(sliced_output_table,outputFileXLS);
                    catch err
                        war_str = sprintf('Could not Save sliced output Snapshot %.0f Type %s Stratum %s Transect %d\n',snap_num,type_t,strat_name,trans_num);
                        print_errors_and_warnings(fid_error,'warning',war_str);
                        print_errors_and_warnings(fid_error,'error',err);
                    end
                end                
            end
            
            sliced_output.eint = slice_int;
            sliced_output.slice_abscf = slice_int./good_pings;
            sliced_output.slice_abscf(isnan(sliced_output.slice_abscf)) = 0;
            sliced_output.slice_size = vert_slice;
            sliced_output.num_slices = num_slice;
            sliced_output.shadow_zone_slice_abscf = slice_int_sh./good_pings;
            sliced_output.shadow_zone_slice_abscf(isnan(sliced_output.shadow_zone_slice_abscf)) = 0;
            
            output_2D_ref = output_2D{1};
            
            sliced_output.slice_lat = output_2D_ref.Lat_S;
            sliced_output.slice_lon = output_2D_ref.Lon_S;
            sliced_output.slice_lat_s = output_2D_ref.Lat_S;
            sliced_output.slice_lon_s = output_2D_ref.Lon_S;
            sliced_output.slice_lat_e = output_2D_ref.Lat_E;
            sliced_output.slice_lon_e = output_2D_ref.Lon_E;
            
            sliced_output.slice_time_start = output_2D_ref.Time_S;
            sliced_output.slice_time_end = output_2D_ref.Time_E;
            
            sliced_output.slice_nb_tracks = nansum(output_2D_ref.nb_tracks);
            sliced_output.slice_nb_st = nansum(output_2D_ref.nb_st);
            
            if ~isempty(Output_echo) && nanmax([Output_echo(:).slice_time_end])<sliced_output.slice_time_start(1)
                Output_echo = [Output_echo sliced_output];
            else
                Output_echo = [sliced_output Output_echo];
            end
            
            sliced_output=[];
            
            for j = 1:length(regs)
                
                reg_curr = regs{j};
                regCellInt_r = regCellInt{j};
               
                
                if isempty(regCellInt_r)
                    continue;
                end
                
                if nansum(nansum(nansum(regCellInt_r.eint))) == 0
                    continue;
                end
                
                if ~isempty(cells_tmp) && ~isempty(reg_curr.Tag) && ~ismember(reg_curr.Tag,cells_tmp)
                    continue;
                end
                
                if  surv_input_obj.Options.ExportRegions>0

                    outputFileXLS = generate_valid_filename(sprintf('%s_region_snap_%d_type_%s_strat_%s_trans_%d_%d_%s_%d_%s%s',str_fname,snap_num,type_t,strat_name,trans_num,ir,reg_curr.Reference,reg_curr.ID,reg_curr.Tag,'.csv'));

                    if ~isempty(regCellInt_r)
                        if exist(outputFileXLS,'file')>0
                            delete(outputFileXLS);
                        end
                        
                        reg_output_table = reg_output_to_table(regCellInt_r);
                        writetable(reg_output_table,outputFileXLS);
                    end
                end
                
                
                i_reg = i_reg+1;
                startPing = regCellInt_r.Ping_S(1);
                stopPing = regCellInt_r.Ping_E(end);
                ix = (startPing:stopPing);
                ix_good = intersect(ix,find(trans_obj_tr.Bottom.Tag>0));
                
                
                switch reg_curr.Reference
                    case 'Surface'
                        refType = 's';
                    case 'Bottom'
                        refType = 'b';
                    case 'Transducer'
                        refType = 't';   
                end
                
                if~isnan(nanmin(regCellInt_r.Sample_S(:)))&&~isnan(nanmin(regCellInt_r.Ping_S(:)))
                    start_d = trans_obj_tr.get_transceiver_depth(nanmin(regCellInt_r.Sample_S(:)),nanmin(regCellInt_r.Ping_S(:)));
                else
                    start_d = 0;
                end
                
                if~isnan(nanmin(regCellInt_r.Sample_S(:)))&&~isnan(nanmax(regCellInt_r.Ping_E(:)))
                    finish_d = trans_obj_tr.get_transceiver_depth(nanmin(regCellInt_r.Sample_S(:)),nanmax(regCellInt_r.Ping_S(:)));
                else
                    finish_d = 0;
                end
                
                surv_out_obj.regionsIntegrated.snapshot(i_reg) = snap_num;
                surv_out_obj.regionsIntegrated.stratum{i_reg} = strat_name;
                surv_out_obj.regionsIntegrated.type{i_reg} = type_t;
                surv_out_obj.regionsIntegrated.transect(i_reg) = trans_num;
                
                surv_out_obj.regionsIntegrated.file{i_reg} = layer_obj_tr.Filename;
                surv_out_obj.regionsIntegrated.Region{i_reg} = reg_curr;
                surv_out_obj.regionsIntegrated.RegOutput{i_reg} = regCellInt_r;
                
                surv_out_obj.regionSum.snapshot(i_reg) = snap_num;
                surv_out_obj.regionSumAbscf.snapshot(i_reg) = snap_num;
                surv_out_obj.regionSumVbscf.snapshot(i_reg) = snap_num;
                
                surv_out_obj.regionSum.stratum{i_reg} = strat_name;
                surv_out_obj.regionSumAbscf.stratum{i_reg} = strat_name;
                surv_out_obj.regionSumVbscf.stratum{i_reg} = strat_name;
                
                surv_out_obj.regionSum.type{i_reg} = type_t;
                surv_out_obj.regionSumAbscf.type{i_reg} = type_t;
                surv_out_obj.regionSumVbscf.type{i_reg} = type_t;
                
                surv_out_obj.regionSum.transect(i_reg) = trans_num;
                surv_out_obj.regionSumAbscf.transect(i_reg) = trans_num;
                surv_out_obj.regionSumVbscf.transect(i_reg) = trans_num;
                
                surv_out_obj.regionSum.file{i_reg} = layer_obj_tr.Filename;
                surv_out_obj.regionSumAbscf.file{i_reg} = layer_obj_tr.Filename;
                surv_out_obj.regionSumVbscf.file{i_reg} = layer_obj_tr.Filename;
                
                surv_out_obj.regionSum.region_id(i_reg) = reg_curr.ID;
                surv_out_obj.regionSumAbscf.region_id(i_reg) = reg_curr.ID;
                surv_out_obj.regionSumVbscf.region_id(i_reg) = reg_curr.ID;
                
                %% Region Summary (4th Mbs Output Block)
                surv_out_obj.regionSum.time_end(i_reg) = regCellInt_r.Time_E(end);
                surv_out_obj.regionSum.time_start(i_reg) = regCellInt_r.Time_S(1);
                surv_out_obj.regionSum.ref{i_reg} = refType;
                surv_out_obj.regionSum.slice_size(i_reg) = reg_curr.Cell_h;
                surv_out_obj.regionSum.good_pings(i_reg) = length(ix_good);
                surv_out_obj.regionSum.start_d(i_reg) = start_d;
                surv_out_obj.regionSum.mean_d(i_reg) = mean_bot(ir);
                surv_out_obj.regionSum.finish_d(i_reg) = finish_d;
                surv_out_obj.regionSum.av_speed(i_reg) = av_speed(ir);
                surv_out_obj.regionSum.vbscf(i_reg) = nansum(nansum(regCellInt_r.eint))./nansum(nansum(regCellInt_r.Nb_good_pings.*regCellInt_r.Thickness_mean));
                surv_out_obj.regionSum.abscf(i_reg) = nansum(nansum(regCellInt_r.eint))./nansum(nanmax(regCellInt_r.Nb_good_pings));%Abscf Region
                surv_out_obj.regionSum.tag{i_reg} = reg_curr.Tag;
                
                %% Region Summary (abscf by vertical slice) (5th Mbs Output Block)
                surv_out_obj.regionSumAbscf.time_end{i_reg} = regCellInt_r.Time_E(end);
                surv_out_obj.regionSumAbscf.time_start{i_reg} = regCellInt_r.Time_S(1);
                surv_out_obj.regionSumAbscf.num_v_slices(i_reg) = size(regCellInt_r.eint,2);
                surv_out_obj.regionSumAbscf.transmit_start{i_reg} = regCellInt_r.Ping_S; % transmit Start vertical slice
                surv_out_obj.regionSumAbscf.latitude{i_reg} = regCellInt_r.Lat_S; % lat vertical slice
                surv_out_obj.regionSumAbscf.longitude{i_reg} = regCellInt_r.Lon_S; % lon vertical slice
                surv_out_obj.regionSumAbscf.column_abscf{i_reg} = nansum(regCellInt_r.eint)./nanmax(regCellInt_r.Nb_good_pings);%sum up all abcsf per vertical slice
                
                %% Region vbscf (6th Mbs Output Block)
                surv_out_obj.regionSumVbscf.time_end{i_reg} = regCellInt_r.Time_E;
                surv_out_obj.regionSumVbscf.time_start{i_reg} = regCellInt_r.Time_S;
                surv_out_obj.regionSumVbscf.num_h_slices(i_reg) = size(regCellInt_r.sv_mean,1);% num_h_slices
                surv_out_obj.regionSumVbscf.num_v_slices(i_reg) = size(regCellInt_r.sv_mean,2); % num_v_slices
                tmp = surv_out_obj.regionSum.vbscf(i_reg);
                tmp(isnan(tmp)) = 0;
                surv_out_obj.regionSumVbscf.region_vbscf(i_reg) = tmp; % Vbscf Region
                surv_out_obj.regionSumVbscf.vbscf_values{i_reg} = regCellInt_r.sv_mean; %
                
                %% Region echo integral for Transect Summary
                     
            end%end of regions iteration for this file
            
        end%end of layer iteration for this transect
        

        %% Transect Summary
        if ~all(find(~isnan(gps_tot.Long)))
            idx_s = intersect(idx_good_pings,find(~isnan(gps_tot.Long)));
        else
            idx_s = idx_good_pings;
        end
        if isempty(idx_s)
            idx_s = [1 numel(idx_good_pings)];
        end

        surv_out_obj.transectSum.snapshot(i_trans) = snap_num;
        surv_out_obj.transectSum.stratum{i_trans} = strat_name;
        surv_out_obj.transectSum.type{i_trans} = type_t;
        surv_out_obj.transectSum.transect(i_trans) = trans_num;
        surv_out_obj.transectSum.dist(i_trans) = dist_tot;
        
        surv_out_obj.transectSum.mean_d(i_trans) = nanmean(good_bot_tot); % mean_d
        surv_out_obj.transectSum.pings(i_trans) = numel(idx_good_pings); % pings %
        
        surv_out_obj.transectSum.av_speed(i_trans) = av_speed_tot; % av_speed
        
        surv_out_obj.transectSum.start_lat(i_trans) = gps_tot.Lat(idx_s(1)); % start_lat
        surv_out_obj.transectSum.start_lon(i_trans) = gps_tot.Long(idx_s(1)); % start_lon
        
        surv_out_obj.transectSum.finish_lat(i_trans) = gps_tot.Lat(idx_s(end)); % finish_lat
        surv_out_obj.transectSum.finish_lon(i_trans) = gps_tot.Long(idx_s(end)); % finish_lon
        
        surv_out_obj.transectSum.time_start(i_trans) = gps_tot.Time(idx_s(1)); % finish_lat
        surv_out_obj.transectSum.time_end(i_trans) = gps_tot.Time(idx_s(end)); % finish_lon
        
        surv_out_obj.transectSum.vbscf(i_trans) = nansum([Output_echo(:).eint])/(surv_out_obj.transectSum.mean_d(i_trans)*surv_out_obj.transectSum.pings(i_trans)); % vbscf according to Esp2 formula
        surv_out_obj.transectSum.abscf(i_trans) = nansum([Output_echo(:).eint])/surv_out_obj.transectSum.pings(i_trans); % abscf according to Esp2 formula
        
        surv_out_obj.transectSum.shadow_zone_abscf(i_trans) = nansum([Output_echo(:).shadow_zone_slice_abscf])/surv_out_obj.transectSum.pings(i_trans);
        
        surv_out_obj.transectSum.nb_pings_tot(i_trans) = nb_pings_tot;
        surv_out_obj.transectSum.nb_tracks(i_trans) = nansum([Output_echo(:).slice_nb_tracks]);
        surv_out_obj.transectSum.nb_st(i_trans) = nansum([Output_echo(:).slice_nb_st]);
       
        
        %% Sliced Transect Summary
        surv_out_obj.slicedTransectSum.snapshot(i_trans) = snap_num;
        surv_out_obj.slicedTransectSum.stratum{i_trans} = strat_name;
        surv_out_obj.slicedTransectSum.type{i_trans} = type_t;
        surv_out_obj.slicedTransectSum.transect(i_trans) = trans_num;
        surv_out_obj.slicedTransectSum.slice_size(i_trans) = nanmean([Output_echo(:).slice_size]); % slice_size
        surv_out_obj.slicedTransectSum.num_slices(i_trans) = nansum([Output_echo(:).num_slices]); % num_slices
        
        surv_out_obj.slicedTransectSum.latitude{i_trans} = [Output_echo(:).slice_lat_s]; % latitude
        surv_out_obj.slicedTransectSum.longitude{i_trans} = [Output_echo(:).slice_lon_s]; % longitude
        
        surv_out_obj.slicedTransectSum.latitude_e{i_trans} = [Output_echo(:).slice_lat_e]; % latitude
        surv_out_obj.slicedTransectSum.longitude_e{i_trans} = [Output_echo(:).slice_lon_e]; % longitude
        
        surv_out_obj.slicedTransectSum.time_start{i_trans} = [Output_echo(:).slice_time_start]; %
        surv_out_obj.slicedTransectSum.time_end{i_trans} = [Output_echo(:).slice_time_end]; %
        surv_out_obj.slicedTransectSum.slice_abscf{i_trans} = [Output_echo(:).slice_abscf]; % slice_abscf
        surv_out_obj.slicedTransectSum.slice_nb_tracks{i_trans} = [Output_echo(:).slice_nb_tracks];
        surv_out_obj.slicedTransectSum.slice_nb_st{i_trans} = [Output_echo(:).slice_nb_st];
        slice_shadow_zone_abscf_temp = [Output_echo(:).shadow_zone_slice_abscf];
        slice_shadow_zone_abscf_temp(surv_out_obj.slicedTransectSum.slice_abscf{i_trans} == 0) = 0;
        surv_out_obj.slicedTransectSum.slice_shadow_zone_abscf{i_trans} = slice_shadow_zone_abscf_temp;
    catch err
        war_str = sprintf('Could not Integrate Snapshot %.0f Type %s Stratum %s Transect %d\n',snap_num,type_t,strat_name,trans_num);
        print_errors_and_warnings(fid_error,'warning',war_str);
        print_errors_and_warnings(fid_error,'error',err);
        err_num = err_num+1;
        continue;
    end
    if ~isempty(load_bar_comp)
        set(load_bar_comp.progress_bar,'Value',i_trans);
    end
end


%% Stratum Summary (1st mbs Output block)

i_strat = 0;

snapshots = unique(snaps);

for isn = 1:length(snapshots)
    % loop over all snapshots and get Data subset
    ix = find(surv_out_obj.transectSum.snapshot == snapshots(isn));
    strats = unique(surv_out_obj.transectSum.stratum(ix));
    
    for j = 1:length(strats)
        i_strat = i_strat+1;
        
        jx = strcmpi(surv_out_obj.transectSum.stratum(ix), strats{j});
        idx = ix(jx);
        
        [design,radius] = surv_input_obj.get_start_design_and_radius(snapshots(isn),strats{j});
        i_trans_strat = find(surv_out_obj.slicedTransectSum.snapshot == snapshots(isn)&strcmp(strats{j},surv_out_obj.slicedTransectSum.stratum));
        il = 0;
        slice_trans_obj = surv_out_obj.slicedTransectSum;
        switch design
            case 'hill'
                [~,~,lat_trans,long_trans] = find_centre(slice_trans_obj.latitude(i_trans_strat),...
                    slice_trans_obj.longitude(i_trans_strat));
                
                for it = i_trans_strat
                    il = il+1;
                    [surv_out_obj.slicedTransectSum.slice_hill_weight{it},~,~] = compute_slice_weight_hills(...
                        slice_trans_obj.latitude{it},slice_trans_obj.longitude{it},...
                        slice_trans_obj.latitude_e{it},slice_trans_obj.longitude_e{it},...
                        lat_trans(il),long_trans(il),radius);
                end
            otherwise
                for it = i_trans_strat
                    il = il+1;
                    surv_out_obj.slicedTransectSum.slice_hill_weight{it} = zeros(size(surv_out_obj.slicedTransectSum.latitude{it}));
                end
        end
        
        surv_out_obj.stratumSum.snapshot(i_strat) = surv_out_obj.transectSum.snapshot(idx(1));
        surv_out_obj.stratumSum.stratum{i_strat} = surv_out_obj.transectSum.stratum{idx(1)};
        surv_out_obj.stratumSum.time_start(i_strat) = nanmin(surv_out_obj.transectSum.time_start(idx));
        surv_out_obj.stratumSum.time_end(i_strat) = nanmax(surv_out_obj.transectSum.time_end(idx));
        surv_out_obj.stratumSum.no_transects(i_strat) = length(surv_out_obj.transectSum.transect(idx));
        
        dist = surv_out_obj.transectSum.dist(idx);
        trans_abscf = surv_out_obj.transectSum.abscf(idx);
        trans_abscf_with_shz = trans_abscf+surv_out_obj.transectSum.shadow_zone_abscf(idx);
        
        [surv_out_obj.stratumSum.abscf_mean(i_strat),surv_out_obj.stratumSum.abscf_sd(i_strat)] = calc_abscf_and_sd(trans_abscf);
        [surv_out_obj.stratumSum.abscf_wmean(i_strat),surv_out_obj.stratumSum.abscf_var(i_strat)] = calc_weighted_abscf_and_var(trans_abscf,dist);
        
        [surv_out_obj.stratumSum.abscf_with_shz_mean(i_strat),surv_out_obj.stratumSum.abscf_with_shz_sd(i_strat)] = calc_abscf_and_sd(trans_abscf_with_shz);
        [surv_out_obj.stratumSum.abscf_with_shz_wmean(i_strat),surv_out_obj.stratumSum.abscf_with_shz_var(i_strat)] = calc_weighted_abscf_and_var(trans_abscf_with_shz,dist);
        
        
    end
end

sum_str = sprintf(['Integration process for script %s finished with:\n' ...
'%d Warnings\n'...
'%d Errors\n']...
,surv_obj.SurvInput.Infos.Title,war_num,err_num);

print_errors_and_warnings(fid_error,'',sum_str);

str_end = sprintf('Integration process for script %s finished at %s\n',surv_obj.SurvInput.Infos.Title,datestr(now));
print_errors_and_warnings(fid_error,'',str_end);

surv_obj.SurvOutput = surv_out_obj;

surv_obj.clean_output();

if surv_input_obj.Options.ExportRegions>0&&~isempty(reg_descr_table)
    outputFileXLS = generate_valid_filename(sprintf('%s%s',str_fname,'_reg_descriptors.csv'));
    if exist(outputFileXLS,'file')>1
        delete(outputFileXLS);
    end
    writetable(reg_descr_table,outputFileXLS);
end


end




