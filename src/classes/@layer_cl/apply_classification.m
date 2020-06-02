function output_struct=apply_classification(layer,varargin)

default_l_min_tot=25;
check_l_min_tot=@(l)(l>=0);

default_h_min_tot=10;
check_h_min_tot=@(l)(l>=0);

default_horz_link_max=55;
check_horz_link_max=@(l)(l>=0&&l<=1000);

default_vert_link_max=5;
check_vert_link_max=@(l)(l>=0&&l<=500);


p = inputParser;

addRequired(p,'layer',@(x) isa(x,'layer_cl'));
addParameter(p,'classification_file','',@ischar);
addParameter(p,'ref','Surface',@(x) ismember(x,{'Surface' 'Transducer' 'Bottom'}));
addParameter(p,'timeBounds',[0 inf],@isnumeric);
addParameter(p,'create_regions',true,@islogical);
addParameter(p,'cluster_tags',true,@islogical);
addParameter(p,'thr_cluster',10,@isnumeric);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'l_min_tot',default_l_min_tot,check_l_min_tot);
addParameter(p,'h_min_tot',default_h_min_tot,check_h_min_tot);
addParameter(p,'horz_link_max',default_horz_link_max,check_horz_link_max);
addParameter(p,'vert_link_max',default_vert_link_max,check_vert_link_max);
addParameter(p,'survey_options',layer.get_survey_options(),@(x) isa(x,'survey_options_cl'));
addParameter(p,'load_bar_comp',[]);


parse(p,layer,varargin{:});
surv_opt_obj = p.Results.survey_options;

primary_freq=surv_opt_obj.Frequency;
reg_obj=p.Results.reg_obj;

output_struct.school_struct=[];
output_struct.out_type={};
output_struct.done=false;

classification_file=p.Results.classification_file;

if isempty(classification_file)||~isfile(classification_file)
    warndlg_perso([],'',sprintf('Cannot find classification file %s.',classification_file));
    return;
end


[trans_obj_primary,idx_primary_freq]=layer.get_trans(primary_freq);
if isempty(trans_obj_primary)
    warndlg_perso([],'',sprintf('Cannot find %dkHz! Cannot apply classification here....',primary_freq/1e3));
    return;
end

if exist(classification_file,'file')>0
    try
        class_tree_obj=decision_tree_cl(classification_file);
    catch
        warndlg_perso([],'Warning',sprintf('Cannot parse specified classification file: %s',classification_file));
        return;
    end
else
    warndlg_perso([],'Warning',sprintf('Cannot find specified classification file: %s',classification_file));
    return;
end

switch lower(class_tree_obj.ClassificationType)
    case 'by regions'
        if isempty(reg_obj)
            idx_schools=trans_obj_primary.find_regions_type('Data');
            if isempty(idx_schools)
                warndlg_perso([],'',sprintf('No regions defined on %dkHz!',primary_freq/1e3));
            end
        else
            idx_schools=trans_obj_primary.find_regions_Unique_ID(reg_obj.Unique_ID);
        end
        
        nb_schools=numel(idx_schools);
        output_struct.school_struct=cell(nb_schools,1);
        surv_opt_obj.IntRef='';
        surv_opt_obj.IntType='Regions only';
        
    case 'cell by cell'
        nb_schools=0;
        idx_schools=[];
        output_struct.school_struct=[];
        surv_opt_obj.IntRef=p.Results.ref;
        if isempty(reg_obj)
            surv_opt_obj.IntType='WC';
        else
            surv_opt_obj.IntType='By regions';
        end
    otherwise
         warndlg_perso([],'Warning',sprintf('Un regognized ClassificationType in classification file: %s\n Should be "Cell by cell" or "By regions"',classification_file));
        return;
        
end


%freqs=class_tree_obj.get_frequencies();
vars=class_tree_obj.get_variables();

sv_freqs=cellfun(@(x) textscan(x,'Sv_%d'),vars,'un',1);
delta_sv_freqs=cellfun(@(x) textscan(x,'delta_Sv_%d_%d'),vars,'un',0);

idx_var_freq=find(cellfun(@(x) ~any(isempty(x)),sv_freqs));
idx_var_freq_sec=find(cellfun(@(x) ~any(isempty([x{:}])),delta_sv_freqs));

