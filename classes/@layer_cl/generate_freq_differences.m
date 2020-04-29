function [secondary_freqs,cax,output_diff]=generate_freq_differences(layer_obj,varargin)

p = inputParser;


addRequired(p,'layer_obj',@(x) isa(x,'layer_cl'));
addParameter(p,'primary_freq',layer_obj.Frequencies(1),@isnumeric);
addParameter(p,'main_figure',[],@(x) ishandle(x)||ishandle());
addParameter(p,'secondary_freqs',layer_obj.Frequencies,@isnumeric);
addParameter(p,'region',region_cl.empty,@(x) isa(x,'region_cl'));
addParameter(p,'Cell_w',5,@isnumeric);
addParameter(p,'Cell_h',5,@isnumeric);
addParameter(p,'Cell_w_unit','pings',@ischar);
addParameter(p,'Cell_h_unit','meters',@ischar);
addParameter(p,'sv_thr',-999,@isnumeric);

parse(p,layer_obj,varargin{:});

primary_freq=p.Results.primary_freq;
secondary_freqs=p.Results.secondary_freqs;

freqs=layer_obj.Frequencies;
primary_freq=intersect(primary_freq,freqs);
secondary_freqs=setdiff(secondary_freqs,primary_freq);
secondary_freqs=intersect(secondary_freqs,freqs);

if isempty(secondary_freqs)||isempty(primary_freq)
    cax=[];
    return;
end

[idx_freq_primary,~]=layer_obj.find_freq_idx(primary_freq);
[idx_freqs_secondary,~]=layer_obj.find_freq_idx(secondary_freqs);

trans_obj_primary=layer_obj.Transceivers(idx_freq_primary);

if isempty(p.Results.region)
    reg_primary=trans_obj_primary.create_WC_region(...
        'Ref','Transducer',...
        'Cell_w',p.Results.Cell_w,...
        'Cell_h',p.Results.Cell_h,...
        'Cell_w_unit',p.Results.Cell_w_unit,...
        'Cell_h_unit',p.Results.Cell_h_unit);
else
    reg_primary=p.Results.region;
end

output_diff=cell(numel(reg_primary),numel(idx_freqs_secondary));
show_status_bar(p.Results.main_figure);
if ~isempty(p.Results.main_figure)
    load_bar_comp = getappdata(p.Results.main_figure,'Loading_bar');
else
    load_bar_comp=[];
end
for ireg=1:numel(reg_primary)
    [regs_secondary,idx_freqs_secondary,r_factor,t_factor]=layer_obj.generate_regions_for_other_freqs(idx_freq_primary,reg_primary(ireg),idx_freqs_secondary);
    
    if any(r_factor*reg_primary(ireg).Cell_h<2)
            ss_ori= reg_primary(ireg).Cell_h;
           reg_primary(ireg).Cell_h=nanmin(ceil(1/r_factor))*2;
           warning('Could not subsample at %d, doing it at %d instead',ss_ori,reg_primary(ireg).Cell_h);
           [regs_secondary,idx_freqs_secondary,r_factor,t_factor]=layer_obj.generate_regions_for_other_freqs(idx_freq_primary,reg_primary(ireg),idx_freqs_secondary);
           
    end
    
    output_reg_primary=trans_obj_primary.integrate_region(reg_primary(ireg),'keep_bottom',1,'keep_all',1,'sv_thr',p.Results.sv_thr,'load_bar_comp',load_bar_comp);

    output_regs_secondary=cell(1,numel(idx_freqs_secondary));
    cax=nan(numel(idx_freqs_secondary),2);
    
    for i=1:numel(idx_freqs_secondary)
        trans_obj_secondary=layer_obj.Transceivers(idx_freqs_secondary(i));
        output_regs_secondary{i}=trans_obj_secondary.integrate_region(regs_secondary(i),'keep_bottom',1,'keep_all',1,'sv_thr',p.Results.sv_thr,'load_bar_comp',load_bar_comp);
        output_diff{ireg,i}  = substract_reg_outputs(output_reg_primary,output_regs_secondary{i});
        
        if isempty(p.Results.region)
            trans_obj_primary.set_sv_diff(output_diff{ireg,i},secondary_freqs(i));
        end
        
        sv=pow2db_perso(output_diff{ireg,i}.Sv_mean_lin(:));
        cax(i,1)=prctile(sv(sv>-999),10)-5;
        cax(i,2)=prctile(sv(sv>-999),90)+5;
    end
    cax(isnan(cax(:,1)),:)=[];
end
hide_status_bar(p.Results.main_figure);