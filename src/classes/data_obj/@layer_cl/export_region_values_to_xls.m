function export_region_values_to_xls(layer_obj,active_reg,varargin)

[path_tmp,~,~]=fileparts(layer_obj.Filename{1});
layers_Str=list_layers(layer_obj,'nb_char',80);
output_f_def=fullfile(path_tmp,[layers_Str{1} '_regions' '.xlsx']);

p = inputParser;
addRequired(p,'layer_obj',@(x) isa(x,'layer_cl'));
addRequired(p,'active_reg',@(x) (isa(x,'region_cl')||isempty(x)));
addParameter(p,'output_f',output_f_def,@ischar);
addParameter(p,'idx_freq',1,@isnumeric);
addParameter(p,'idx_freq_end',[],@isnumeric);
addParameter(p,'field','sv',@ischar);
addParameter(p,'rm_bad_data_reg',1,@isnumeric);
addParameter(p,'rm_bad_transmits',1,@isnumeric);
addParameter(p,'rm_under_bot',1,@isnumeric);
addParameter(p,'rm_st',0,@isnumeric);
%addParameter(p,'block_len',get_block_len(10,'cpu'),@(x) x>0);
addParameter(p,'intersection_only',0,@isnumeric)
addParameter(p,'load_bar_comp',[]);

parse(p,layer_obj,active_reg,varargin{:});


if exist(p.Results.output_f,'file')>1
    delete(p.Results.output_f);
end


if isempty(active_reg)
    active_reg=layer_obj.Transceivers(p.Results.idx_freq).create_WC_region(...
        'y_min',-inf,...
        'y_max',Inf,...
        'Type','Data',...
        'Ref','Surface',...
        'Cell_w',1,...
        'Cell_h',1,...
        'Cell_w_unit','meters',...
        'Cell_h_unit','meters',...
        'Remove_ST',p.Results.rm_st);
end


[regs_end,idx_freq_end,~,~]=layer_obj.generate_regions_for_other_freqs(p.Results.idx_freq,active_reg,p.Results.idx_freq_end);
regs=[active_reg regs_end];
[idx_freq_sort,is]=sort([p.Results.idx_freq,idx_freq_end]);
regs=regs(is);

for ir=1:length(idx_freq_sort)
    reg_tmp=regs(ir);
    trans_obj=layer_obj.Transceivers(idx_freq_sort(ir));
    [data_reg,idx_r,idx_pings,bad_data_mask,bad_trans_vec,intersection_mask,below_bot_mask,mask_from_st]=get_data_from_region(trans_obj,...
        reg_tmp,...
        'field',p.Results.field,...
        'intersect_only',p.Results.intersection_only);
    if isempty(data_reg)
        continue;
    end
 
    if p.Results.rm_bad_data_reg>0
        data_reg(bad_data_mask)=-999;
    end
    
    if p.Results.rm_bad_transmits>0
        data_reg(:,bad_trans_vec)=-999;
    end
    
    if p.Results.rm_st>0
        data_reg(mask_from_st)=-999;
    end
    
    if p.Results.intersection_only>0
        data_reg(~intersection_mask)=nan;
    end
    
    if p.Results.rm_under_bot>0
        data_reg(below_bot_mask)=nan;
    end
    
    
    range_t=trans_obj.get_transceiver_range(idx_r);
    time_t=trans_obj.get_transceiver_time(idx_pings);
    samples_t=trans_obj.get_transceiver_samples(idx_r);
    ping_number=trans_obj.get_transceiver_pings(idx_pings);
    
    
    output_f=generate_valid_filename(p.Results.output_f);
    sheet_name= sprintf('%.0fkHz',layer_obj.Frequencies(idx_freq_sort(ir))/1e3);
    sheet_name=sheet_name(1:nanmin(numel(sheet_name),31));
    writetable(table(samples_t),output_f,'WriteVariableNames',0,'Sheet',sheet_name,'Range','A3');
    writetable(table(range_t),output_f,'WriteVariableNames',0,'Sheet',sheet_name,'Range','B3');   
    writetable(table(ping_number),output_f,'WriteVariableNames',0,'Sheet',sheet_name,'Range','C1');
    writetable(table(cellfun(@(x) datestr(x,'dd/mm/yyyy HH:MM:SS.FFF'),num2cell(time_t),'un',0)),output_f,'WriteVariableNames',0,'Sheet',sheet_name,'Range','C2');
    writetable(table(data_reg),output_f,'WriteVariableNames',0,'Sheet',sheet_name,'Range','C2');

end


