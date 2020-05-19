function output_struct=apply_classification(layer,varargin)

p = inputParser;

addRequired(p,'layer',@(x) isa(x,'layer_cl'));
addParameter(p,'classification_type','By regions',@(x) ismember(x,{'By regions' 'Cell by cell'}));
addParameter(p,'classification_file','',@ischar);
addParameter(p,'ref','Surface',@(x) ismember(x,{'Surface' 'Transducer' 'Bottom'}));
addParameter(p,'timeBounds',[0 inf],@isnumeric);
addParameter(p,'create_regions',true,@islogical);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl'));
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

switch lower(p.Results.classification_type)
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
end

if exist(classification_file,'file')>0
    try
        class_tree_obj=decision_tree_cl(classification_file);
    catch
        warning('Cannot parse specified classification file: %s',classification_file);
        return;
    end
else
    warning('Cannot find specified classification file: %s',classification_file);
    return;
end

%freqs=class_tree_obj.get_frequencies();
vars=class_tree_obj.get_variables();

if ~strcmpi(class_tree_obj.ClassificationType,p.Results.classification_type)
    warndlg_perso([],'',sprintf('Chosen classification file does not match the required classsification type (%s instead of %s)....',class_tree_obj.ClassificationType,p.Results.classification_type));
    return;
end


idx_var_freq=find(contains(vars,'Sv_'));
idx_var_freq_sec=find(contains(vars,'delta_Sv_'));

primary_freqs=nan(1,numel(idx_var_freq));
secondary_freqs=nan(1,numel(idx_var_freq));

for ii=1:numel(idx_var_freq)
    if ismember(idx_var_freq(ii),idx_var_freq_sec)
        freqs_tmp=textscan(vars{idx_var_freq(ii)},'delta_Sv_%d_%d');
    else
        freqs_tmp=textscan(vars{idx_var_freq(ii)},'Sv_%');
    end
    primary_freqs(ii)=freqs_tmp{1}*1e3;
    if ismember(idx_var_freq(ii),idx_var_freq_sec)
        secondary_freqs(ii)=freqs_tmp{2}*1e3;
    end
end


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


switch lower(p.Results.classification_type)
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
    switch lower(p.Results.classification_type)
        case 'by regions'
            tag=class_tree_obj.apply_classification_tree(output_struct.school_struct{ui});
            trans_obj_primary.Regions(idx_schools(ui)).Tag=char(tag);
            
        case 'cell by cell'
            tag=class_tree_obj.apply_classification_tree(output_struct.school_struct{ui});
            
            for ifreq=1:numel(layer.EchoIntStruct.output_2D)
                layer.EchoIntStruct.output_2D{ifreq}{ui}.Tags=tag;
            end
            if p.Results.create_regions
                
                if ~isempty(p.Results.load_bar_comp)
                    p.Results.load_bar_comp.progress_bar.setText('Creating regions...');
                end
                trans_obj_primary.create_regions_from_linked_candidates(tag,...
                    'idx_pings',1/2*(output_struct.school_struct{ui}.Ping_S+output_struct.school_struct{ui}.Ping_E),...
                    'idx_r',1/2*(output_struct.school_struct{ui}.Sample_S+output_struct.school_struct{ui}.Sample_E),...
                    'w_unit',surv_opt_obj.Vertical_slice_units,...
                    'cell_w',surv_opt_obj.Vertical_slice_size,...
                    'h_unit','meters',...
                    'ref',layer.EchoIntStruct.output_2D_type{idx_main}{ui},...
                    'cell_h',surv_opt_obj.Horizontal_slice_size,...
                    'reg_names','Classified',...
                    'rm_overlapping_regions',true);
            end
            
    end
end

output_struct.done=true;
disp('Done.');