primary_freqs_sv = [sv_freqs{idx_var_freq}];

primary_freqs_delta = cellfun(@(x) [x{1}],delta_sv_freqs(idx_var_freq_sec));
sec_freqs_delta = cellfun(@(x) [x{2}],delta_sv_freqs(idx_var_freq_sec));

primary_freqs = double([primary_freqs_delta setdiff(primary_freqs_sv,primary_freqs_delta)]);
primary_freqs = primary_freqs*1e3;
secondary_freqs = nan(1,numel(primary_freqs));
secondary_freqs(1:numel(sec_freqs_delta)) = double(sec_freqs_delta);
secondary_freqs = secondary_freqs*1e3;
idx_primary_freqs=nan(1,numel(primary_freqs));
idx_secondary_freqs=nan(1,numel(primary_freqs));


for ii=1:numel(primary_freqs)
    
    
    [idx_primary_freqs(ii),found]=find_freq_idx(layer,primary_freqs(ii));
    
    if ~found
        warning('Cannot find %dkHz! Cannot apply classification here....',primary_freqs(ii)/1e3);
        return;
    end
    if ~isnan(secondary_freqs(ii))
        [idx_secondary_freqs(ii),found]=find_freq_idx(layer,secondary_freqs(ii));
        if ~found
            warning('Cannot find %dkHz! Cannot apply classification here....',secondary_freqs(ii)/1e3);
            return;
        end
    end
end

idx_freq_tot=union(idx_primary_freqs,idx_secondary_freqs);
idx_freq_tot(isnan(idx_freq_tot))=[];

reslice = true;
%reslice = false;

if reslice
    layer.multi_freq_slice_transect2D(...
        'idx_regs',idx_schools,...
        'timeBounds',p.Results.timeBounds,...
        'regs',p.Results.reg_obj,...
        'idx_main_freq',idx_primary_freq,...
        'idx_sec_freq',idx_freq_tot,...
        'tag_sliced_output',false,...
        'keep_all',1,...
        'keep_bottom',1,...
        'survey_options',surv_opt_obj,...
        'load_bar_comp',p.Results.load_bar_comp);
end

switch lower(class_tree_obj.ClassificationType)
    case 'by regions'
        for jj=1:nb_schools
            for ii=1:numel(primary_freqs)
                i_freq_p=layer.EchoIntStruct.idx_freq_out==idx_primary_freqs(ii);
                output_reg_p=layer.EchoIntStruct.regCellInt_tot{i_freq_p}{jj};
                output_struct.school_struct{jj}.(sprintf('Sv_%d',primary_freqs(ii)/1e3))=pow2db_perso(nanmean(output_reg_p.sv_mean(:)));
                
                if ~isnan(idx_secondary_freqs(ii))
                    i_freq_s=layer.EchoIntStruct.idx_freq_out==idx_secondary_freqs(ii);
                    output_reg_s=layer.EchoIntStruct.regCellInt_tot{i_freq_s}{jj};
                    ns=numel(output_reg_s.nb_samples(:));
                    np=numel(output_reg_p.nb_samples(:));
                    n=nanmin(ns,np);
                    delta_temp=nanmean(pow2db_perso(output_reg_p.sv_mean(1:n))-pow2db_perso(output_reg_s.sv_mean(1:n)));
                    delta_temp(isnan(delta_temp))=0;
                    output_struct.school_struct{jj}.(sprintf('delta_Sv_%d_%d',primary_freqs(ii)/1e3,secondary_freqs(ii)/1e3))=delta_temp;
                    output_struct.school_struct{jj}.(sprintf('Sv_%d',secondary_freqs(ii)/1e3))=pow2db_perso(nanmean(output_reg_p.sv_mean(:)));
                end
            end
            
            output_struct.school_struct{jj}.nb_cell=length(~isnan(output_reg_p.sv_mean(:)));
            output_struct.school_struct{jj}.aggregation_depth_mean=nanmean(output_reg_p.Depth_mean(:));
            output_struct.school_struct{jj}.aggregation_depth_min=nanmax(output_reg_p.Depth_mean(:));
            output_struct.school_struct{jj}.bottom_depth=nanmean(trans_obj_primary.get_bottom_range(output_reg_p.Ping_S(1):output_reg_p.Ping_E(end)));
            output_struct.school_struct{jj}.lat_mean=nanmean(output_reg_p.Lat_E(:));
            output_struct.school_struct{jj}.lon_mean=nanmean(output_reg_p.Lon_E(:));
        end
        
    case 'cell by cell'
        idx_main=find(idx_primary_freq==layer.EchoIntStruct.idx_freq_out);
        output_struct.school_struct=cell(1,numel(layer.EchoIntStruct.output_2D{idx_main}));
        
        for ui=1:numel(output_struct.school_struct)
            output_struct.school_struct{ui}=layer.EchoIntStruct.output_2D{idx_main}{ui};
            output_struct.out_type{ui}=layer.EchoIntStruct.output_2D_type{idx_main}{ui};
            for ip=1:numel(primary_freqs)
                
                if idx_primary_freq==idx_primary_freqs(ip)
                    tmp=pow2db_perso(output_struct.school_struct{ui}.sv_mean);
                else
                    tmp=pow2db_perso(output_struct.school_struct{ui}.(sprintf('sv_mean_%.0fkHz',primary_freqs(ip)/1e3)));
                end
                output_struct.school_struct{ui}.(sprintf('Sv_%d',primary_freqs(ip)/1e3))=tmp;
                
                if ~isnan(secondary_freqs(ip))
                    
                    if idx_primary_freq==idx_secondary_freqs(ip)
                        tmp_sec=pow2db_perso(output_struct.school_struct{ui}.sv_mean);
                    else
                        tmp_sec=pow2db_perso(output_struct.school_struct{ui}.(sprintf('sv_mean_%.0fkHz',secondary_freqs(ip)/1e3)));
                    end
                    
                    delta_tmp=tmp-tmp_sec;
                    output_struct.school_struct{ui}.(sprintf('delta_Sv_%d_%d',primary_freqs(ip)/1e3,secondary_freqs(ip)/1e3))=delta_tmp;
                    output_struct.school_struct{ui}.(sprintf('Sv_%d',secondary_freqs(ip)/1e3))=tmp_sec;
                end
            end
        end
end

if ~isempty(p.Results.load_bar_comp)
    p.Results.load_bar_comp.progress_bar.setText('Applying classification tree...');
end

for ui=1:length(output_struct.school_struct)
    switch lower(class_tree_obj.ClassificationType)
        case 'by regions'
            tag=class_tree_obj.apply_classification_tree(output_struct.school_struct{ui});
            trans_obj_primary.Regions(idx_schools(ui)).Tag=char(tag);
            
        case 'cell by cell'
            tag=class_tree_obj.apply_classification_tree(output_struct.school_struct{ui});
            l_min_can = surv_opt_obj.Vertical_slice_size/2;
            h_min_can = surv_opt_obj.Horizontal_slice_size/2;
            nb_min_sples = 1;
            
            switch lower(surv_opt_obj.Vertical_slice_units)
                case 'pings'
                    dist_can = output_struct.school_struct{ui}.Ping_S;
                case 'meters'
                    dist_can= output_struct.school_struct{ui}.Dist_S;
                    if nanmean(diff(dist))==0
                        warning('No Distance was computed, using ping instead of distance for linking');
                        dist_can= output_struct.school_struct{ui}.Ping_S;
                    end
            end
            tags=unique(tag);
            tags(tags == "") = [];
            if p.Results.cluster_tags
                
                  
                vert_link_max = p.Results.vert_link_max;
                horz_link_max = p.Results.horz_link_max;
                
                l_min_tot = p.Results.l_min_tot;
                h_min_tot = p.Results.h_min_tot;
                
                tag_can = zeros(size(tag));
                

                
                dist= output_struct.school_struct{ui}.Dist_S;
                if nanmean(diff(dist))==0
                    warning('No Distance was computed, using ping instead of distance for linking');
                    dist= output_struct.school_struct{ui}.Ping_S;
                end
                
                linked_cell_tags = cell(1,numel(tags));
                candidates_cell_tags = cell(1,numel(tags));
                
                for itag = 1:numel(tags)
                    tag_can(tag==tags{itag}) = itag;
                    candidates_cell_tags{itag}=find_candidates_v3(tag==tags{itag},output_struct.school_struct{ui}.Range_ref_min(:,1),dist_can,l_min_can,h_min_can,nb_min_sples,'mat',[]);
                    linked_cell_tags{itag}=link_candidates_v2(candidates_cell_tags{itag},dist,output_struct.school_struct{ui}.Range_ref_min(:,1),horz_link_max,vert_link_max,l_min_tot,h_min_tot,[]);
                end
                
                candidates=find_candidates_v3(tag~="",output_struct.school_struct{ui}.Range_ref_min(:,1),dist_can,l_min_can,h_min_can,nb_min_sples,'mat',[]);
                
                linked_tags=link_candidates_v2(candidates,dist,output_struct.school_struct{ui}.Range_ref_min(:,1),horz_link_max,vert_link_max,l_min_tot,h_min_tot,[]);
                
                tag_f = layer.EchoIntStruct.output_2D{idx_main}{ui}.Tags;
                
                unique_can = unique(linked_tags(:));
                unique_can(unique_can==0)=[];
                n_can = numel(unique_can);
                
                prop=cell(n_can,numel(tags));
                
                for ican=1:n_can
                    can_temp = linked_tags==unique_can(ican);
                    nc = nansum(nansum(can_temp));
                    for itag = 1:numel(tags)
                        tu = unique(linked_cell_tags{itag});
                        tu(tu==0)=[];
                        for utu = 1:numel(tu)
                            tag_ori=linked_cell_tags{itag}==tu(utu);
                            prop{ican,itag}(utu) =nansum(nansum(tag_ori&can_temp))/nc;
                        end
                    end
                end
               
                prop_per_tag = cellfun(@nansum,prop);
                for ican=1:n_can
                    [~,id_max] = nanmax(prop_per_tag(ican,:));
                    can_temp = linked_tags==unique_can(ican);
                    for itag = 1:numel(tags)
                        tu = unique(linked_cell_tags{itag});
                        tu(tu==0)=[];
                        for utu = 1:numel(tu)
                            tag_ori=linked_cell_tags{itag}==tu(utu);
                            if  prop{ican,itag}(utu)>p.Results.thr_cluster/100
                                tag_f(tag_ori&can_temp) = tags{itag};
                            else
                                tag_f(tag_ori&can_temp) = tags{id_max};
                            end
                        end
                    end
                    
                end
                
            else
                candidates=find_candidates_v3(tag~="",output_struct.school_struct{ui}.Range_ref_min(:,1),dist_can,l_min_can,h_min_can,nb_min_sples,'mat',[]);
                tag_f=tag;
            end
            
            layer.EchoIntStruct.output_2D{idx_main}{ui}.Tags=tag_f;
            
            if p.Results.create_regions
                
                if ~isempty(p.Results.load_bar_comp)
                    p.Results.load_bar_comp.progress_bar.setText('Creating regions...');
                    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(tags), 'Value',0);
                end
                
                for itag = 1:numel(tags)
                    set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',numel(tags), 'Value',itag);
                    can_temp=candidates;
                    can_temp(tag_f~=tags{itag})=0;
                    
                    trans_obj_primary.create_regions_from_linked_candidates(can_temp,...
                        'idx_pings',1/2*(output_struct.school_struct{ui}.Ping_S+output_struct.school_struct{ui}.Ping_E),...
                        'idx_r',1/2*(output_struct.school_struct{ui}.Sample_S+output_struct.school_struct{ui}.Sample_E),...
                        'w_unit',surv_opt_obj.Vertical_slice_units,...
                        'cell_w',surv_opt_obj.Vertical_slice_size,...
                        'h_unit','meters',...
                        'ref',layer.EchoIntStruct.output_2D_type{idx_main}{ui},...
                        'cell_h',surv_opt_obj.Horizontal_slice_size,...
                        'reg_names','Classified',...
                        'tag',tags{itag},...
                        'rm_overlapping_regions',true);
                
                end
            end
            
    end
end

output_struct.done=true;
disp('Done.');
